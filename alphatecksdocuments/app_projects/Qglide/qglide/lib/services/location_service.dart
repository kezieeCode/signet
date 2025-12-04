import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static const String _apiKey = 'AIzaSyBrThzOJlW4SbyUHKLoCrv9yK5AAs_esao'; // Google Maps API Key
  
  /// Get user's current location with high accuracy
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {        return null;
      }

      // Get current position with highest accuracy for detailed street view
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation, // Highest accuracy
        timeLimit: Duration(seconds: 15), // Allow more time for better accuracy
      );

      return position;
    } catch (e) {      return null;
    }
  }

  /// Get address from coordinates using Google Geocoding API
  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final String url = 
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$_apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Get the first result (most accurate)
          final result = data['results'][0];
          final formattedAddress = result['formatted_address'];
          
          return formattedAddress;
        } else {          return null;
        }
      } else {        return null;
      }
    } catch (e) {      return null;
    }
  }

  /// Get country code from coordinates using Google Geocoding API
  static Future<String?> getCountryFromCoordinates(double latitude, double longitude) async {
    try {
      final String url = 
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$_apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // Extract country code from address components
          final result = data['results'][0];
          final addressComponents = result['address_components'] as List;
          
          for (var component in addressComponents) {
            final types = component['types'] as List;
            if (types.contains('country')) {
              return component['short_name']; // Returns ISO country code (e.g., 'QA', 'US')
            }
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current location with address
  static Future<Map<String, dynamic>?> getCurrentLocationWithAddress() async {
    try {
      // Get current position
      Position? position = await getCurrentPosition();
      if (position == null) {
        return null;
      }

      // Get address and country from coordinates
      String? address = await getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
      String? country = await getCountryFromCoordinates(
        position.latitude, 
        position.longitude
      );

      return {
        'position': position,
        'address': address ?? 'Current Location',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'country': country ?? 'QA', // Default to Qatar if detection fails
      };
    } catch (e) {      return null;
    }
  }
}
