import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../cubits/theme_cubit.dart';

class PlacesService {
  // Google Maps API Keys
  static const String _mobileApiKey = 'AIzaSyBrThzOJlW4SbyUHKLoCrv9yK5AAs_esao';
  static const String _webApiKey = 'AIzaSyBrThzOJlW4SbyUHKLoCrv9yK5AAs_esao';
  
  // Get the appropriate API key based on platform
  static String get apiKey => kIsWeb ? _webApiKey : _mobileApiKey;
  
  static GooglePlaceAutoCompleteTextField buildAutocompleteTextField({
    required Function(Prediction) onPlaceSelected,
    required String hintText,
    required ThemeState themeState,
    required BuildContext context,
    required TextEditingController controller,
    String? countryCode, // Add country parameter
    FocusNode? focusNode,
    VoidCallback? onSubmitted,
  }) {
    return GooglePlaceAutoCompleteTextField(
      textEditingController: controller,
      googleAPIKey: apiKey,
      inputDecoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: themeState.textSecondary,
          fontSize: 16,
        ),
        filled: true,
        fillColor: themeState.fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: themeState.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: themeState.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.gold),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      debounceTime: 600,
      countries: countryCode != null ? [countryCode.toLowerCase()] : null, // Apply country filter
      isLatLngRequired: true,
      focusNode: focusNode,
      getPlaceDetailWithLatLng: (Prediction prediction) {
        // Dismiss keyboard when place is selected
        if (onSubmitted != null) {
          onSubmitted();
        } else if (focusNode != null) {
          focusNode.unfocus();
        }
        onPlaceSelected(prediction);
      },
      itemClick: (Prediction prediction) {
        onPlaceSelected(prediction);
        // Dismiss keyboard when place is clicked
        if (onSubmitted != null) {
          onSubmitted();
        } else if (focusNode != null) {
          focusNode.unfocus();
        }
      },
      seperatedBuilder: const Divider(),
      containerHorizontalPadding: 10,
      itemBuilder: (context, index, Prediction prediction) {
        return Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.gold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.description ?? "",
                      style: TextStyle(
                        color: themeState.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (prediction.structuredFormatting?.secondaryText != null)
                      Text(
                        prediction.structuredFormatting!.secondaryText!,
                        style: TextStyle(
                          color: themeState.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      isCrossBtnShown: true,
    );
  }

  // Get route directions from Google Directions API
  static Future<Map<String, dynamic>?> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final String url = 
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=$originLat,$originLng'
          '&destination=$destLat,$destLng'
          '&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Extract polyline points
          final polylinePoints = route['overview_polyline']['points'];
          
          // Extract duration
          final durationInSeconds = leg['duration']['value'];
          final durationText = leg['duration']['text'];
          final durationInMinutes = (durationInSeconds / 60).round();
          
          // Extract distance
          final distanceInMeters = leg['distance']['value'];
          final distanceText = leg['distance']['text'];
          
          return {
            'success': true,
            'polylinePoints': polylinePoints,
            'durationInMinutes': durationInMinutes,
            'durationText': durationText,
            'distanceText': distanceText,
            'distanceInMeters': distanceInMeters,
          };
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get coordinates from address using Google Geocoding API
  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      final String url = 
          'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          
          return LatLng(
            location['lat'].toDouble(),
            location['lng'].toDouble(),
          );
        } else {
          print('Geocoding failed: ${data['status']}');
          return null;
        }
      } else {
        print('Geocoding HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  /// Validate if coordinates are within the specified country
  static Future<bool> isLocationInCountry(double lat, double lng, String countryCode) async {
    try {
      final String url = 
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final addressComponents = result['address_components'] as List;
          
          for (var component in addressComponents) {
            final types = component['types'] as List;
            if (types.contains('country')) {
              final locationCountry = component['short_name'];
              return locationCountry.toUpperCase() == countryCode.toUpperCase();
            }
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Decode polyline points to List<LatLng>
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

}
