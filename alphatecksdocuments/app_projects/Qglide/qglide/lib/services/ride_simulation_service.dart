import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideSimulationService {
  static final RideSimulationService _instance = RideSimulationService._internal();
  factory RideSimulationService() => _instance;
  RideSimulationService._internal();

  // Simulation data
  final List<Map<String, dynamic>> _availableDrivers = [
    {
      'id': 'driver_001',
      'name': 'Ahmed Al-Farsi',
      'rating': 4.8,
      'totalRides': 1247,
      'vehicle': 'Toyota Camry',
      'plateNumber': 'QTR 5821',
      'phone': '+974 1234 5678',
      'location': const LatLng(25.2048, 55.2708),
      'isAvailable': true,
    },
    {
      'id': 'driver_002',
      'name': 'Mohammed Al-Thani',
      'rating': 4.9,
      'totalRides': 892,
      'vehicle': 'Honda Accord',
      'plateNumber': 'QTR 4521',
      'phone': '+974 2345 6789',
      'location': const LatLng(25.2148, 55.2808),
      'isAvailable': true,
    },
    {
      'id': 'driver_003',
      'name': 'Yousef Al-Mansouri',
      'rating': 4.7,
      'totalRides': 1563,
      'vehicle': 'Nissan Altima',
      'plateNumber': 'QTR 7891',
      'phone': '+974 3456 7890',
      'location': const LatLng(25.1948, 55.2608),
      'isAvailable': true,
    },
  ];

  Timer? _rideTimer;
  Timer? _locationTimer;
  Timer? _etaTimer;
  
  LatLng? _currentDriverLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;
  Map<String, dynamic>? _assignedDriver;
  
  double _currentDistance = 0.0;
  double _totalDistance = 0.0;
  int _estimatedArrivalMinutes = 0;
  double _currentFare = 0.0;
  
  // Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _rideStatusController = StreamController.broadcast();
  final StreamController<LatLng> _driverLocationController = StreamController.broadcast();
  final StreamController<int> _etaController = StreamController.broadcast();
  final StreamController<double> _fareController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _driverUpdateController = StreamController.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get rideStatusStream => _rideStatusController.stream;
  Stream<LatLng> get driverLocationStream => _driverLocationController.stream;
  Stream<int> get etaStream => _etaController.stream;
  Stream<double> get fareStream => _fareController.stream;
  Stream<Map<String, dynamic>> get driverUpdateStream => _driverUpdateController.stream;

  // Start ride booking simulation
  Future<Map<String, dynamic>> startRideBooking({
    required LatLng pickup,
    required LatLng destination,
    required String rideType,
  }) async {
    _pickupLocation = pickup;
    _destinationLocation = destination;
    
    // Calculate total distance
    _totalDistance = _calculateDistance(pickup, destination);
    
    // Find available driver
    await _findAndAssignDriver();
    
    if (_assignedDriver != null) {
      _currentDriverLocation = _assignedDriver!['location'];
      _estimatedArrivalMinutes = _calculateETA(_currentDriverLocation!, pickup);
      _currentFare = _calculateFare(_totalDistance, rideType);
      
      // Start simulation timers
      _startLocationSimulation();
      _startETASimulation();
      
      return {
        'success': true,
        'driver': _assignedDriver,
        'eta': _estimatedArrivalMinutes,
        'fare': _currentFare,
        'distance': _totalDistance,
      };
    }
    
    return {'success': false, 'message': 'No drivers available'};
  }

  // Simulate driver finding and assignment
  Future<void> _findAndAssignDriver() async {
    // Simulate search delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Find closest available driver
    List<Map<String, dynamic>> availableDrivers = _availableDrivers
        .where((driver) => driver['isAvailable'] == true)
        .toList();
    
    if (availableDrivers.isNotEmpty) {
      // Simulate driver selection algorithm
      _assignedDriver = availableDrivers[Random().nextInt(availableDrivers.length)];
      _assignedDriver!['isAvailable'] = false;
      
      // Emit driver found status
      _rideStatusController.add({
        'status': 'driver_found',
        'driver': _assignedDriver,
        'eta': _estimatedArrivalMinutes,
      });
    }
  }

  // Start location simulation
  void _startLocationSimulation() {
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentDriverLocation != null && _pickupLocation != null) {
        // Simulate driver moving towards pickup
        _simulateDriverMovement();
        _driverLocationController.add(_currentDriverLocation!);
      }
    });
    
    // Fallback timer to ensure driver arrives (for demo purposes)
    // REMOVED: Automatic driver arrival transition
    // Timer(const Duration(seconds: 15), () {
    //   if (_currentDriverLocation != null && _pickupLocation != null) {
    //     _onDriverArrived();
    //   }
    // });
  }

  // Start ETA simulation
  void _startETASimulation() {
    _etaTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentDriverLocation != null && _pickupLocation != null) {
        int newETA = _calculateETA(_currentDriverLocation!, _pickupLocation!);
        if (newETA != _estimatedArrivalMinutes) {
          _estimatedArrivalMinutes = newETA;
          _etaController.add(_estimatedArrivalMinutes);
          
          // Emit driver update
          _driverUpdateController.add({
            'status': 'eta_updated',
            'eta': _estimatedArrivalMinutes,
            'location': _currentDriverLocation,
          });
        }
      }
    });
  }

  // Simulate driver movement
  void _simulateDriverMovement() {
    if (_currentDriverLocation == null || _pickupLocation == null) return;
    
    // Calculate direction to pickup
    double latDiff = _pickupLocation!.latitude - _currentDriverLocation!.latitude;
    double lngDiff = _pickupLocation!.longitude - _currentDriverLocation!.longitude;
    
    // Move closer to pickup (simulate realistic movement) - increased speed for demo
    double moveFactor = 0.01; // Much faster movement for demo purposes
    double newLat = _currentDriverLocation!.latitude + (latDiff * moveFactor);
    double newLng = _currentDriverLocation!.longitude + (lngDiff * moveFactor);
    
    _currentDriverLocation = LatLng(newLat, newLng);
    
    // Check if driver has arrived (larger threshold for demo)
    // REMOVED: Automatic driver arrival when close to pickup
    // double distanceToPickup = _calculateDistance(_currentDriverLocation!, _pickupLocation!);
    // if (distanceToPickup < 0.1) { // ~10km threshold for demo
    //   _onDriverArrived();
    // }
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

  // Calculate ETA in minutes
  int _calculateETA(LatLng from, LatLng to) {
    double distance = _calculateDistance(from, to);
    // Assume average speed of 30 km/h in city traffic
    double timeInHours = distance / 30.0;
    return (timeInHours * 60).round();
  }

  // Calculate fare based on distance and ride type
  double _calculateFare(double distance, String rideType) {
    double baseFare = 5.0; // Base fare
    double perKmRate = 2.0; // Per kilometer rate
    
    switch (rideType) {
      case 'Q-Comfort':
        baseFare = 8.0;
        perKmRate = 3.0;
        break;
      case 'Q-XL':
        baseFare = 12.0;
        perKmRate = 4.0;
        break;
      default: // Q-Standard
        baseFare = 5.0;
        perKmRate = 2.0;
        break;
    }
    
    return baseFare + (distance * perKmRate);
  }

  // Cancel ride
  void cancelRide() {
    if (_assignedDriver != null) {
      _assignedDriver!['isAvailable'] = true;
    }
    _cleanup();
    
    _rideStatusController.add({
      'status': 'ride_cancelled',
    });
  }

  // Clean up resources
  void _cleanup() {
    _rideTimer?.cancel();
    _locationTimer?.cancel();
    _etaTimer?.cancel();
    
    _currentDriverLocation = null;
    _pickupLocation = null;
    _destinationLocation = null;
    _assignedDriver = null;
    _currentDistance = 0.0;
    _totalDistance = 0.0;
    _estimatedArrivalMinutes = 0;
    _currentFare = 0.0;
  }

  // Get current ride status
  Map<String, dynamic>? getCurrentRideStatus() {
    if (_assignedDriver == null) return null;
    
    return {
      'driver': _assignedDriver,
      'eta': _estimatedArrivalMinutes,
      'fare': _currentFare,
      'distance': _currentDistance,
      'totalDistance': _totalDistance,
    };
  }

  // Dispose resources
  void dispose() {
    _cleanup();
    _rideStatusController.close();
    _driverLocationController.close();
    _etaController.close();
    _fareController.close();
    _driverUpdateController.close();
  }
}

