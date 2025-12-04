import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  static const String baseUrl = 'https://bvazoowmmiymbbhxoggo.supabase.co';
  
  // Store access token, user type, and user info
  static String? _accessToken;
  static String? _userType; // 'rider' or 'driver'
  static String? _firstName;
  static const String _tokenKey = 'access_token';
  static const String _userTypeKey = 'user_type';
  static const String _firstNameKey = 'first_name';
  
  // Set access token, user type, and user info after login
  static Future<void> setAccessToken(String token, {String? userType, String? firstName}) async {    
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);    
    if (userType != null) {
      _userType = userType;
      await prefs.setString(_userTypeKey, userType);
    }
    
    if (firstName != null) {
      _firstName = firstName;
      await prefs.setString(_firstNameKey, firstName);
    }
  }
  
  // Clear access token, user type, and user info on logout
  static Future<void> clearAccessToken() async {
    _accessToken = null;
    _userType = null;
    _firstName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_firstNameKey);  }
  
  // Load access token, user type, and user info from storage on app start
  static Future<void> loadStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    final storedUserType = prefs.getString(_userTypeKey);
    final storedFirstName = prefs.getString(_firstNameKey);
    
    if (storedToken != null) {
      _accessToken = storedToken;
    }
    
    if (storedUserType != null) {
      _userType = storedUserType;
    }
    
    if (storedFirstName != null) {
      _firstName = storedFirstName;
    }
  }
  
  // Get stored user info
  static String? get userType => _userType;
  static String? get firstName => _firstName;
  
  // Check if user is authenticated
  static bool get isAuthenticated => _accessToken != null;
  
  // Headers for API requests
  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    // Prefer Supabase auto-refreshed access token if available
    try {
      final String? supabaseToken = Supabase.instance.client.auth.currentSession?.accessToken;
      if (supabaseToken != null && supabaseToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer ' + supabaseToken;
        return headers;
      }
    } catch (_) {}

    // Fallback to locally stored token
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer ' + _accessToken!;
    }
    
    return headers;
  }

  // Generic API response model
  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      // Handle empty response
      if (response.body.isEmpty) {
          return {
          'success': response.statusCode >= 200 && response.statusCode < 300,
            'data': null,
          'error': response.statusCode >= 200 && response.statusCode < 300 
              ? null 
              : {'message': 'Empty response from server'},
        };
      }

      final Map<String, dynamic> data = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
          return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': data,
        };
      }
    } catch (e) {
      // Handle JSON parsing errors
      return {
        'success': false,
        'error': {
          'message': 'Invalid response format from server',
          'status': response.statusCode.toString(),
          'body': response.body,
        },
      };
    }
  }


  // OTP Verification
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final requestBody = {
        'email': email,
        'otp': otp,
      };

      final url = '$baseUrl/functions/v1/verify-otp';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Resend OTP
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    try {
      final requestBody = {
        'email': email,
      };

      final url = '$baseUrl/functions/v1/rider-resend-otp';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Test server connectivity
  static Future<Map<String, dynamic>> testConnectivity() async {
    try {
      final url = '$baseUrl/';      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Server not reachable');
        },
      );
      return {
        'success': true,
        'status': response.statusCode,
        'reachable': true,
      };
    } catch (e) {
      return {
        'success': false,
        'reachable': false,
        'error': e.toString(),
      };
    }
  }

  // Test OTP verification endpoint specifically
  static Future<Map<String, dynamic>> testOtpEndpoint() async {
    try {
      // Test both with and without trailing slash
      final urls = [
        '$baseUrl/v1/auth/verify-otp',
        '$baseUrl/v1/auth/verify-otp/',
      ];
      
      for (final url in urls) {        
        try {
          final response = await http.post(
            Uri.parse(url),
            headers: _headers,
            body: json.encode({'email': 'test@test.com', 'otp': '1234'}),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout for $url');
            },
          );
          
          return {
            'success': true,
            'working_url': url,
            'status': response.statusCode,
            'body': response.body,
          };
        } catch (e) {
          // Continue to next URL
        }
      }
      
      return {
        'success': false,
        'error': 'No working endpoint found',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Rider Registration
  static Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String dateOfBirth,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final requestBody = {
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth,
        'password': password,
        'confirm_password': confirmPassword,
      };

      final url = '$baseUrl/functions/v1/register';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Forgot Password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final requestBody = {
        'email': email,
      };

      final url = '$baseUrl/functions/v1/forgot-password';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Rider Login
  static Future<Map<String, dynamic>> riderLogin({
    required String email,
    required String password,
  }) async {
    try {
      final requestBody = {
        'email': email,
        'password': password,
      };

      final url = '$baseUrl/functions/v1/rider-login';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
      } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Upload Avatar
  static Future<Map<String, dynamic>> uploadAvatar({
    required String base64Image,
  }) async {
    try {
      final requestBody = {
        'base64_image': base64Image,
      };

      final url = '$baseUrl/functions/v1/upload-avatar';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Edit Profile
  static Future<Map<String, dynamic>> editProfile({
    required String fullName,
    required String phone,
    required String dateOfBirth,
  }) async {
    try {
      final requestBody = {
        'full_name': fullName,
        'phone': phone,
        'date_of_birth': dateOfBirth,
      };

      final url = '$baseUrl/functions/v1/edit-profile';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Driver Registration
  static Future<Map<String, dynamic>> driverSignup({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String dateOfBirth,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final requestBody = {
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'phone_number': phoneNumber,
        'date_of_birth': dateOfBirth,
        'password': password,
        'confirm_password': confirmPassword,
      };

      final url = '$baseUrl/functions/v1/driver-signup';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Document Upload
  static Future<Map<String, dynamic>> uploadDocument({
    required String email,
    required String password,
    required String documentType,
    required String fileBase64,
    required String mimeType,
  }) async {
    try {
      print('\n🔵 API CALL - uploadDocument');
      print('   Document Type: $documentType');
      print('   Email: $email');
      print('   File Base64 Length: ${fileBase64.length} characters');
      print('   MIME Type: $mimeType');
      
      final requestBody = {
        'email': email,
        'password': password,
        'document_type': documentType,
        'file_base64': fileBase64,
        'mime_type': mimeType,
      };

      final url = '$baseUrl/functions/v1/upload-document';
      print('   URL: $url');
      print('   Headers: $_headers');
      print('   Request Body: ${json.encode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      
      print('   Response Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');
      
      final result = _handleResponse(response);
      print('   Parsed Result: $result');
      
      return result;
    } catch (e, stackTrace) {
      print('❌ API ERROR - uploadDocument');
      print('   Exception: $e');
      print('   Stack Trace: $stackTrace');
      
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Helper method to generate MD5 hash of file
  static Future<String> generateFileHash(File file) async {
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // Helper method to get mime type from file extension
  static String getMimeTypeFromExtension(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        // Default to image/jpeg for unknown image formats
        return 'image/jpeg';
    }
  }

  // Manage Vehicle
  static Future<Map<String, dynamic>> manageVehicle({
    required String email,
    required String password,
    required String vehicleImage,
    required String vehicleName,
    required String vehicleModel,
    required int vehicleYear,
    required String vehicleColor,
    required String licensePlate,
  }) async {
    try {
      print('\n🚗 API CALL - manageVehicle');
      print('   Email: $email');
      print('   Vehicle Name: $vehicleName');
      print('   Vehicle Model: $vehicleModel');
      print('   Vehicle Year: $vehicleYear');
      print('   Vehicle Color: $vehicleColor');
      print('   License Plate: $licensePlate');
      print('   Vehicle Image: $vehicleImage');
      
      final requestBody = {
        'email': email,
        'password': password,
        'vehicle_image': vehicleImage,
        'vehicle_name': vehicleName,
        'vehicle_model': vehicleModel,
        'vehicle_year': vehicleYear,
        'vehicle_color': vehicleColor,
        'license_plate': licensePlate,
      };

      final url = '$baseUrl/functions/v1/manage-vehicle';
      print('   URL: $url');
      print('   Request Body: ${json.encode(requestBody)}');
      print('   Headers: $_headers');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      
      print('   Response Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');
      
      final result = _handleResponse(response);
      print('   Parsed Result: $result');
      
      return result;
    } catch (e, stackTrace) {
      print('❌ API ERROR - manageVehicle');
      print('   Exception: $e');
      print('   Stack Trace: $stackTrace');
      
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Driver Login
  static Future<Map<String, dynamic>> driverLogin({
    required String email,
    required String password,
  }) async {
    try {
      final requestBody = {
        'email': email,
        'password': password,
      };

      final url = '$baseUrl/functions/v1/driver-login';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Create Ride
  static Future<Map<String, dynamic>> createRide({
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
    required double estimatedFare,
    required String carType,
  }) async {
    try {
      final requestBody = {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'pickup_address': pickupAddress,
        'dropoff_lat': dropoffLat,
        'dropoff_lng': dropoffLng,
        'dropoff_address': dropoffAddress,
        'estimated_fare': estimatedFare,
        'car_type': carType,
      };

      final url = '$baseUrl/functions/v1/create-ride';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Cancel a ride
  static Future<Map<String, dynamic>> cancelRide({
    required String rideId,
    required String cancelledBy, // 'rider' or 'driver'
    required String reason,
    String? reasonNote,
  }) async {
    try {
      // Generate idempotency key for this cancellation request
      const uuid = Uuid();
      final idempotencyKey = uuid.v4();
      
      final requestBody = {
        'ride_id': rideId,
        'cancelled_by': cancelledBy,
        'reason': reason,
        if (reasonNote != null && reasonNote.isNotEmpty) 'reason_note': reasonNote,
        'idempotency_key': idempotencyKey,
      };

      final url = '$baseUrl/functions/v1/cancel-ride';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Calculate distance between two coordinates using Haversine formula (returns km)
  static double calculateDistance({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const double earthRadiusKm = 6371.0;
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = 
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_degreesToRadians(lat1)) * 
         cos(_degreesToRadians(lat2)) * 
         sin(dLng / 2) * 
         sin(dLng / 2));
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadiusKm * c;
    return distance;
  }
  
  // Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  // Calculate fare based on distance (0.5 QAR per km)
  static double calculateFare(double distanceKm) {
    const double pricePerKm = 0.5;
    final double fare = distanceKm * pricePerKm;
    return fare;
  }

  // Get Ride Status
  static Future<Map<String, dynamic>> getRideStatus({String? rideId}) async {
    try {
      // Build URL with ride_id parameter if provided
      final url = rideId != null 
          ? '$baseUrl/functions/v1/ride-status?ride_id=$rideId'
          : '$baseUrl/functions/v1/ride-status';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get Ride Info (with driver details)
  static Future<Map<String, dynamic>> getRideInfo({
    required String rideId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double dropoffLat,
    required double dropoffLng,
    required String dropoffAddress,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'ride_id': rideId,
        'pickup_lat': pickupLat.toString(),
        'pickup_lng': pickupLng.toString(),
        'pickup_address': pickupAddress,
        'dropoff_lat': dropoffLat.toString(),
        'dropoff_lng': dropoffLng.toString(),
        'dropoff_address': dropoffAddress,
      };

      print('📡 API - RIDE INFO REQUEST:');
      print('   URL: $baseUrl/functions/v1/ride-info');
      print('   Query Parameters:');
      print('     ride_id: $rideId');
      print('     pickup_lat: $pickupLat');
      print('     pickup_lng: $pickupLng');
      print('     pickup_address: $pickupAddress');
      print('     dropoff_lat: $dropoffLat');
      print('     dropoff_lng: $dropoffLng');
      print('     dropoff_address: $dropoffAddress');

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/functions/v1/ride-info').replace(
        queryParameters: queryParams,
      );
      
      print('   Full URL: $uri');
      
      final response = await http.get(
        uri,
        headers: _headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      
      print('📡 API - RIDE INFO RAW RESPONSE:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');
      
      final result = _handleResponse(response);
      
      print('📡 API - RIDE INFO PARSED RESULT:');
      print('   Success: ${result['success']}');
      print('   Full Result: $result');
      
      return result;
    } catch (e) {
      print('❌ API - RIDE INFO ERROR: $e');
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get Rewards Info
  static Future<Map<String, dynamic>> getRewards({
    bool includeCoupons = true,
    bool includeRedemptions = false,
    int couponLimit = 5,
  }) async {
    try {
      final requestBody = {
        'include_coupons': includeCoupons,
        'include_redemptions': includeRedemptions,
        'coupon_limit': couponLimit,
      };

      final url = '$baseUrl/functions/v1/rewards';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get Ride History
  static Future<Map<String, dynamic>> getRideHistory() async {
    try {
      final url = '$baseUrl/functions/v1/ride-history';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({}), // Empty body for POST request
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get Nearby Rides for Driver
  static Future<Map<String, dynamic>> getNearbyRides({
    required double driverLat,
    required double driverLng,
    double radiusKm = 10.0,
    int limit = 10,
  }) async {
    try {
      final requestBody = {
        'driver_lat': driverLat,
        'driver_lng': driverLng,
        'radius_km': radiusKm,
        'limit': limit,
      };
      
      print('📡 API - GET NEARBY RIDES REQUEST:');
      print('   URL: $baseUrl/functions/v1/get-nearby-rides');
      print('   Request Body: ${json.encode(requestBody)}');
      
      final url = '$baseUrl/functions/v1/get-nearby-rides';      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      );
      
      print('📡 API - GET NEARBY RIDES RAW RESPONSE:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');
      
      final result = _handleResponse(response);
      
      print('📡 API - GET NEARBY RIDES PARSED RESULT:');
      print('   Success: ${result['success']}');
      print('   Full Result: $result');
      
      return result;
    } catch (e) {
      print('❌ API - GET NEARBY RIDES ERROR: $e');
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final url = '$baseUrl/functions/v1/get-user-profile';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );      
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get Driver Earnings
  static Future<Map<String, dynamic>> getDriverEarnings() async {
    try {
      final url = '$baseUrl/functions/v1/driver-earnings';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Ride Response (Accept/Decline)
  static Future<Map<String, dynamic>> rideResponse({
    required String rideId,
    required String action, // "accept" or "decline"
    String? declineReason,
    double? currentLatitude,
    double? currentLongitude,
    int? estimatedArrivalMinutes,
  }) async {
    try {
      final requestBody = {
        'ride_id': rideId,
        'action': action,
        if (action == 'accept' && currentLatitude != null && currentLongitude != null)
          'current_location': {
            'latitude': currentLatitude,
            'longitude': currentLongitude,
          },
        if (action == 'accept' && estimatedArrivalMinutes != null)
          'estimated_arrival_minutes': estimatedArrivalMinutes,
        if (declineReason != null) 'decline_reason': declineReason,
      };
      
      print('📡 API - RIDE RESPONSE REQUEST:');
      print('   Ride ID: $rideId');
      print('   Action: $action');
      if (action == 'accept') {
        print('   Current Location: ${currentLatitude != null && currentLongitude != null ? "($currentLatitude, $currentLongitude)" : "NOT PROVIDED"}');
        print('   Estimated Arrival: ${estimatedArrivalMinutes ?? "NOT PROVIDED"} minutes');
      }
      print('   Full Request Body: ${json.encode(requestBody)}');
      
      final url = '$baseUrl/functions/v1/ride-response';      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      );
      
      print('📡 API - RIDE RESPONSE RESULT:');
      print('   Status Code: ${response.statusCode}');
      print('   Response: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      print('❌ API - RIDE RESPONSE ERROR: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      final url = '$baseUrl/functions/v1/logout';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode({}), // Empty body for POST request
      );      
      final result = _handleResponse(response);
      
      // If logout successful, clear stored tokens
      if (result['success'] == true) {
        await clearAccessToken();
      }
      
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Start Ride (Driver picks up rider)
  static Future<Map<String, dynamic>> startRide({
    required String rideId,
  }) async {
    try {
      final requestBody = {
        'ride_id': rideId,
      };
      
      final url = '$baseUrl/functions/v1/start-ride';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Complete Ride
  static Future<Map<String, dynamic>> completeRide({
    required String rideId,
  }) async {
    try {
      final requestBody = {
        'ride_id': rideId,
      };
      
      final url = '$baseUrl/functions/v1/complete-ride';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Rate driver after ride completion
  static Future<Map<String, dynamic>> rateDriver({
    required String rideId,
    required int rating,
  }) async {
    try {
      final requestBody = {
        'ride_id': rideId,
        'rating': rating,
      };
      
      final url = '$baseUrl/functions/v1/rate-driver';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
      } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get chat history for a ride
  static Future<Map<String, dynamic>> getChatHistory({
    required String rideId,
  }) async {
    try {
      print('📡 API - GET CHAT HISTORY REQUEST:');
      print('   Ride ID: $rideId');
      
      final url = '$baseUrl/functions/v1/get-chat-history?ride_id=$rideId';
      print('   Full URL: $url');
      print('   Headers: $_headers');
      print('   Access Token: ${_accessToken != null ? "EXISTS (${_accessToken!.substring(0, 20)}...)" : "NULL"}');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      
      print('📡 API - GET CHAT HISTORY RAW RESPONSE:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');
      
      final result = _handleResponse(response);
      
      print('📡 API - GET CHAT HISTORY PARSED RESULT:');
      print('   Success: ${result['success']}');
      print('   Full Result: $result');
      
      return result;
    } catch (e) {
      print('❌ API - GET CHAT HISTORY ERROR: $e');
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Send chat message between rider and driver
  static Future<Map<String, dynamic>> sendChatMessage({
    required String rideId,
    required String message,
    String? senderType, // Optional: 'driver' or 'rider' - if not provided, backend determines from auth token
  }) async {
    try {
      final requestBody = {
        'ride_id': rideId,
        'message': message,
        if (senderType != null && senderType.isNotEmpty) 'sender_type': senderType,
      };
      
      print('📡 API - SEND CHAT MESSAGE REQUEST:');
      print('   Ride ID: $rideId');
      print('   Message: $message');
      print('   Request Body: ${json.encode(requestBody)}');
      print('   Headers: $_headers');
      print('   Access Token: ${_accessToken != null ? "EXISTS (${_accessToken!.substring(0, 20)}...)" : "NULL"}');
      
      final url = '$baseUrl/functions/v1/send-chat-message';
      print('   Full URL: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      
      print('📡 API - SEND CHAT MESSAGE RAW RESPONSE:');
      print('   Status Code: ${response.statusCode}');
      print('   Response Body: ${response.body}');
      
      final result = _handleResponse(response);
      
      print('📡 API - SEND CHAT MESSAGE PARSED RESULT:');
      print('   Success: ${result['success']}');
      print('   Full Result: $result');
      
      return result;
    } catch (e) {
      print('❌ API - SEND CHAT MESSAGE ERROR: $e');
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get driver's active ride status
  static Future<Map<String, dynamic>> getDriverRideStatus({String? rideId}) async {
    try {
      // Build URL with optional ride_id parameter
      var url = '$baseUrl/functions/v1/driver-ride-status';
      if (rideId != null && rideId.isNotEmpty) {
        url += '?ride_id=$rideId';
        print('🔍 API - Fetching driver ride status for ride_id: $rideId');
      } else {
        print('🔍 API - Fetching driver ride status (no ride_id specified)');
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get driver's completed trips history
  static Future<Map<String, dynamic>> getDriverCompletedTrips() async {
    try {
      final url = '$baseUrl/functions/v1/driver-completed-trips';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get rider's points history
  static Future<Map<String, dynamic>> getPointsHistory() async {
    try {
      final url = '$baseUrl/functions/v1/points-history';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get rider notifications
  static Future<Map<String, dynamic>> getRiderNotifications() async {
    try {
      final url = '$baseUrl/functions/v1/rider-notifications';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Register FCM Token
  static Future<Map<String, dynamic>> registerFcmToken({
    required String deviceToken,
    required String deviceType,
    required String deviceId,
  }) async {
    try {
      final requestBody = {
        'device_token': deviceToken,
        'device_type': deviceType,
        'device_id': deviceId,
      };

      final url = '$baseUrl/functions/v1/register-fcm-token';
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );
      
      if (kDebugMode) {
        print('📱 FCM Token Registration:');
        print('   Status: ${response.statusCode}');
        print('   Response: ${response.body}');
      }
      
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM Token Registration Error: $e');
      }
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get Nearby Drivers
  static Future<Map<String, dynamic>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
    int limit = 50,
  }) async {
    try {
      final url = '$baseUrl/functions/v1/get-nearby-drivers';
      final requestBody = {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        'limit': limit,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      if (kDebugMode) {
        print('📱 Get Nearby Drivers:');
        print('   Status: ${response.statusCode}');
        print('   Response: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get Nearby Drivers Error: $e');
      }
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Update Driver Location (for driver app/mode)
  static Future<Map<String, dynamic>> updateDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    required bool isAvailable,
  }) async {
    try {
      final url = '$baseUrl/functions/v1/update-driver-location';
      final requestBody = {
        'latitude': latitude,
        'longitude': longitude,
        if (heading != null) 'heading': heading,
        'is_available': isAvailable,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      if (kDebugMode) {
        print('📱 Update Driver Location:');
        print('   Status: ${response.statusCode}');
        print('   Response: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Update Driver Location Error: $e');
      }
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Set driver online/offline status
  static Future<Map<String, dynamic>> driverSetStatus({
    required bool isOnline,
  }) async {
    try {
      final url = '$baseUrl/functions/v1/driver-set-status';
      final requestBody = {
        'is_online': isOnline,
      };

      if (kDebugMode) {
        print('📱 Driver Set Status:');
        print('   URL: $url');
        print('   is_online: $isOnline');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - please check your internet connection');
        },
      );

      if (kDebugMode) {
        print('📱 Driver Set Status Response:');
        print('   Status: ${response.statusCode}');
        print('   Body: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Driver Set Status Error: $e');
      }
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Get online status of the currently assigned driver (for rider app)
  static Future<Map<String, dynamic>> driverOnlineStatus() async {
    try {
      final url = '$baseUrl/functions/v1/driver-online-status';

      if (kDebugMode) {
        print('📡 Driver Online Status - Request URL: $url');
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: _headers,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout - please check your internet connection');
            },
          );

      if (kDebugMode) {
        print('📡 Driver Online Status - Response Status: ${response.statusCode}');
        print('📡 Driver Online Status - Response Body: ${response.body}');
      }

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Driver Online Status Error: $e');
      }
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Future methods can be added here for other endpoints
  // static Future<Map<String, dynamic>> loginUser({...}) async {...}

  // ===== Zego Cloud Voice/Video Integration =====
  // Generate Zego access token (optionally for a specific room)
  static Future<Map<String, dynamic>> generateZegoToken({String? roomId}) async {
    try {
      final url = '$baseUrl/functions/v1/generate-zego-token';
      final body = <String, dynamic>{
        'expiration': 3600,
      };
      // Include room_id if provided - backend may generate room-specific token
      if (roomId != null && roomId.isNotEmpty) {
        body['room_id'] = roomId;
      }
      
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout - please check your internet connection');
            },
          );

      if (kDebugMode) {
        print('📞 Generate Zego Token (room: $roomId) -> ${response.statusCode}');
        print('Body: ${response.body}');
      }
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Generate Zego Token Error: $e');
      }
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }

  // Initiate call (returns recipient identity and call info)
  static Future<Map<String, dynamic>> initiateCall({
    required String rideId,
  }) async {
    try {
      final url = '$baseUrl/functions/v1/initiate-call';
      final body = {
        'ride_id': rideId,
      };
      final response = await http
          .post(
            Uri.parse(url),
            headers: _headers,
            body: json.encode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout - please check your internet connection');
            },
          );

      if (kDebugMode) {
        print('📞 Initiate Call -> ${response.statusCode}');
        print('Body: ${response.body}');
      }
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Initiate Call Error: $e');
      }
      return {
        'success': false,
        'error': {
          'status': 'False',
          'message': 'Network error: ${e.toString()}'
        }
      };
    }
  }
}