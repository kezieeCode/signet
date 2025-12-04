import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSimulationService {
  static final LocationSimulationService _instance = LocationSimulationService._internal();
  factory LocationSimulationService() => _instance;
  LocationSimulationService._internal();

  final StreamController<LatLng> _locationController = StreamController.broadcast();
  final StreamController<double> _speedController = StreamController.broadcast();
  final StreamController<String> _addressController = StreamController.broadcast();
  
  Stream<LatLng> get locationStream => _locationController.stream;
  Stream<double> get speedStream => _speedController.stream;
  Stream<String> get addressStream => _addressController.stream;

  Timer? _locationTimer;
  Timer? _speedTimer;
  LatLng? _currentLocation;
  double _currentSpeed = 0.0;
  final Random _random = Random();

  // Qatar area bounds for realistic simulation
  static const double _minLat = 24.5;
  static const double _maxLat = 26.2;
  static const double _minLng = 50.7;
  static const double _maxLng = 51.7;

  // Popular locations in Qatar
  final Map<String, LatLng> _popularLocations = {
    'Doha': const LatLng(25.2854, 51.5310),
    'Pearl Qatar': const LatLng(25.3708, 51.5370),
    'West Bay': const LatLng(25.3197, 51.5206),
    'Hamad International Airport': const LatLng(25.2611, 51.5651),
    'Katara Cultural Village': const LatLng(25.3626, 51.5370),
    'Souq Waqif': const LatLng(25.2892, 51.5303),
    'Museum of Islamic Art': const LatLng(25.2929, 51.5394),
    'Aspire Zone': const LatLng(25.2638, 51.4401),
    'Lusail': const LatLng(25.4181, 51.5004),
    'Al Rayyan': const LatLng(25.2919, 51.4244),
  };

  // Start location simulation
  void startLocationSimulation(LatLng initialLocation) {
    _currentLocation = initialLocation;
    
    // Start location updates
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _simulateLocationUpdate();
    });
    
    // Start speed simulation
    _speedTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _simulateSpeedUpdate();
    });
  }

  // Simulate location update
  void _simulateLocationUpdate() {
    if (_currentLocation == null) return;
    
    // Simulate realistic movement (small random changes)
    double latChange = (_random.nextDouble() - 0.5) * 0.0001; // ~11 meters
    double lngChange = (_random.nextDouble() - 0.5) * 0.0001;
    
    double newLat = (_currentLocation!.latitude + latChange).clamp(_minLat, _maxLat);
    double newLng = (_currentLocation!.longitude + lngChange).clamp(_minLng, _maxLng);
    
    _currentLocation = LatLng(newLat, newLng);
    _locationController.add(_currentLocation!);
    
    // Update address periodically
    _updateAddress();
  }

  // Simulate speed update
  void _simulateSpeedUpdate() {
    // Simulate realistic speed changes (0-60 km/h in city)
    if (_currentSpeed == 0) {
      // Starting from stop
      _currentSpeed = 5.0 + _random.nextDouble() * 15.0; // 5-20 km/h
    } else {
      // Varying speed
      double change = (_random.nextDouble() - 0.5) * 10.0; // -5 to +5 km/h change
      _currentSpeed = (_currentSpeed + change).clamp(0.0, 60.0);
    }
    
    _speedController.add(_currentSpeed);
  }

  // Update address based on current location
  void _updateAddress() {
    if (_currentLocation == null) return;
    
    // Find closest popular location
    String closestLocation = _findClosestLocation(_currentLocation!);
    
    // Simulate realistic address
    String streetNumber = (100 + _random.nextInt(900)).toString();
    String streetName = _getRandomStreetName();
    String address = "$streetNumber $streetName, $closestLocation, Qatar";
    
    _addressController.add(address);
  }

  // Find closest popular location
  String _findClosestLocation(LatLng location) {
    String closestLocation = 'Doha';
    double minDistance = double.infinity;
    
    _popularLocations.forEach((name, coords) {
      double distance = _calculateDistance(location, coords);
      if (distance < minDistance) {
        minDistance = distance;
        closestLocation = name;
      }
    });
    
    return closestLocation;
  }

  // Get random street name
  String _getRandomStreetName() {
    final List<String> streetNames = [
      'Al Corniche Street',
      'Al Rayyan Road',
      'Salwa Road',
      'Al Waab Street',
      'Al Gharafa Street',
      'Al Khaleej Street',
      'Al Sadd Street',
      'Al Hilal Street',
      'Al Wakra Road',
      'Al Shamal Road',
      'Al Khor Road',
      'Al Wukair Street',
      'Al Thumama Road',
      'Al Sailiya Street',
      'Al Aziziya Street',
    ];
    
    return streetNames[_random.nextInt(streetNames.length)];
  }

  // Calculate distance between two points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    double lat1Rad = point1.latitude * (3.14159265359 / 180);
    double lat2Rad = point2.latitude * (3.14159265359 / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    double a = (sin(deltaLatRad / 2) * sin(deltaLatRad / 2)) +
        cos(lat1Rad) * cos(lat2Rad) * (sin(deltaLngRad / 2) * sin(deltaLngRad / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c / 1000; // Return distance in kilometers
  }

  // Get current location
  LatLng? get currentLocation => _currentLocation;

  // Get current speed
  double get currentSpeed => _currentSpeed;

  // Stop simulation
  void stopSimulation() {
    _locationTimer?.cancel();
    _speedTimer?.cancel();
    _currentSpeed = 0.0;
  }

  // Dispose resources
  void dispose() {
    stopSimulation();
    _locationController.close();
    _speedController.close();
    _addressController.close();
  }
}

