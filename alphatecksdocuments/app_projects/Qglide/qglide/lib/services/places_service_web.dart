// ignore: deprecated_member_use
import 'dart:html' as html;
// ignore: deprecated_member_use
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlacesServiceWeb {
  /// Initialize Google Places Autocomplete for web
  static void initAutocomplete(String inputId, Function(Map<String, dynamic>) onPlaceSelected) {
    if (!kIsWeb) return;

    try {
      final input = html.document.getElementById(inputId) as html.InputElement?;
      if (input == null) {        return;
      }

      // Create autocomplete instance
      final autocomplete = js.JsObject(
        js.context['google']['maps']['places']['Autocomplete'],
        [input],
      );

      // Set fields to return
      autocomplete.callMethod('setFields', [
        js.JsArray.from(['place_id', 'geometry', 'name', 'formatted_address'])
      ]);

      // Add place_changed listener
      js.context['google']['maps']['event'].callMethod('addListener', [
        autocomplete,
        'place_changed',
        js.allowInterop(() {
          final place = autocomplete.callMethod('getPlace', []);
          
          if (place['geometry'] != null) {
            final geometry = place['geometry'];
            final location = geometry['location'];
            
            final placeData = {
              'place_id': place['place_id'] ?? '',
              'name': place['name'] ?? '',
              'formatted_address': place['formatted_address'] ?? '',
              'latitude': location.callMethod('lat', []),
              'longitude': location.callMethod('lng', []),
            };            
            onPlaceSelected(placeData);
          }
        })
      ]);    } catch (e) {
      // Silent error handling
    }
  }
}


