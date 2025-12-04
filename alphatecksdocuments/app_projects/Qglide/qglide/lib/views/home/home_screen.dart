import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_places_flutter/model/prediction.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import '../../cubits/theme_cubit.dart';
import '../../cubits/ride_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/places_service.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../services/ride_simulation_service.dart';
import '../../services/chat_simulation_service.dart';
import '../../services/location_simulation_service.dart';
import '../booking/ride_completed_screen.dart';
import '../booking/delivery_order_screen.dart';
import '../booking/rental_screen.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(Widget)? onNavigateToSubScreen;
  final Map<String, dynamic>? prefilledBooking;
  
  const HomeScreen({
    super.key, 
    this.onNavigateToSubScreen,
    this.prefilledBooking,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {

  
  // Google Maps controller
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(25.2854, 51.5310); // Default to Qatar (Doha) coordinates
  bool _isLocationLoading = true;
  Set<Marker> _routeMarkers = {};
  Set<Polyline> _routePolylines = {};
  Set<Circle> _locationCircles = {};
  String _routeDurationText = ''; // Travel time text
  int? _routeDurationMinutes; // Duration in minutes from Google Maps API
  
  // Animation controllers for ripple effect
  late AnimationController _rippleController1;
  late AnimationController _rippleController2;
  late AnimationController _rippleController3;
  
  // Timer for ride completion
  Timer? _rideCompletionTimer;
  Timer? _driverArrivedTimer;
  Timer? _rideStatusPollingTimer; // Timer for polling ride status
  Timer? _driverOnlineStatusPollingTimer; // Timer for polling assigned driver's online status
  
  // Simulation services
  final RideSimulationService _rideSimulation = RideSimulationService();
  final ChatSimulationService _chatSimulation = ChatSimulationService();
  final LocationSimulationService _locationSimulation = LocationSimulationService();

  // Destination input
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _destinationFocusNode = FocusNode();
  String _selectedDestination = '';
  LatLng? _destinationLatLng; // Destination coordinates
  
  // Service selection
  String _selectedService = 'ride'; // 'ride', 'parcel', 'rental'
  
  // Payment method
  String _selectedPaymentMethod = 'Payment Method'; // Default dropdown value
  
  // Pickup location
  String _pickupAddress = 'Getting location...';
  
  // Saved locations
  String? _homeAddress;
  String? _workAddress;
  
  // Ride booking state
  bool _isConnectingToDriver = false;
  bool _isDriverFound = false;
  bool _isDriverArrived = false;
  bool _isRideStarted = false;
  bool _showBookingPanel = false;
  bool _isDeliveryOrder = false; // Track if current order is a delivery
  String _bookingPickupLocation = '';
  String _bookingDestinationLocation = '';
  String _selectedRideType = 'Q-Standard';
  bool _isCreatingRide = false; // Loading state for API call
  
  // Ride pricing state
  Map<String, double?> _ridePrices = {};
  bool _isFetchingPrices = false;
  
  // Driver information from API
  String _driverName = '';
  String _driverCarModel = '';
  String _driverPlateNumber = '';
  double _driverRating = 0.0;
  String? _driverPhotoUrl;
  
  // Real calculated ride data
  double _calculatedDistance = 0.0; // in km
  double _calculatedFare = 0.0; // in QAR
  String _driverETA = '2-5 min'; // Real ETA from API
  String? _currentRideId; // Store the current ride ID
  bool _isDriverOnline = false; // Assigned driver online status from API
  
  // Driver ETA tracking
  DateTime? _estimatedArrivalTime; // Parsed from ride-info API
  int? _minutesUntilArrival; // Calculated minutes remaining
  Timer? _etaPollingTimer; // Timer for polling ride-info for ETA updates
  
  // User profile
  String? _profilePhotoUrl;
  String? _userName; // User's full name or first name
  
  // User country for location restrictions
  String _userCountry = 'QA'; // Default to Qatar
  
  // Cancel ride dialog
  String? _selectedCancelReason;
  final TextEditingController _cancelNotesController = TextEditingController();

  // Nearby drivers tracking
  BitmapDescriptor? _carIcon;
  Map<String, _DriverMarkerState> _driverMarkers = {}; // driver_id -> marker state
  Map<String, Timer> _driverAnimations = {}; // driver_id -> animation timer
  Timer? _nearbyDriversPollingTimer;
  bool _isPollingNearbyDrivers = false;


  @override
  void initState() {
    super.initState();
    
    // CRITICAL FIX: Clear any persisted ride state IMMEDIATELY before first UI build
    // This prevents showing stale panels (connecting/driver found/arrived) while backend verification happens
    final rideState = context.read<RideCubit>().state;
    if (rideState.status != RideStatus.none && rideState.status != RideStatus.rideCompleted) {
      print('⚠️ RIDER - initState: Clearing persisted ride state before first build');
      print('   Old status: ${rideState.status}');
      context.read<RideCubit>().rideCompleted();
      _currentRideId = null;
      _isConnectingToDriver = false;
      _isDriverFound = false;
      _isDriverArrived = false;
      _isRideStarted = false;
      
      // Also clear driver details to force refresh from backend
      _driverName = '';
      _driverCarModel = '';
      _driverPlateNumber = '';
      _driverRating = 0.0;
      _driverPhotoUrl = null;
      print('   Cleared driver details - will be fetched from backend/API');
    }
    
    WidgetsBinding.instance.addObserver(this);
    _getCurrentLocation();
    _fetchUserProfile();
    
    // Initialize animation controllers for ripple effect
    _rippleController1 = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _rippleController2 = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _rippleController3 = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    
    // Initialize simulation listeners
    _initializeSimulationListeners();
    
    // Initialize location circles
    _updateLocationCircles();
    
    // Load car icon for driver markers (will start polling when loaded)
    _loadCarIcon();
    
    // Don't start polling here - wait for car icon and location to be ready
    // Polling will start automatically when both are ready
    
    // Restore saved ride state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreSavedRideState();
      
      // Handle prefilled booking data from repeat ride
      if (widget.prefilledBooking != null) {
        _handlePrefilledBooking(widget.prefilledBooking!);
      }
      
      // If user wasn't authenticated, retry after a short delay
      // This handles the case where HomeScreen is created before login completes
      if (!ApiService.isAuthenticated) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && ApiService.isAuthenticated) {
            print('🔄 RIDER - Retrying restoration after authentication');
            _restoreSavedRideState();
          }
        });
      }
      
      // ALSO check backend for active rides (handles logout/login scenario)
      // This is crucial because logout clears local state but ride might still be active on backend
      _checkBackendForActiveRides();
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('📱 RIDER - APP RESUMED');
      // Refresh profile data when app comes back to foreground
      _refreshUserData();
      // Resume polling for nearby drivers if not in active ride
      if (!_isConnectingToDriver && !_isDriverFound && !_isDriverArrived && !_isRideStarted && !_isPollingNearbyDrivers) {
        _startNearbyDriversPolling();
      }
    } else if (state == AppLifecycleState.paused) {
      // Pause polling when app goes to background to save battery
      _stopNearbyDriversPolling();
    }
  }
  
  Future<void> _refreshUserData() async {
    // Reload firstName from SharedPreferences
    await ApiService.loadStoredToken();
    // Refresh profile photo
    _fetchUserProfile();
    // DON'T call setState() - it resets UI flags!
    // The BlocBuilder will automatically rebuild when data changes
    print('✅ RIDER - Profile data refreshed (no setState to avoid flag reset)');
    
    // Also attempt to restore ride state if user just logged in
    if (ApiService.isAuthenticated) {
      final rideState = context.read<RideCubit>().state;
      // Only attempt restoration if there's a persisted ride and we haven't already restored it
      if (rideState.status != RideStatus.none && 
          rideState.status != RideStatus.rideCompleted &&
          _currentRideId == null) {
        print('🔄 RIDER - Attempting restoration after app resume/login');
        _restoreSavedRideState();
      }
    }
  }
  
  Future<void> _fetchUserProfile() async {
    try {
      print('🏠 HOME: FETCHING USER PROFILE...');
      final response = await ApiService.getUserProfile();
      
      print('🏠 HOME: FULL RESPONSE: $response');
      
      if (response['success'] && mounted) {
        // Handle double nesting: response['data']['data']['profile']
        final outerData = response['data'];
        final innerData = outerData['data'] ?? outerData;
        final profile = innerData['profile'] ?? innerData;
        
        print('🏠 HOME: PROFILE DATA: $profile');
        
        final photoUrl = profile['avatar_url']?.toString();
        final fullName = profile['full_name']?.toString() ?? profile['name']?.toString();
        final firstName = profile['first_name']?.toString();
        
        print('🏠 HOME: PROFILE PHOTO URL: $photoUrl');
        print('🏠 HOME: USER NAME: Full=$fullName, First=$firstName');
        
        setState(() {
          _profilePhotoUrl = photoUrl;
          _userName = firstName ?? fullName?.split(' ').first ?? 'there';
        });
        
        print('🏠 HOME: SET USERNAME TO: $_userName');
      } else {
        print('❌ HOME: GET PROFILE FAILED');
      }
    } catch (e) {
      print('❌ HOME: GET PROFILE ERROR: $e');
    }
  }
  
  void _restoreSavedRideState() {
    final rideState = context.read<RideCubit>().state;
    
    print('🔄 RIDER - _restoreSavedRideState called');
    print('   RideCubit state: ${rideState.status}');
    print('   Ride ID: ${rideState.rideId}');
    
    // Check if user is authenticated
    if (!ApiService.isAuthenticated) {
      print('❌ RIDER - USER NOT AUTHENTICATED - Cannot restore ride state yet');
      print('   Will wait for login to complete');
      return;
    }

    // Check if there's an active ride in RideCubit (including newly created ones)
    if (rideState.status != RideStatus.none && 
        rideState.status != RideStatus.rideCompleted &&
        rideState.rideId != null && rideState.rideId!.isNotEmpty) {
      
      print('✅ RIDER - Found active ride in RideCubit: ${rideState.status}');
      print('   Ride ID: ${rideState.rideId}');
      print('   Pickup: ${rideState.pickupLocation}');
      print('   Destination: ${rideState.destinationLocation}');
      
      // Set the ride ID and start polling
      _currentRideId = rideState.rideId;
      _bookingPickupLocation = rideState.pickupLocation;
      _bookingDestinationLocation = rideState.destinationLocation;
      
      // Set UI state based on ride status
      setState(() {
        switch (rideState.status) {
          case RideStatus.searching:
            _isConnectingToDriver = true;
            _stopNearbyDriversPolling(); // Stop showing nearby drivers when searching
            _rippleController1.repeat();
            _rippleController2.repeat();
            _rippleController3.repeat();
            break;
          case RideStatus.driverFound:
            _isDriverFound = true;
            _startDriverOnlineStatusPolling();
            break;
          case RideStatus.driverArrived:
            _isDriverArrived = true;
            break;
          case RideStatus.rideStarted:
            _isRideStarted = true;
            break;
          case RideStatus.none:
          case RideStatus.rideCompleted:
            // Ride ended - restart showing nearby drivers
            _isConnectingToDriver = false;
            _isDriverFound = false;
            _isDriverArrived = false;
            _isRideStarted = false;
            _isDriverOnline = false;
            _stopDriverOnlineStatusPolling();
            _clearAllDriverMarkers(); // Clear driver markers when ride ends
            if (!_isPollingNearbyDrivers) {
              _startNearbyDriversPolling(); // Restart polling for nearby drivers
            }
            break;
        }
      });
      
      // Start polling for ride status updates
      _startRideStatusPolling();
      print('✅ RIDER - Started polling for ride updates');
      
    } else {
      print('✅ RIDER - No active ride in RideCubit, checking backend...');
      // No active ride in RideCubit, check backend for any active rides
      _checkBackendForActiveRides();
    }
  }

  void _handlePrefilledBooking(Map<String, dynamic> data) async {
    print('🔄 RIDER - Handling prefilled booking from repeat ride');
    print('   Pickup: ${data['pickupAddress']}');
    print('   Destination: ${data['destinationAddress']}');
    
    // Skip country validation for repeat rides - they were already validated when originally booked
    // This prevents false positives when _userCountry might not be set yet or API temporarily fails
    
    // Set pickup location (current location from repeat ride)
    _currentPosition = LatLng(data['pickupLat'], data['pickupLng']);
    _pickupAddress = data['pickupAddress'];
    
    // Set destination
    _selectedDestination = data['destinationAddress'];
    _destinationLatLng = LatLng(data['destinationLat'], data['destinationLng']);
    _destinationController.text = data['destinationAddress'];
    
    // Draw route on map
    await _drawRouteOnMap();
    
    // Calculate distance and fare
    final distance = ApiService.calculateDistance(
      lat1: _currentPosition.latitude,
      lng1: _currentPosition.longitude,
      lat2: _destinationLatLng!.latitude,
      lng2: _destinationLatLng!.longitude,
    );
    
    final fare = ApiService.calculateFare(distance);
    
    // Show booking panel with the prefilled data
    setState(() {
      _showBookingPanel = true;
      _bookingPickupLocation = data['pickupAddress'];
      _bookingDestinationLocation = data['destinationAddress'];
      _calculatedDistance = distance;
      _calculatedFare = fare;
    });
    
    print('✅ RIDER - Booking panel shown with prefilled data');
    print('   Distance: ${distance.toStringAsFixed(2)} km');
    print('   Fare: QAR ${fare.toStringAsFixed(2)}');
  }
  
  /// Check backend for any active rides (handles logout/login scenario)
  /// This is called on app start to restore rides that were cleared during logout
  Future<void> _checkBackendForActiveRides() async {
    if (!ApiService.isAuthenticated) {
      print('❌ RIDER - Not authenticated, skipping backend check');
      return;
    }
    
    // Don't check if we already have an active ride locally
    if (_currentRideId != null) {
      print('✅ RIDER - Already have active ride locally, skipping backend check');
      return;
    }
    
    print('🔍 RIDER - Checking backend for active rides...');
    
    try {
      // Call ride-status without ride_id to get any active rides for this user
      final response = await ApiService.getRideStatus();
      
      print('📡 RIDER - BACKEND CHECK RESPONSE:');
      print('   Success: ${response['success']}');
      print('   Full Response: $response');
      
      if (response['success']) {
        final data = response['data'];
        var status = 'unknown';
        var rideData;
        String? rideId;
        
        print('📊 RIDER - BACKEND CHECK DATA:');
        print('   Data type: ${data.runtimeType}');
        print('   Data keys: ${data is Map ? data.keys.toList() : "not a map"}');
        
        // Extract ride data using same logic as polling
        if (data is Map && data.containsKey('status')) {
          status = data['status'] ?? 'unknown';
          rideData = data;
          rideId = data['ride_id'] ?? data['id'];
        } else if (data is Map && data.containsKey('ride')) {
          rideData = data['ride'];
          status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
          rideId = rideData?['ride_id'] ?? rideData?['id'];
        } else if (data is Map && data.containsKey('rides')) {
          final rides = data['rides'];
          if (rides is List && rides.isNotEmpty) {
            rideData = rides[0];
            status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
            rideId = rideData?['ride_id'] ?? rideData?['id'];
          } else if (rides is List && rides.isEmpty) {
            // CRITICAL FIX: Empty rides array means no active ride
            print('🧹 RIDER - Backend check: Rides array is empty - no active ride');
            status = 'completed'; // Treat as completed to trigger cleanup
          }
        } else if (data is Map && data.containsKey('data')) {
          final nestedData = data['data'];
          if (nestedData is Map && nestedData.containsKey('rides')) {
            final rides = nestedData['rides'];
            if (rides is List && rides.isNotEmpty) {
              rideData = rides[0];
              status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
              rideId = rideData?['ride_id'] ?? rideData?['id'];
            } else if (rides is List && rides.isEmpty) {
              // CRITICAL FIX: Empty rides array means no active ride
              print('🧹 RIDER - Backend check: Nested rides array is empty - no active ride');
              status = 'completed'; // Treat as completed to trigger cleanup
            }
          } else if (nestedData is Map && nestedData.containsKey('ride')) {
            rideData = nestedData['ride'];
            status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
            rideId = rideData?['ride_id'] ?? rideData?['id'];
          }
        }
        
        final normalizedStatus = status.toString().trim().toLowerCase();
        print('🔍 RIDER - Backend ride status: $normalizedStatus, rideId: $rideId');
        print('   Ride data: $rideData');
        
        // If there's an active ride on backend, restore it
        if (rideId != null && rideId.isNotEmpty && 
            normalizedStatus != 'completed' && normalizedStatus != 'finished' &&
            normalizedStatus != 'cancelled' && normalizedStatus != 'driver_cancelled' &&
            normalizedStatus != 'unknown') {
          
          print('✅ RIDER - Found active ride on backend! Restoring...');
          
          // Set ride ID and sync with cubit
          _currentRideId = rideId;
          context.read<RideCubit>().syncFromApiStatus(normalizedStatus);
          
          // Extract ride details
          final pickupAddress = rideData?['pickup_address'] ?? '';
          final dropoffAddress = rideData?['dropoff_address'] ?? '';
          final fare = rideData?['estimated_fare'] ?? rideData?['fare'] ?? 0.0;
          
          // Extract driver info
          final driver = rideData?['driver'];
          print('👤 RIDER - DRIVER DATA FROM BACKEND: $driver');
          
          // Extract dropoff coordinates for ride-info call
          final dropoffLocation = rideData?['dropoff_location'];
          
          // Set destination coordinates BEFORE calling ride-info API
          if (dropoffLocation != null) {
            try {
              final coords = dropoffLocation.toString().replaceAll('(', '').replaceAll(')', '').split(',');
              if (coords.length == 2) {
                _destinationLatLng = LatLng(double.parse(coords[0]), double.parse(coords[1]));
                print('✅ RIDER - Destination coordinates restored: $_destinationLatLng');
              }
            } catch (e) {
              print('❌ RIDER - Error parsing destination coordinates: $e');
            }
          }
          
          // Also try extracting from direct latitude/longitude fields
          if (_destinationLatLng == null && rideData?['dropoff_latitude'] != null && rideData?['dropoff_longitude'] != null) {
            try {
              final lat = double.parse(rideData['dropoff_latitude'].toString());
              final lng = double.parse(rideData['dropoff_longitude'].toString());
              _destinationLatLng = LatLng(lat, lng);
              print('✅ RIDER - Destination coordinates from lat/lng fields: $_destinationLatLng');
            } catch (e) {
              print('❌ RIDER - Error parsing lat/lng fields: $e');
            }
          }
          
          setState(() {
            _bookingPickupLocation = pickupAddress;
            _bookingDestinationLocation = dropoffAddress;
            _calculatedFare = (fare is num) ? fare.toDouble() : double.tryParse(fare.toString()) ?? 0.0;
            
            // Populate driver info if available (will be overwritten by ride-info API)
            if (driver != null) {
              _driverName = driver['name'] ?? driver['full_name'] ?? 'Driver';
              _driverCarModel = driver['vehicle']?['model'] ?? driver['car_model'] ?? 'Vehicle';
              _driverPlateNumber = driver['vehicle']?['plate_number'] ?? driver['plate_number'] ?? 'N/A';
              _driverRating = (driver['rating'] ?? 0).toDouble();
              _driverPhotoUrl = driver['avatar_url'] ?? driver['photo_url'] ?? driver['profile_picture'];
              
              print('📋 DRIVER INFO FROM BACKEND (will be refreshed):');
              print('   Name: $_driverName');
              print('   Car: $_driverCarModel - $_driverPlateNumber');
              print('   Rating: $_driverRating');
              print('   Photo: $_driverPhotoUrl');
            }
          });
          
          // ALWAYS fetch fresh driver info from ride-info API after hot restart
          final isDriverAssigned = (normalizedStatus == 'accepted' || 
                                     normalizedStatus == 'driver_assigned' ||
                                     normalizedStatus == 'confirmed' ||
                                     normalizedStatus == 'in_progress' ||
                                     normalizedStatus == 'driver_found' ||
                                     normalizedStatus == 'assigned');
          
          if (isDriverAssigned) {
            print('╔════════════════════════════════════════════════════════════════╗');
            print('║  🔄 RIDER - HOT RESTART: Fetching fresh driver info           ║');
            print('╚════════════════════════════════════════════════════════════════╝');
            print('   Ride ID: $_currentRideId');
            print('   Ride Status: $normalizedStatus');
            
            // Use destination coordinates if available, otherwise use pickup as fallback
            final dropoffLat = _destinationLatLng?.latitude ?? _currentPosition.latitude;
            final dropoffLng = _destinationLatLng?.longitude ?? _currentPosition.longitude;
            final dropoffAddr = _destinationLatLng != null ? dropoffAddress : pickupAddress;
            
            if (_destinationLatLng == null) {
              print('⚠️ RIDER - No destination coordinates yet, using pickup as fallback for ride-info call');
            }
            
            if (_currentRideId != null) {
              try {
                print('📞 RIDER - CALLING ride-info API (HOT RESTART)...');
                print('   Parameters:');
                print('     ride_id: $_currentRideId');
                print('     pickup_lat: ${_currentPosition.latitude}');
                print('     pickup_lng: ${_currentPosition.longitude}');
                print('     pickup_address: $pickupAddress');
                print('     dropoff_lat: $dropoffLat');
                print('     dropoff_lng: $dropoffLng');
                print('     dropoff_address: $dropoffAddr');
                
                final rideInfoResponse = await ApiService.getRideInfo(
                  rideId: _currentRideId!,
                  pickupLat: _currentPosition.latitude,
                  pickupLng: _currentPosition.longitude,
                  pickupAddress: pickupAddress,
                  dropoffLat: dropoffLat,
                  dropoffLng: dropoffLng,
                  dropoffAddress: dropoffAddr,
                );
                
                print('📡 RIDER - ride-info API RESPONSE (HOT RESTART):');
                print('   Success: ${rideInfoResponse['success']}');
                print('   Full Response: $rideInfoResponse');
                
                if (rideInfoResponse['success'] == true && rideInfoResponse['data'] != null) {
                  final outerData = rideInfoResponse['data'];
                  print('📊 RIDER - Response data structure (HOT RESTART):');
                  print('   Outer data type: ${outerData.runtimeType}');
                  print('   Outer data keys: ${outerData is Map ? outerData.keys.toList() : "not a map"}');
                  
                  final nestedData = outerData['data'];
                  print('📊 RIDER - Nested data (HOT RESTART):');
                  print('   Nested data type: ${nestedData.runtimeType}');
                  print('   Nested data keys: ${nestedData is Map ? nestedData.keys.toList() : "not a map"}');
                  
                  final fetchedRideData = nestedData?['ride'];
                  print('📊 RIDER - Ride data (HOT RESTART):');
                  print('   Ride exists: ${fetchedRideData != null}');
                  if (fetchedRideData != null) {
                    print('   Ride data keys: ${fetchedRideData is Map ? fetchedRideData.keys.toList() : "not a map"}');
                  }
                  
                  final fetchedDriver = fetchedRideData?['driver'];
                  print('👤 RIDER - Driver data from ride-info (HOT RESTART):');
                  print('   Driver exists: ${fetchedDriver != null}');
                  if (fetchedDriver != null) {
                    print('   Driver data keys: ${fetchedDriver is Map ? fetchedDriver.keys.toList() : "not a map"}');
                    print('   Full driver data: $fetchedDriver');
                  }
                  
                  if (fetchedDriver != null && mounted) {
                    setState(() {
                      _driverName = fetchedDriver['name'] ?? fetchedDriver['full_name'] ?? 'Driver';
                      _driverCarModel = fetchedDriver['vehicle']?['model'] ?? fetchedDriver['car_model'] ?? 'Vehicle';
                      _driverPlateNumber = fetchedDriver['vehicle']?['plate_number'] ?? fetchedDriver['plate_number'] ?? 'N/A';
                      _driverRating = (fetchedDriver['rating'] ?? 0).toDouble();
                      _driverPhotoUrl = fetchedDriver['avatar_url'] ?? fetchedDriver['photo_url'] ?? fetchedDriver['profile_picture'];
                    });
                    
                    // Update ETA and driver location from ride data
                    _updateETAFromRideInfo(fetchedRideData);
                    
                    print('╔════════════════════════════════════════════════════════════════╗');
                    print('║  ✅ RIDER - Driver info REFRESHED from ride-info API         ║');
                    print('╚════════════════════════════════════════════════════════════════╝');
                    print('   Name: $_driverName');
                    print('   Car: $_driverCarModel');
                    print('   Plate: $_driverPlateNumber');
                    print('   Rating: $_driverRating');
                    print('   Photo URL: $_driverPhotoUrl');
                  } else {
                    print('❌ RIDER - No driver data in ride-info response');
                  }
                } else {
                  print('❌ RIDER - ride-info API failed or returned no data');
                  print('   Error: ${rideInfoResponse['error']}');
                }
              } catch (e, stackTrace) {
                print('❌ RIDER - ERROR fetching driver info from ride-info: $e');
                print('   Stack trace: $stackTrace');
              }
            }
          }
          
          // Now restore UI and start polling
          final rideState = context.read<RideCubit>().state;
          if (rideState.status != RideStatus.none) {
            _verifyAndStartPolling(rideState);
          }
        } else {
          print('✅ RIDER - No active ride found on backend');
        }
      }
    } catch (e) {
      print('❌ RIDER - Error checking backend for active rides: $e');
    }
  }
  
  // Verify ride status on backend before starting polling
  Future<void> _verifyAndStartPolling(RideState rideState) async {
    if (_currentRideId == null) return;
    
    try {
      final response = await ApiService.getRideStatus(rideId: _currentRideId);
      
      if (response['success']) {
        final data = response['data'];
        var status = 'unknown';
        var rideData;
        
        // Extract status (FULL logic from polling)
        if (data is Map && data.containsKey('status')) {
          status = data['status'] ?? 'unknown';
          rideData = data;
        } else if (data is Map && data.containsKey('ride')) {
          rideData = data['ride'];
          status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
        } else if (data is Map && data.containsKey('rides')) {
          final rides = data['rides'];
          if (rides is List && rides.isNotEmpty) {
            rideData = rides[0];
            status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
          }
        } else if (data is Map && data.containsKey('data')) {
          final nestedData = data['data'];
          if (nestedData is Map && nestedData.containsKey('rides')) {
            final rides = nestedData['rides'];
            if (rides is List && rides.isNotEmpty) {
              rideData = rides[0];
              status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
            }
          } else if (nestedData is Map && nestedData.containsKey('ride')) {
            rideData = nestedData['ride'];
            status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
          }
        }
        
        final normalizedStatus = status.toString().trim().toLowerCase();
        print('🔄 RIDER - VERIFIED BACKEND STATUS: $normalizedStatus');
        
        // FIRST: Sync RideCubit with API status (single source of truth)
        context.read<RideCubit>().syncFromApiStatus(normalizedStatus);
        final syncedRideState = context.read<RideCubit>().state;
        print('🔄 RIDER - RideCubit synced on verification. State: ${syncedRideState.status}');
        
        // If ride is already completed or cancelled, don't restore or start polling
        if (syncedRideState.status == RideStatus.none || 
            syncedRideState.status == RideStatus.rideCompleted) {
          print('❌ RIDER - RIDE ALREADY COMPLETED/CANCELLED - NOT RESTORING UI');
          
          setState(() {
            _isConnectingToDriver = false;
            _isDriverFound = false;
            _isDriverArrived = false;
            _isRideStarted = false;
            _bookingPickupLocation = '';
            _bookingDestinationLocation = '';
            _currentRideId = null;
          });
          return;
        }
        
        // Ride is still active - NOW restore UI state and start polling
        print('✅ RIDER - RIDE STILL ACTIVE - RESTORING UI AND STARTING POLLING');
        print('🔍 RIDER - RESTORING FROM SYNCED RIDE STATE: ${syncedRideState.status}');
        
        // Extract driver info before restoring UI
        final driver = rideData?['driver'];
        print('👤 RIDER - DRIVER DATA FROM VERIFY: $driver');
        
        setState(() {
        // Populate driver info if available
        if (driver != null) {
          _driverName = driver['name'] ?? driver['full_name'] ?? 'Driver';
          _driverCarModel = driver['vehicle']?['model'] ?? driver['car_model'] ?? 'Vehicle';
          _driverPlateNumber = driver['vehicle']?['plate_number'] ?? driver['plate_number'] ?? 'N/A';
          _driverRating = (driver['rating'] ?? 0).toDouble();
          _driverPhotoUrl = driver['avatar_url'] ?? driver['photo_url'] ?? driver['profile_picture'];
          
          print('✅ DRIVER INFO SET ON VERIFY:');
          print('   Name: $_driverName');
          print('   Car: $_driverCarModel - $_driverPlateNumber');
          print('   Rating: $_driverRating');
          print('   Photo: $_driverPhotoUrl');
        }
        
        // Set UI state based on synced ride status from API
        switch (syncedRideState.status) {
          case RideStatus.searching:
            print('🎯 RIDER - SETTING UI: connecting=true');
            _isConnectingToDriver = true;
            _rippleController1.repeat();
            _rippleController2.repeat();
            _rippleController3.repeat();
            break;
          case RideStatus.driverFound:
            print('🎯 RIDER - SETTING UI: found=true');
            _isDriverFound = true;
            _startDriverOnlineStatusPolling();
            break;
          case RideStatus.driverArrived:
            print('🎯 RIDER - SETTING UI: arrived=true');
            _isDriverArrived = true;
            break;
          case RideStatus.rideStarted:
            print('🎯 RIDER - SETTING UI: started=true');
            _isRideStarted = true;
            // Driver is definitely assigned; ensure polling is running
            _startDriverOnlineStatusPolling();
            break;
          default:
            print('⚠️ RIDER - UNKNOWN STATUS, NOT SETTING ANY UI FLAGS: ${syncedRideState.status}');
            break;
        }
        
        print('🎯 RIDER - AFTER setState: connecting=$_isConnectingToDriver, found=$_isDriverFound, arrived=$_isDriverArrived, started=$_isRideStarted');
      });
        
        // Force rebuild to show correct panel
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
        setState(() {
              print('🔄 RIDER - FORCED REBUILD TO SHOW PANEL');
            });
          }
        });
        
        _startRideStatusPolling();
      } else {
        // If we can't verify, clear the ride to be safe
        print('⚠️ RIDER - CANNOT VERIFY RIDE STATUS - CLEARING');
        context.read<RideCubit>().rideCompleted();
        setState(() {
          _isConnectingToDriver = false;
          _isDriverFound = false;
          _isDriverArrived = false;
          _isRideStarted = false;
          _currentRideId = null;
        });
      }
    } catch (e) {
      // If verification fails, clear the ride to be safe
      print('❌ RIDER - VERIFICATION ERROR: $e - CLEARING');
      context.read<RideCubit>().rideCompleted();
      setState(() {
        _isConnectingToDriver = false;
        _isDriverFound = false;
        _isDriverArrived = false;
        _isRideStarted = false;
        _currentRideId = null;
      });
    }
  }
  
  void _initializeSimulationListeners() {
    // SIMULATION DISABLED - Using real API status polling instead
    // Listen to ride status updates
    // _rideSimulation.rideStatusStream.listen((status) { // Debug output
    //   if (mounted) {
    //     setState(() {
    //       switch (status['status']) {
    //         case 'driver_found':
    //           _isConnectingToDriver = false;
    //           _isDriverFound = true;
    //           break;
    //         case 'driver_arrived':
    //           _isDriverFound = false;
    //           _isDriverArrived = true;
    //           break;
    //         case 'ride_started':
    //           _isDriverArrived = false;
    //           _isRideStarted = true;
    //           break;
    //         case 'trip_completed':
    //           _isRideStarted = false;
    //           _showRideCompletedScreen();
    //           break;
    //       }
    //     });
    //   }
    // });
    
    // SIMULATION DISABLED - Using real location tracking instead
    // Listen to driver location updates
    // _rideSimulation.driverLocationStream.listen((location) {
    //   if (mounted) {
    //     setState(() {
    //       // Update driver marker on map
    //       _updateDriverMarker(location);
    //     });
    //   }
    // });
    
    // SIMULATION DISABLED - Using real API data instead
    // Listen to ETA updates
    // _rideSimulation.etaStream.listen((eta) {
    //   if (mounted) {
    //     setState(() {
    //       // Update ETA display
    //     });
    //   }
    // });
    
    // SIMULATION DISABLED
    // Listen to fare updates
    // _rideSimulation.fareStream.listen((fare) {
    //   if (mounted) {
    //     setState(() {
    //       // Update fare display
    //     });
    //   }
    // });
  }

  void _onDestinationSelected(Prediction prediction) async {
    // Dismiss keyboard when destination is selected
    _destinationFocusNode.unfocus();    
    // Validate location is in user's country
    if (prediction.lat != null && prediction.lng != null) {
      bool isInCountry = await PlacesService.isLocationInCountry(
        double.parse(prediction.lat!),
        double.parse(prediction.lng!),
        _userCountry,
      );
      
      if (!isInCountry) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a location within your country'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    setState(() {
      _selectedDestination = prediction.description ?? '';
      _destinationController.text = _selectedDestination;
      
      // Extract lat/lng from prediction
      if (prediction.lat != null && prediction.lng != null) {
        _destinationLatLng = LatLng(
          double.parse(prediction.lat!),
          double.parse(prediction.lng!),
        );
      } else {
        _destinationLatLng = null;
      }
    });
    
    // Draw route on map if destination coordinates are available
    if (_destinationLatLng != null) {
      await _drawRouteOnMap();
    }
  }

  void _handleQuickLocationTap(String label, int index) {
    switch (index) {
      case 0: // Home
        _handleHomeTap();
        break;
      case 1: // Work
        _handleWorkTap();
        break;
      case 2: // Favourites
        _handleFavouritesTap();
        break;
    }
  }

  void _handleHomeTap() {
    if (_homeAddress != null) {
      // If Home is already set, use it as destination
        setState(() {
        _selectedDestination = _homeAddress!;
        _destinationController.text = _homeAddress!;
      });
    } else {
      // If Home is not set, set current location as Home
      _showSetLocationDialog('Home', (address) {
        setState(() {
          _homeAddress = address;
        });
      });
    }
  }

  void _handleWorkTap() {
    if (_workAddress != null) {
      // If Work is already set, use it as destination
          setState(() {
        _selectedDestination = _workAddress!;
        _destinationController.text = _workAddress!;
      });
    } else {
      // If Work is not set, set current location as Work
      _showSetLocationDialog('Work', (address) {
        setState(() {
          _workAddress = address;
        });
      });
    }
  }

  void _handleFavouritesTap() {
    // For now, just show a message that this feature is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Favourites feature coming soon!'),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareLiveLocation() async {
    try {
      // Get current location
      final position = await LocationService.getCurrentPosition();
      
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get your current location'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Create shareable location data
      final lat = position.latitude;
      final lng = position.longitude;
      final googleMapsUrl = 'https://www.google.com/maps?q=$lat,$lng';
      
      // Get user's first name
      final firstName = ApiService.firstName ?? 'Rider';
      
      // Create share message
      final shareText = '''
📍 Live Location Shared from Qglide

👤 From: $firstName
🗺️ Location: https://www.google.com/maps?q=$lat,$lng

📱 Track my location in real-time:
$googleMapsUrl

⏰ Shared at: ${DateTime.now().toString().split('.')[0]}

🚗 Ride ID: ${_currentRideId ?? 'N/A'}
''';
      
      // Share using native share sheet
      await Share.share(
        shareText,
        subject: 'Live Location - Qglide Ride',
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
                decoration: BoxDecoration(
                  color: themeState.panelBg,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emergency Icon
                    Center(
                      child: Container(
                        width: ResponsiveHelper.getResponsiveSpacing(context, 60),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 60),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emergency,
                          color: Colors.white,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 30),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                    
                    // Title
                    Center(
                      child: Text(
                        'Report Emergency',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    Center(
                      child: Text(
                        'Your safety is our priority',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeState.textSecondary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // Emergency Actions
                    _buildEmergencyActionButton(
                      icon: Icons.shield,
                      title: 'Contact Qglide Safety',
                      subtitle: 'Report incident to our safety team',
                      onTap: () {
                        // Handle safety team contact
                        Navigator.of(dialogContext).pop();
                      },
                      themeState: themeState,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    
                    _buildEmergencyActionButton(
                      icon: Icons.report,
                      title: 'Report Driver',
                      subtitle: 'Report inappropriate behavior or concerns',
                      onTap: () {
                        // Handle report driver
                        Navigator.of(dialogContext).pop();
                      },
                      themeState: themeState,
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    
                    _buildEmergencyActionButton(
                      icon: Icons.share_location,
                      title: 'Share Live Location',
                      subtitle: 'Share your trip with trusted contacts',
                      onTap: () async {
                        Navigator.of(dialogContext).pop();
                        await _shareLiveLocation();
                      },
                      themeState: themeState,
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // Cancel Button
                    Container(
                      width: double.infinity,
                      height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: themeState.fieldBorder,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: themeState.textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildEmergencyActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeState themeState,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
        decoration: BoxDecoration(
          color: themeState.fieldBg,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          border: Border.all(color: themeState.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
              height: ResponsiveHelper.getResponsiveSpacing(context, 40),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.red.shade700,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: themeState.textSecondary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelRideDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setDialogState) {
                  return Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ),
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    decoration: BoxDecoration(
                      color: themeState.panelBg,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Title
                        Text(
                          'Cancel Ride?',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Text(
                          'Please let us know why you\'re canceling',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeState.textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        
                        // Cancellation Reasons
                        Text(
                          'Reason',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        
                        // Dropdown for cancellation reasons
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                            vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
                          ),
                          decoration: BoxDecoration(
                            color: themeState.isDarkTheme ? Colors.grey[800] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                            border: Border.all(
                              color: _selectedCancelReason != null 
                                ? AppColors.gold 
                                : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCancelReason,
                              hint: Text(
                                'Select a reason',
                                style: TextStyle(
                                  color: themeState.textSecondary.withOpacity(0.6),
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                                ),
                              ),
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: themeState.textPrimary,
                              ),
                              dropdownColor: themeState.panelBg,
                              style: TextStyle(
                                color: themeState.textPrimary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                              ),
                              items: [
                                'Changed my mind',
                                'Wrong destination',
                                'Taking too long',
                                'Found another ride',
                                'Driver issues',
                                'Other',
                              ].map((String reason) {
                                return DropdownMenuItem<String>(
                                  value: reason,
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      color: themeState.textPrimary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setDialogState(() {
                                  _selectedCancelReason = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                        
                        // Additional Notes
                        Text(
                          'Additional Notes (Optional)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        
                        TextField(
                          controller: _cancelNotesController,
                          maxLines: 3,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Please provide more details...',
                            hintStyle: TextStyle(
                              color: themeState.textSecondary.withOpacity(0.6),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            ),
                            filled: true,
                            fillColor: themeState.isDarkTheme 
                              ? Colors.grey[800] 
                              : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                          ),
                        ),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        
                        // Action Buttons
                        Row(
                          children: [
                            // Go Back Button
                            Expanded(
                              child: Container(
                                height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: themeState.isDarkTheme 
                                      ? Colors.grey[700]! 
                                      : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                ),
                                child: TextButton(
                                  onPressed: () {
                                    _cancelNotesController.clear();
                                    _selectedCancelReason = null;
                                    Navigator.of(dialogContext).pop();
                                  },
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                    ),
                                  ),
                                  child: Text(
                                    'Go Back',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: themeState.textSecondary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                            
                            // Confirm Cancel Button
                            Expanded(
                              child: Container(
                                height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                                decoration: BoxDecoration(
                                  color: _selectedCancelReason != null 
                                    ? Colors.red.shade700 
                                    : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                ),
                                child: TextButton(
                                  onPressed: _selectedCancelReason != null
                                    ? () {
                                        Navigator.of(dialogContext).pop();
                                        _cancelRide();
                                      }
                                    : null,
                                  style: TextButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                    ),
                                  ),
                                  child: Text(
                                    'Confirm',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _cancelRide() async {
    // Validate that we have a ride to cancel
    if (_currentRideId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No active ride to cancel'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }    
    
    print('🚫 RIDER - CANCELING RIDE - Ride ID: $_currentRideId, Reason: ${_selectedCancelReason ?? "Other"}');
    
    try {
      // Call cancel ride API
      final response = await ApiService.cancelRide(
        rideId: _currentRideId!,
        cancelledBy: 'rider',
        reason: _selectedCancelReason ?? 'Other',
        reasonNote: _cancelNotesController.text.isNotEmpty ? _cancelNotesController.text : null,
      );
      
      if (response['success']) {
        print('🚫 RIDER - RIDE CANCELED SUCCESSFULLY - Ride ID: $_currentRideId');
        final successMessage = response['data']?['message'] ?? 
                               response['message'] ?? 
                               'Ride canceled successfully';
        
        if (mounted) {
          setState(() {
            _isConnectingToDriver = false;
            _isDriverFound = false;
            _isDriverArrived = false;
            _isRideStarted = false;
            _bookingPickupLocation = '';
            _bookingDestinationLocation = '';
            _currentRideId = null; // Clear ride ID
          });
          
          // Clear ride from RideCubit (removes from persistent storage)
          context.read<RideCubit>().cancelRide();
          
          // Stop ride status polling
          _stopRideStatusPolling();
          
          // Stop ETA polling
          _stopETAPolling();
          
          // Cancel ride completion timer
          _rideCompletionTimer?.cancel();
          _driverArrivedTimer?.cancel();
          
          // Stop all ripple animations
          _rippleController1.stop();
          _rippleController2.stop();
          _rippleController3.stop();
          _rippleController1.reset();
          _rippleController2.reset();
          _rippleController3.reset();
          
          // Cancel simulation services
          _rideSimulation.cancelRide();
          _locationSimulation.stopSimulation();
          _chatSimulation.stopPeriodicUpdates();
          
          // Clear cancel dialog data
          _cancelNotesController.clear();
          _selectedCancelReason = null;
          
          // Show success message from API
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: AppColors.gold,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {        
        String errorMessage = 'Failed to cancel ride. Please try again.';
        if (response['error'] != null) {
          if (response['error'] is String) {
            errorMessage = response['error'];
          } else if (response['error'] is Map) {
            final error = response['error'];
            errorMessage = error['message'] ?? error['error'] ?? 'Failed to cancel ride. Please try again.';
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showRideCompletedScreen() {
    print('🏁 RIDER - SHOWING RIDE COMPLETED SCREEN - Stopping all services');
    
    // Stop all timers and services
    _stopRideStatusPolling();
    _rideCompletionTimer?.cancel();
    _driverArrivedTimer?.cancel();
    
    // Stop animations
    _rippleController1.stop();
    _rippleController2.stop();
    _rippleController3.stop();
    _rippleController1.reset();
    _rippleController2.reset();
    _rippleController3.reset();
    
    
    // Note: RideCubit is already cleared before this function is called
    // Save ride ID before clearing
    final completedRideId = _currentRideId;
    
    // Clear local ride ID
    _currentRideId = null;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideCompletedScreen(
          driverName: _driverName.isNotEmpty ? _driverName : 'Ahmed Al-Farsi',
          vehicleInfo: _driverCarModel.isNotEmpty ? '$_driverCarModel - $_driverPlateNumber' : 'Toyota Camry - QTR 5821',
          pickupLocation: _bookingPickupLocation.isNotEmpty ? _bookingPickupLocation : 'Current Location',
          destinationLocation: _bookingDestinationLocation.isNotEmpty ? _bookingDestinationLocation : 'Destination',
          rideFare: _calculatedFare > 0 ? _calculatedFare : 25.50,
          rideId: completedRideId,
        ),
      ),
    );
  }

  void _showSetLocationDialog(String locationType, Function(String) onSet) {
    final themeState = context.read<ThemeCubit>().state;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Increase dialog width by reducing horizontal padding
        final horizontalPadding = screenWidth > 600 
            ? screenWidth * 0.15  // 15% padding on tablets (70% width dialog)
            : screenWidth * 0.02; // 2% padding on phones (96% width dialog)
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 40),
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
              vertical: ResponsiveHelper.getResponsiveSpacing(context, 40),
            ),
            decoration: BoxDecoration(
              color: themeState.panelBg,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
              border: Border.all(color: themeState.fieldBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                      topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: ResponsiveHelper.getResponsiveSpacing(context, 60),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 60),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          locationType == 'Home' ? Icons.home : Icons.work,
                          color: Colors.black,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 30),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      Text(
                        'Set $locationType Location',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Content
                Padding(
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  child: Column(
                    children: [
                      Text(
                        'Would you like to set your current location as $locationType?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      
                      // Current location display
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        decoration: BoxDecoration(
                          color: themeState.fieldBg,
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                          border: Border.all(color: themeState.fieldBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location:',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: themeState.textSecondary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                            Text(
                              _pickupAddress,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: themeState.textPrimary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                              decoration: BoxDecoration(
                                color: themeState.panelBg,
                                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                border: Border.all(color: themeState.fieldBorder),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: themeState.textSecondary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Expanded(
                            child: Container(
                              height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.gold, Color(0xFFFFD700)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  if (_pickupAddress.isNotEmpty && _pickupAddress != 'Getting location...' && _pickupAddress != 'Location unavailable') {
                                    onSet(_pickupAddress);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$locationType location set successfully!'),
                                        backgroundColor: AppColors.gold,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Unable to set location. Please try again.'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                  ),
                                ),
                                child: Text(
                                  'Set',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.black,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Get user's current location with address
  Future<void> _getCurrentLocation() async {
    try {
      // Get current location with address using the location service
      Map<String, dynamic>? locationData = await LocationService.getCurrentLocationWithAddress();
      
      if (locationData == null) {
        if (mounted) {
        setState(() {
          _isLocationLoading = false;
            _pickupAddress = 'Location unavailable';
        });
        }
        return;
      }

      geo.Position position = locationData['position'];
      String address = locationData['address'];
      String country = locationData['country'] ?? 'QA';
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _pickupAddress = address;
          _userCountry = country; // Store detected country
          _isLocationLoading = false;
        });
        
        // Update location circles
        _updateLocationCircles();
        
        // Fetch nearby drivers immediately when location is available
        if (!_isPollingNearbyDrivers && !_isConnectingToDriver && !_isDriverFound && !_isDriverArrived && !_isRideStarted) {
          // Wait for car icon to load if not already loaded
          if (_carIcon != null) {
            _startNearbyDriversPolling();
          } else {
            // Icon will trigger polling when loaded
            if (kDebugMode) {
              print('⏳ Waiting for car icon to load before starting driver polling');
            }
          }
        } else if (_isPollingNearbyDrivers) {
          // Trigger immediate fetch if already polling
          _fetchNearbyDrivers();
        }
      }

      // Move camera to user's location once map is available
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 16.5),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
          _pickupAddress = 'Location unavailable';
        });
      }
    }
  }

  // Update location circles with static effect
  void _updateLocationCircles() {
    setState(() {
      _locationCircles = {
        // Outer circle for searchlight effect
        Circle(
          circleId: CircleId('location_outer'),
          center: _currentPosition,
          radius: 50,
          fillColor: Colors.transparent,
          strokeColor: AppColors.gold.withOpacity(0.3),
          strokeWidth: 3,
        ),
        // Inner solid circle
        Circle(
          circleId: CircleId('location_center'),
          center: _currentPosition,
          radius: 15,
          fillColor: AppColors.gold.withOpacity(0.8),
          strokeColor: AppColors.gold,
          strokeWidth: 3,
        ),
      };
    });
  }

  // Start polling ride status every 3 seconds
  void _startRideStatusPolling() {    
    // Don't start polling if we don't have a ride ID
    if (_currentRideId == null) {
      print('⚠️ RIDER - Cannot start polling: No ride ID');
      return;
    }
    
    print('🔄 RIDER - STARTING RIDE STATUS POLLING - Ride ID: $_currentRideId');
    
    // Cancel any existing polling timer
    _rideStatusPollingTimer?.cancel();
    
    // Start periodic polling
    _rideStatusPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      // If we don't have a ride ID or no active ride UI, stop polling
      if (_currentRideId == null || 
          (!_isConnectingToDriver && !_isDriverFound && !_isDriverArrived && !_isRideStarted)) {
        print('⚠️ RIDER - STOPPING POLLING: No ride ID or no active ride UI');
        _stopRideStatusPolling();
        return;
      }
      
      try {
        final response = await ApiService.getRideStatus(rideId: _currentRideId);
        
        print('📡 RIDER - POLLING RIDE STATUS RESPONSE:');
        print('   Success: ${response['success']}');
        print('   Full Response: $response');
        
        if (response['success']) {          
          // Extract status from response
          final data = response['data'];
          
          var status = 'unknown';
          var rideData;
          
          print('📊 RIDER - POLLING RIDE STATUS - Ride ID: $_currentRideId');
          print('   Data type: ${data.runtimeType}');
          print('   Data keys: ${data is Map ? data.keys.toList() : "not a map"}');
          
          // First, check if data directly contains 'status' field
          if (data is Map && data.containsKey('status')) {
            status = data['status'] ?? 'unknown';
            rideData = data;
          }
          // Check if data has 'ride' object (singular)
          else if (data is Map && data.containsKey('ride')) {
            rideData = data['ride'];
            status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
          }
          // Check if data has 'rides' array
          else if (data is Map && data.containsKey('rides')) {
            final rides = data['rides'];            
            
            // Get the first (most recent) ride
            if (rides is List && rides.isNotEmpty) {
              rideData = rides[0];
              status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
              
              // Store ride ID if we don't have one yet (fallback for existing rides)
              if (_currentRideId == null && rideData?['id'] != null) {
                _currentRideId = rideData['id'];
              }
            } else if (rides is List && rides.isEmpty) {
              // CRITICAL FIX: Empty rides array means no active ride
              print('🧹 RIDER - Rides array is empty - treating as no active ride');
              status = 'completed'; // Treat as completed to trigger cleanup
            }
          }
          // Or check if data has nested 'data' object first
          else if (data is Map && data.containsKey('data')) {
            final nestedData = data['data'];            
            
            if (nestedData is Map && nestedData.containsKey('rides')) {
              final rides = nestedData['rides'];              
              
              if (rides is List && rides.isNotEmpty) {
                rideData = rides[0];
                status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
              } else if (rides is List && rides.isEmpty) {
                // CRITICAL FIX: Empty rides array means no active ride
                print('🧹 RIDER - Nested rides array is empty - treating as no active ride');
                status = 'completed'; // Treat as completed to trigger cleanup
              }
            }
            // Check for singular 'ride' object in nested data
            else if (nestedData is Map && nestedData.containsKey('ride')) {
              rideData = nestedData['ride'];
              status = rideData?['status'] ?? rideData?['ride_status'] ?? 'unknown';
              
              // Store ride ID if we don't have one yet
              if (_currentRideId == null && rideData?['id'] != null) {
                _currentRideId = rideData['id'];
            }
          }
          }
          
          // Check for driver acceptance - handle multiple possible status values
          final normalizedStatus = status.toString().trim().toLowerCase();
          print('📊 RIDER - RIDE STATUS: $normalizedStatus - Ride ID: $_currentRideId');
          print('   Ride data: $rideData');
          
          // FIRST: Sync RideCubit with API status (single source of truth)
          context.read<RideCubit>().syncFromApiStatus(normalizedStatus);
          final rideState = context.read<RideCubit>().state;
          print('🔄 RIDER - RideCubit synced. State: ${rideState.status}, apiStatus: ${rideState.apiStatus}');
          
          // CRITICAL: If ride was completed by sync, handle it immediately
          if (rideState.status == RideStatus.rideCompleted || rideState.status == RideStatus.none) {
            print('🏁 RIDER - RIDE ENDED VIA SYNC (status: ${rideState.status})');
            
            // Stop polling
            _stopRideStatusPolling();
            
            if (mounted) {
              // Reset UI state
              setState(() {
                _isConnectingToDriver = false;
                _isDriverFound = false;
                _isDriverArrived = false;
                _isRideStarted = false;
                _bookingPickupLocation = '';
                _bookingDestinationLocation = '';
                _currentRideId = null;
              });
              
              // Show completed screen
              _showRideCompletedScreen();
            }
            return; // Exit polling iteration
          }
          
          final isDriverAssigned = normalizedStatus == 'accepted' || 
                                   normalizedStatus == 'driver_assigned' ||
                                   normalizedStatus == 'confirmed' ||
                                   normalizedStatus == 'in_progress' ||
                                   normalizedStatus == 'driver_found' ||
                                   normalizedStatus == 'assigned';          
          
          print('🔍 RIDER - Checking driver assignment: isDriverAssigned=$isDriverAssigned, _isDriverFound=$_isDriverFound');
          
          if (isDriverAssigned && !_isDriverFound) {
            print('🚗 RIDER - DRIVER ASSIGNED - Ride ID: $_currentRideId');
            print('🔍 RIDER - Checking conditions: _currentRideId=$_currentRideId, _destinationLatLng=$_destinationLatLng, _currentPosition=$_currentPosition');
            
            // Fetch driver info from API (only once)
            // CRITICAL: Check all required values before making API call
            if (_currentRideId != null && 
                _destinationLatLng != null) {
              print('📞 RIDER - CALLING getRideInfo API...');
              print('   Ride ID: $_currentRideId');
              print('   Pickup: (${_currentPosition.latitude}, ${_currentPosition.longitude})');
              print('   Dropoff: (${_destinationLatLng!.latitude}, ${_destinationLatLng!.longitude})');
              
              try {
                final rideInfoResponse = await ApiService.getRideInfo(
                  rideId: _currentRideId!,
                  pickupLat: _currentPosition.latitude,
                  pickupLng: _currentPosition.longitude,
                  pickupAddress: _bookingPickupLocation,
                  dropoffLat: _destinationLatLng!.latitude,
                  dropoffLng: _destinationLatLng!.longitude,
                  dropoffAddress: _bookingDestinationLocation,
                );                
                
                print('📡 RIDER - ride-info API RESPONSE:');
                print('   Success: ${rideInfoResponse['success']}');
                print('   Full Response: $rideInfoResponse');
                
                if (rideInfoResponse['success'] == true && rideInfoResponse['data'] != null) {
                  final outerData = rideInfoResponse['data'];
                  print('📊 RIDER - Response data structure:');
                  print('   Outer data type: ${outerData.runtimeType}');
                  print('   Outer data keys: ${outerData is Map ? outerData.keys.toList() : "not a map"}');
                  
                  // The response is double-nested: data.data.ride
                  // CRITICAL: Check if outerData is a Map before accessing
                  Map<String, dynamic>? nestedData;
                  if (outerData is Map && outerData.containsKey('data')) {
                    final dataValue = outerData['data'];
                    if (dataValue is Map) {
                      nestedData = dataValue as Map<String, dynamic>;
                    }
                  }
                  
                  print('📊 RIDER - Nested data:');
                  print('   Nested data type: ${nestedData?.runtimeType}');
                  print('   Nested data keys: ${nestedData != null ? nestedData.keys.toList() : "not a map"}');
                  
                  // CRITICAL: Safe access to rideData
                  Map<String, dynamic>? rideData;
                  if (nestedData != null && nestedData.containsKey('ride')) {
                    final rideValue = nestedData['ride'];
                    if (rideValue is Map) {
                      rideData = rideValue as Map<String, dynamic>;
                    }
                  }
                  
                  print('📊 RIDER - Ride data:');
                  print('   Ride exists: ${rideData != null}');
                  if (rideData != null) {
                    print('   Ride data keys: ${rideData.keys.toList()}');
                    print('   Full ride data: $rideData');
                  }
                  
                  // CRITICAL: Safe access to driver data
                  Map<String, dynamic>? driver;
                  if (rideData != null && rideData.containsKey('driver')) {
                    final driverValue = rideData['driver'];
                    if (driverValue is Map) {
                      driver = driverValue as Map<String, dynamic>;
                    }
                  }
                  
                  print('👤 RIDER - Driver data:');
                  print('   Driver exists: ${driver != null}');
                  if (driver != null) {
                    print('   Driver data keys: ${driver.keys.toList()}');
                    print('   Full driver data: $driver');
                  }
                  
                  if (driver != null && mounted) {
                    final driverMap = driver; // Create local non-nullable reference
                    setState(() {
                      _driverName = driverMap['name']?.toString() ?? driverMap['full_name']?.toString() ?? 'Driver';
                      final vehicle = driverMap['vehicle'];
                      if (vehicle is Map) {
                        _driverCarModel = vehicle['model']?.toString() ?? driverMap['car_model']?.toString() ?? 'Vehicle';
                        _driverPlateNumber = vehicle['plate_number']?.toString() ?? driverMap['plate_number']?.toString() ?? 'N/A';
                      } else {
                        _driverCarModel = driverMap['car_model']?.toString() ?? 'Vehicle';
                        _driverPlateNumber = driverMap['plate_number']?.toString() ?? 'N/A';
                      }
                      final ratingValue = driverMap['rating'];
                      _driverRating = ratingValue is num ? ratingValue.toDouble() : (ratingValue is String ? double.tryParse(ratingValue) ?? 0.0 : 0.0);
                      _driverPhotoUrl = driverMap['avatar_url']?.toString() ?? driverMap['photo_url']?.toString() ?? driverMap['profile_picture']?.toString();
                    });
                    
                    // Update ETA and driver location from ride data (safe call)
                    if (rideData != null) {
                      try {
                        _updateETAFromRideInfo(rideData);
                      } catch (e) {
                        print('⚠️ RIDER - Error updating ETA from ride info: $e');
                      }
                    }
                    
                    print('✅ DRIVER INFO SET:');
                    print('   Name: $_driverName');
                    print('   Car: $_driverCarModel - $_driverPlateNumber');
                    print('   Rating: $_driverRating');
                    print('   Photo: $_driverPhotoUrl');
                  } else {
                    print('❌ RIDER - NO DRIVER DATA IN RESPONSE or widget not mounted');
                    if (driver == null) {
                      print('   Driver is null');
                    }
                    if (!mounted) {
                      print('   Widget is not mounted');
                    }
                  }
              } else {
                print('❌ RIDER - ride-info API failed or returned no data');
                print('   Success: ${rideInfoResponse['success']}');
                print('   Error: ${rideInfoResponse['error']}');
                print('   Full Response: $rideInfoResponse');
              }
              } catch (e, stackTrace) {
                print('❌ RIDER - ERROR FETCHING DRIVER INFO: $e');
                print('   Stack trace: $stackTrace');
                // Don't crash - just log the error and continue polling
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error fetching driver info: ${e.toString()}'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            } else {
              print('❌ RIDER - Cannot fetch driver info: Missing required data');
              print('   _currentRideId: $_currentRideId');
              print('   _destinationLatLng: $_destinationLatLng');
              print('   _currentPosition: $_currentPosition');
              // Don't crash - just log and continue
            }
            
            // Use duration from Google Maps API (stored when route was drawn)
            String etaText = '2-5 min'; // Default fallback
            if (_routeDurationMinutes != null && _routeDurationMinutes! > 0) {
              etaText = '$_routeDurationMinutes min';
            }            
            
            // CRITICAL: Check mounted before updating state
            if (mounted) {
              setState(() {
                _isConnectingToDriver = false;
                _isDriverFound = true;
                _driverETA = etaText;
              });

              // Start polling assigned driver's online status when driver is found
              _startDriverOnlineStatusPolling();
              
              // Update RideCubit with driver found status
              try {
                context.read<RideCubit>().driverFound(
                  driverName: _driverName,
                  driverCar: '$_driverCarModel - $_driverPlateNumber',
                  driverRating: _driverRating.toString(),
                  estimatedArrival: etaText,
                  driverLocation: _currentPosition,
                );
              } catch (e) {
                print('⚠️ RIDER - Error updating RideCubit: $e');
              }
              
              // Update fare if available
              if (_calculatedFare > 0) {
                try {
                  context.read<RideCubit>().updateFare(_calculatedFare.toString());
                } catch (e) {
                  print('⚠️ RIDER - Error updating fare: $e');
                }
              }              
              
              // Show success message
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Driver found! Preparing ride details...'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                print('⚠️ RIDER - Error showing snackbar: $e');
              }
              
              // Start polling for real-time ETA updates
              try {
                _startETAPolling();
              } catch (e) {
                print('⚠️ RIDER - Error starting ETA polling: $e');
              }
            } else {
              print('⚠️ RIDER - Cannot update driver found state: mounted=$mounted, _currentPosition=$_currentPosition');
            }
            // Continue polling - don't stop!
          } else if (normalizedStatus == 'arrived' || normalizedStatus == 'driver_arrived') {
            print('🚗 RIDER - DRIVER ARRIVED - Ride ID: $_currentRideId');
            
            // Extract driver info if not already set
            if (_driverName.isEmpty && rideData != null) {
              final driver = rideData['driver'];
              if (driver != null && mounted) {
                setState(() {
                  _driverName = driver['name'] ?? driver['full_name'] ?? 'Driver';
                  _driverCarModel = driver['vehicle']?['model'] ?? driver['car_model'] ?? 'Vehicle';
                  _driverPlateNumber = driver['vehicle']?['plate_number'] ?? driver['plate_number'] ?? 'N/A';
                  _driverRating = (driver['rating'] ?? 0).toDouble();
                  _driverPhotoUrl = driver['avatar_url'] ?? driver['photo_url'] ?? driver['profile_picture'];
                });
                print('✅ DRIVER INFO SET ON ARRIVED');
              }
            }
            
            if (!_isDriverArrived && mounted) {
              setState(() {
                _isConnectingToDriver = false;
                _isDriverFound = false;
                _isDriverArrived = true;
              });
              
              // Stop ETA polling since driver has arrived
              _stopETAPolling();
              
              // Update RideCubit
              context.read<RideCubit>().driverArrived();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Driver has arrived!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            // Continue polling
          } else if (normalizedStatus == 'started' || normalizedStatus == 'ongoing') {
            print('🚗 RIDER - RIDE STARTED - Ride ID: $_currentRideId');
            
            // Extract driver info if not already set
            if (_driverName.isEmpty && rideData != null) {
              final driver = rideData['driver'];
              if (driver != null && mounted) {
                setState(() {
                  _driverName = driver['name'] ?? driver['full_name'] ?? 'Driver';
                  _driverCarModel = driver['vehicle']?['model'] ?? driver['car_model'] ?? 'Vehicle';
                  _driverPlateNumber = driver['vehicle']?['plate_number'] ?? driver['plate_number'] ?? 'N/A';
                  _driverRating = (driver['rating'] ?? 0).toDouble();
                  _driverPhotoUrl = driver['avatar_url'] ?? driver['photo_url'] ?? driver['profile_picture'];
                });
                print('✅ DRIVER INFO SET ON RIDE STARTED');
              }
            }
            
            if (!_isRideStarted && mounted) {
              setState(() {
                _isConnectingToDriver = false;
                _isDriverFound = false;
                _isDriverArrived = false;
                _isRideStarted = true;
              });
              
              // Stop ETA polling since ride has started
              _stopETAPolling();
              
              // Update RideCubit
              context.read<RideCubit>().rideStarted();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ride has started! Enjoy your trip!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            // Continue polling
          } else if (normalizedStatus == 'completed' || 
                     normalizedStatus == 'finished' ||
                     normalizedStatus == 'trip_completed' ||
                     normalizedStatus == 'ride_completed' ||
                     normalizedStatus == 'ended' ||
                     normalizedStatus == 'done') {
            print('🔍 RIDER - Checking if status matches completion: normalizedStatus=$normalizedStatus');
            print('🏁 RIDER - RIDE COMPLETED (status: $normalizedStatus) - Ride ID: $_currentRideId');
            
            // FIRST: Clear RideCubit immediately to prevent re-saving to storage
            context.read<RideCubit>().rideCompleted();
            
            // SECOND: Stop polling
            _stopRideStatusPolling();
            _stopETAPolling();
            
            if (mounted) {
              // Reset UI state
              setState(() {
                _isConnectingToDriver = false;
                _isDriverFound = false;
                _isDriverArrived = false;
                _isRideStarted = false;
                _bookingPickupLocation = '';
                _bookingDestinationLocation = '';
                _currentRideId = null;
              });
              
              // Show completed screen
              _showRideCompletedScreen();
            }
          } else if (status == 'pending') {
            // Continue polling
          } else if (status == 'cancelled' || status == 'driver_cancelled') {
            print('🚫 RIDER - RIDE CANCELLED BY DRIVER - Ride ID: $_currentRideId');
            
            // FIRST: Clear RideCubit immediately
              context.read<RideCubit>().cancelRide();
            
            // SECOND: Stop polling
            _rideStatusPollingTimer?.cancel();
            _rideStatusPollingTimer = null;
            _stopETAPolling();
            
            if (mounted) {
              setState(() {
                _isConnectingToDriver = false;
                _isDriverFound = false;
                _isDriverArrived = false;
                _isRideStarted = false;
                _bookingPickupLocation = '';
                _bookingDestinationLocation = '';
                _currentRideId = null;
              });
              
              // Stop all animations and services
              _rippleController1.stop();
              _rippleController2.stop();
              _rippleController3.stop();
              _rippleController1.reset();
              _rippleController2.reset();
              _rippleController3.reset();
              _rideSimulation.cancelRide();
              _locationSimulation.stopSimulation();
              _chatSimulation.stopPeriodicUpdates();
              
              // Show message to rider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Driver cancelled the ride. Please book again.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } else {
          // Don't stop polling on error, continue trying
          print('⚠️ RIDER - POLLING: API returned success=false');
        }
      } catch (e, stackTrace) {
        print('❌ RIDER - POLLING ERROR: $e');
        print('   Stack trace: $stackTrace');
        // Don't crash - just log and continue polling
        // The error might be transient (network, parsing, etc.)
        if (mounted && kDebugMode) {
          // Only show error in debug mode to avoid annoying users
          print('   Continuing polling despite error...');
        }
      }
    });
  }

  // Stop polling ride status
  void _stopRideStatusPolling() {
    _rideStatusPollingTimer?.cancel();
    _rideStatusPollingTimer = null;
  }

  // Start polling ride-info for real-time ETA updates
  void _startETAPolling() {
    // Don't start if no ride ID or destination
    if (_currentRideId == null || _destinationLatLng == null) {
      print('⚠️ RIDER - Cannot start ETA polling: No ride ID or destination');
      return;
    }
    
    print('✅ RIDER - Starting ETA polling (every 5 seconds)');
    
    // Poll immediately first
    _pollRideInfoForETA();
    
    // Then poll every 5 seconds
    _etaPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentRideId == null || !_isDriverFound) {
        print('⚠️ RIDER - Stopping ETA polling: No ride or driver not found');
        _stopETAPolling();
        return;
      }
      _pollRideInfoForETA();
    });
  }

  // Stop ETA polling
  void _stopETAPolling() {
    print('🛑 RIDER - Stopping ETA polling');
    _etaPollingTimer?.cancel();
    _etaPollingTimer = null;
  }

  // Poll ride-info API for ETA updates
  Future<void> _pollRideInfoForETA() async {
    if (_currentRideId == null || _destinationLatLng == null) return;
    
    try {
      final rideInfoResponse = await ApiService.getRideInfo(
        rideId: _currentRideId!,
        pickupLat: _currentPosition.latitude,
        pickupLng: _currentPosition.longitude,
        pickupAddress: _bookingPickupLocation,
        dropoffLat: _destinationLatLng!.latitude,
        dropoffLng: _destinationLatLng!.longitude,
        dropoffAddress: _bookingDestinationLocation,
      );
      
      if (rideInfoResponse['success'] == true && rideInfoResponse['data'] != null) {
        final outerData = rideInfoResponse['data'];
        final nestedData = outerData['data'];
        final rideData = nestedData?['ride'];
        
        if (rideData != null && mounted) {
          setState(() {
            // Update ETA and driver location
            _updateETAFromRideInfo(rideData);
          });
        }
      }
    } catch (e) {
      print('❌ RIDER - Error polling ride-info for ETA: $e');
    }
  }

  // Draw route on map from pickup to destination
  Future<void> _drawRouteOnMap() async {    
    // Clear old route and markers
    setState(() {
      _routeDurationText = '';
      _routePolylines.clear();
      _routeMarkers.clear();
    });
    
    try {
      // Get directions from Google Directions API
      final directionsData = await PlacesService.getDirections(
        originLat: _currentPosition.latitude,
        originLng: _currentPosition.longitude,
        destLat: _destinationLatLng!.latitude,
        destLng: _destinationLatLng!.longitude,
      );
      
      if (directionsData != null && directionsData['success']) {        
        // Extract duration
        final durationInMinutes = directionsData['durationInMinutes'];
        final durationText = '$durationInMinutes mins';        
        
        // Extract polyline points
        final polylinePoints = PlacesService.decodePolyline(
          directionsData['polylinePoints'] as String
        );
        
        setState(() {
          // Store duration text and minutes
          _routeDurationText = durationText;
          _routeDurationMinutes = durationInMinutes as int?;
          
          // Set driver ETA for connecting screen
          _driverETA = '$durationInMinutes min';
          
          // Draw polyline using Google Maps
          _routePolylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: polylinePoints,
            color: AppColors.gold,
            width: 4,
          ));
        });        
        
        // Auto-zoom to show entire route
        if (polylinePoints.isNotEmpty) {
          _fitMapToRoute(polylinePoints);
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  // Fetch ride prices from API
  Future<void> _fetchRidePrices() async {
    if (_destinationLatLng == null) return;
    
    print('🚗 FETCHING RIDE PRICES:');
    print('   Pickup: ${_currentPosition.latitude}, ${_currentPosition.longitude}');
    print('   Destination: ${_destinationLatLng!.latitude}, ${_destinationLatLng!.longitude}');
    
    setState(() {
      _isFetchingPrices = true;
    });
    
    try {
      final url = 'https://bvazoowmmiymbbhxoggo.supabase.co/functions/v1/ride-types?pickup_lat=${_currentPosition.latitude}&pickup_lng=${_currentPosition.longitude}&dropoff_lat=${_destinationLatLng!.latitude}&dropoff_lng=${_destinationLatLng!.longitude}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final rideTypes = data['data']['ride_types'] as List;
        
        // Extract prices for each ride type
        for (var rideType in rideTypes) {
          final rideId = rideType['id'] as String;
          final carOptions = rideType['car_options'] as List;
          
          double? price;
          if (rideId == 'q-standard' || rideId == 'q-comfort') {
            // Find sedan price
            for (var option in carOptions) {
              if (option['car_type'] == 'sedan') {
                price = (option['estimated_fare'] as num).toDouble();
                break;
              }
            }
          } else if (rideId == 'q-xl') {
            // Find luxury price
            for (var option in carOptions) {
              if (option['car_type'] == 'luxury') {
                price = (option['estimated_fare'] as num).toDouble();
                break;
              }
            }
          }
          
          // Map API ride IDs to UI ride types
          String uiRideType;
          switch (rideId) {
            case 'q-standard':
              uiRideType = 'Q-Standard';
              break;
            case 'q-comfort':
              uiRideType = 'Q-Comfort';
              break;
            case 'q-xl':
              uiRideType = 'Q-XL';
              break;
            default:
              continue;
          }
          
          _ridePrices[uiRideType] = price;
        }
        }
      }
    } catch (e) {
      print('❌ Error fetching ride prices: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingPrices = false;
        });
      }
    }
  }

  // Fit map bounds to show entire route
  void _fitMapToRoute(List<LatLng> polylineCoordinates) {
    if (_mapController == null || polylineCoordinates.isEmpty) return;    
    
    // Calculate bounds
    double minLat = polylineCoordinates[0].latitude;
    double maxLat = polylineCoordinates[0].latitude;
    double minLng = polylineCoordinates[0].longitude;
    double maxLng = polylineCoordinates[0].longitude;
    
    for (var point in polylineCoordinates) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    // Fit bounds with padding for Google Maps
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _destinationController.dispose();
    _destinationFocusNode.dispose();
    _cancelNotesController.dispose();
    _rippleController1.dispose();
    _rippleController2.dispose();
    _rippleController3.dispose();
    _rideCompletionTimer?.cancel();
    _driverArrivedTimer?.cancel();
    _rideStatusPollingTimer?.cancel();
    _driverOnlineStatusPollingTimer?.cancel();
    _etaPollingTimer?.cancel();
    _nearbyDriversPollingTimer?.cancel();
    
    // Cancel all driver animations
    for (final timer in _driverAnimations.values) {
      timer.cancel();
    }
    _driverAnimations.clear();
    
    // Dispose simulation services
    _rideSimulation.dispose();
    _locationSimulation.dispose();
    _chatSimulation.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          body: Stack(
            children: [
              // Full Screen Map Background
              _buildMapBackground(themeState),
              // Top Bar with Profile and Notifications
              _buildTopBar(themeState),
              // Bottom Panel
              _buildBottomPanel(themeState),
            ],
          ),
        );
      },
    );
  }

  String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#212121"
        }
      ]
    },
    {
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#212121"
        }
      ]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "administrative.country",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#9e9e9e"
        }
      ]
    },
    {
      "featureType": "administrative.land_parcel",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#bdbdbd"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#181818"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#616161"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#1b1b1b"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [
        {
          "color": "#2c2c2c"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#8a8a8a"
        }
      ]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#373737"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#3c3c3c"
        }
      ]
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#4e4e4e"
        }
      ]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#616161"
        }
      ]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#000000"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#3d3d3d"
        }
      ]
    }
  ]
  ''';

  Widget _buildMapBackground(ThemeState themeState) {
    return Stack(
      children: [
        GoogleMap(
          key: const ValueKey("googleMap"),
          initialCameraPosition: CameraPosition(
            target: _currentPosition,
            zoom: _isLocationLoading ? 11.0 : 16.0, // Show Qatar overview while loading, zoom in when location is ready
          ),
          onMapCreated: (GoogleMapController controller) async {
            _mapController = controller;
            // Center immediately if location is ready
            if (!_isLocationLoading) {
              await controller.animateCamera(
                CameraUpdate.newLatLngZoom(_currentPosition, 16.0),
              );
            }
          },
          markers: {..._routeMarkers, ..._getDriverMarkers()},
          polylines: _routePolylines,
          circles: _locationCircles,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          style: themeState.isDarkTheme ? _darkMapStyle : null,
        ),
        
        // Duration Text Overlay (when route is visible)
        if (_routeDurationText.isNotEmpty && !_isConnectingToDriver)
          Positioned(
            top: ResponsiveHelper.getResponsiveSpacing(context, 100),
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.black,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Text(
                      _routeDurationText,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ),
        
        // Connecting to Driver Animation Overlay
        if (_isConnectingToDriver)
          Positioned(
            top: ResponsiveHelper.getResponsiveSpacing(context, 100),
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Connecting status text
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isDeliveryOrder ? 'Connecting you to a courier' : 'Connecting to Driver',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: themeState.panelBg,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      Text(
                        'ETA: $_driverETA',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
        // Location loading indicator
        if (_isLocationLoading)
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeState.panelBg,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 16),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Text(
                      'Getting location...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
        
        // My Location button - dynamically positioned based on panel state
        Positioned(
          bottom: _getLocationButtonBottomOffset(),
          right: ResponsiveHelper.getResponsiveSpacing(context, 20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _animateToCurrentLocation,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 28)),
              child: Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 56),
                height: ResponsiveHelper.getResponsiveSpacing(context, 56),
                decoration: BoxDecoration(
                  color: themeState.panelBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.my_location,
                  color: AppColors.gold,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Get bottom offset for location button based on panel state
  double _getLocationButtonBottomOffset() {
    // If booking panel or ride panels are showing, position above them
    if (_showBookingPanel || _isRideStarted || _isDriverArrived || _isDriverFound || _isConnectingToDriver) {
      // These panels are typically taller, position button higher
      return ResponsiveHelper.getResponsiveSpacing(context, 280);
    }
    
    // For default draggable panel (collapsed or expanded)
    // Position it above the max expanded state (48% of screen) plus padding
    // This ensures it's always visible whether panel is collapsed or expanded
    final screenHeight = MediaQuery.of(context).size.height;
    final maxPanelHeight = screenHeight * 0.48; // 48% of screen (maxChildSize)
    final padding = ResponsiveHelper.getResponsiveSpacing(context, 80);
    
    return maxPanelHeight + padding;
  }

  // Animate camera to current location
  Future<void> _animateToCurrentLocation() async {
    if (_mapController == null || _isLocationLoading) {
      return;
    }

    try {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 16.0),
      );
      
      if (kDebugMode) {
        print('📍 Animated to current location: ${_currentPosition.latitude}, ${_currentPosition.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error animating to current location: $e');
      }
    }
  }

  Widget _buildTopBar(ThemeState themeState) {
    return SafeArea(
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Profile Picture
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
              height: ResponsiveHelper.getResponsiveSpacing(context, 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                color: themeState.fieldBg,
              ),
              child: ClipOval(
                child: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                    ? Image.network(
                        _profilePhotoUrl!,
                        fit: BoxFit.cover,
                        width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/user.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        'assets/images/user.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Ride status indicator
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
              ),
              decoration: BoxDecoration(
                color: _isRideStarted ? Colors.green.withOpacity(0.1) : themeState.panelBg,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                border: Border.all(
                  color: _isRideStarted ? Colors.green : themeState.fieldBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isRideStarted) ...[
                    Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 6),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                  ],
                  Text(
                    _isRideStarted ? 'Ride in Progress' : 'No active rides',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _isRideStarted ? Colors.green : themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  fontWeight: FontWeight.w500,
                ),
                  ),
                ],
              ),
            ),
            // Notifications
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                    decoration: BoxDecoration(
                      color: themeState.panelBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: themeState.textPrimary,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(ThemeState themeState) {
    print('🎨 RIDER UI - PANEL STATE: booking=$_showBookingPanel, started=$_isRideStarted, arrived=$_isDriverArrived, found=$_isDriverFound, connecting=$_isConnectingToDriver');
    
    // Show booking panel if booking is active
    if (_showBookingPanel) {
      print('🎨 RIDER UI - RENDERING: Booking Panel');
      return _buildBookingPanel(themeState);
    }
    
    // Show ride started UI if ride has started
    if (_isRideStarted) {
      print('🎨 RIDER UI - RENDERING: Ride Started Panel');
      return _buildRideStartedPanel(themeState);
    }
    
    // Show driver arrived UI if driver has arrived
    if (_isDriverArrived) {
      print('🎨 RIDER UI - RENDERING: Driver Arrived Panel');
      return _buildDriverArrivedPanel(themeState);
    }
    
    // Show driver found UI if driver is found
    if (_isDriverFound) {
      print('🎨 RIDER UI - RENDERING: Driver Found Panel');
      return _buildDriverFoundPanel(themeState);
    }
    
    // Show connecting to driver UI if booking is active
    if (_isConnectingToDriver) {
      print('🎨 RIDER UI - RENDERING: Connecting to Driver Panel');
      return _buildConnectingToDriverPanel(themeState);
    }
    
    print('🎨 RIDER UI - RENDERING: Default Home Panel');
    return DraggableScrollableSheet(
      initialChildSize: 0.45, // Start at 45% of screen height
      minChildSize: 0.1, // Minimum 10% - just enough for "Where to, Sara?" text
      maxChildSize: 0.48, // Maximum 48% of screen height
      builder: (context, scrollController) {
        return Container(
        decoration: BoxDecoration(
            color: themeState.panelBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
            topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
          ),
        ),
        child: Column(
          children: [
            // Handle Bar
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
              height: ResponsiveHelper.getResponsiveSpacing(context, 4),
              margin: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              decoration: BoxDecoration(
                color: themeState.textSecondary,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
              ),
            ),
            // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ride Status (only show if ride is in progress)
                  if (_isRideStarted)
                    Row(
                      children: [
                        Container(
                          width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                          height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Text(
                          'Ride in Progress',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  if (_isRideStarted)
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  // Service Selection Pills (Ride, Delivery, Rental) - at the top
                  Row(
                    children: [
                      Expanded(
                        child: _servicePillButton('ride', Icons.directions_car, 'Ride', themeState),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      Expanded(
                        child: _servicePillButton('parcel', Icons.inventory_2, 'Delivery', themeState),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      Expanded(
                        child: _servicePillButton('rental', Icons.vpn_key, 'Rental', themeState),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  // Destination Input with Autocomplete
                  PlacesService.buildAutocompleteTextField(
                    onPlaceSelected: (prediction) {
                      _onDestinationSelected(prediction);
                    },
                    hintText: 'Where to?',
                    themeState: themeState,
                    context: context,
                    controller: _destinationController,
                    countryCode: _userCountry, // Pass detected country
                    focusNode: _destinationFocusNode,
                    onSubmitted: () {
                      // Dismiss keyboard when "done" is pressed
                      _destinationFocusNode.unfocus();
                    },
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  // Saved Destinations List - Always show Home and Work
                  _savedDestinationItem(
                    label: 'Home',
                    icon: Icons.star,
                    address: _homeAddress ?? 'Set your home address',
                    onTap: () {
                      if (_homeAddress != null) {
                        setState(() {
                          _selectedDestination = _homeAddress!;
                          _destinationController.text = _homeAddress!;
                        });
                      } else {
                        _showSetLocationDialog('Home', (address) {
                          setState(() {
                            _homeAddress = address;
                          });
                        });
                      }
                    },
                    themeState: themeState,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  
                  _savedDestinationItem(
                    label: 'Work',
                    icon: Icons.work,
                    address: _workAddress ?? 'Set your work address',
                    onTap: () {
                      if (_workAddress != null) {
                        setState(() {
                          _selectedDestination = _workAddress!;
                          _destinationController.text = _workAddress!;
                        });
                      } else {
                        _showSetLocationDialog('Work', (address) {
                          setState(() {
                            _workAddress = address;
                          });
                        });
                      }
                    },
                    themeState: themeState,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  // Set Destination Button
                  GestureDetector(
                    onTap: () {
                      // For ride service, show booking panel
                      setState(() {
                        _showBookingPanel = true;
                        _bookingPickupLocation = _pickupAddress;
                        _bookingDestinationLocation = _selectedDestination.isNotEmpty ? _selectedDestination : 'Where to?';
                      });
                      
                      // Fetch ride prices if destination is set
                      if (_destinationLatLng != null) {
                        _fetchRidePrices();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                      ),
                      child: Center(
                        child: Text(
                          'Set Destination',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.black,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                      ],
                    ),
                  ),
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _quickLocationButton(String label, IconData icon, int index, ThemeState themeState) {
    // Check if location is set
    bool isLocationSet = false;
    if (index == 0) isLocationSet = _homeAddress != null;
    if (index == 1) isLocationSet = _workAddress != null;
    
    return InkWell(
      onTap: () {
        _handleQuickLocationTap(label, index);
      },
      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
      child: Container(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 12)),
        decoration: BoxDecoration(
          color: isLocationSet ? AppColors.gold.withOpacity(0.1) : themeState.fieldBg,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          border: isLocationSet ? Border.all(color: AppColors.gold, width: 1) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isLocationSet ? AppColors.gold : themeState.textPrimary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
            Flexible(
              child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLocationSet ? AppColors.gold : themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  fontWeight: isLocationSet ? FontWeight.w700 : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicePillButton(String service, IconData icon, String label, ThemeState themeState) {
    final isSelected = _selectedService == service;
    
    return InkWell(
      onTap: () async {
        setState(() {
          _selectedService = service;
        });
        
        // If delivery is selected, navigate to delivery order screen
        if (service == 'parcel') {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const DeliveryOrderScreen(),
            ),
          );
          
          // If delivery order was confirmed, show connecting to driver panel
          if (result != null && result['success'] == true && mounted) {
            setState(() {
              _isConnectingToDriver = true;
              _isDeliveryOrder = true; // Mark as delivery order
              _bookingPickupLocation = result['pickupAddress'] ?? '';
              _bookingDestinationLocation = result['dropoffAddress'] ?? '';
            });
            
            // Start ripple animations
            _rippleController1.repeat();
            _rippleController2.repeat();
            _rippleController3.repeat();
            
            // TODO: Start polling for delivery driver status
            // _startDeliveryStatusPolling();
          }
        } else if (service == 'rental') {
          // Navigate to rental screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RentalScreen(),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 4)),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : themeState.fieldBg,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : themeState.textPrimary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 18),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 6)),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.black : themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _serviceButton(String service, IconData icon, String label, ThemeState themeState) {
    final isSelected = _selectedService == service;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedService = service;
        });
      },
      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? themeState.fieldBg : themeState.fieldBg,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          border: isSelected ? Border.all(color: AppColors.gold, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon container with background
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 48),
              height: ResponsiveHelper.getResponsiveSpacing(context, 48),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold : Colors.transparent,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : themeState.textPrimary,
                size: ResponsiveHelper.getResponsiveIconSize(context, 24),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
            // Label
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.gold : themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedDestinationItem({
    required String label,
    required IconData icon,
    required String address,
    required VoidCallback onTap,
    required ThemeState themeState,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
      child: Container(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
        child: Row(
          children: [
            // Icon container with gold background
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
              height: ResponsiveHelper.getResponsiveSpacing(context, 40),
              decoration: BoxDecoration(
                color: themeState.fieldBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.gold,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            // Label and address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  Text(
                    address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Chevron icon
            Icon(
              Icons.chevron_right,
              color: themeState.textSecondary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverFoundPanel(ThemeState themeState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360;
    
    return DraggableScrollableSheet(
      initialChildSize: isTablet ? 0.35 : 0.4,
      minChildSize: isTablet ? 0.25 : 0.3,
      maxChildSize: isTablet ? 0.5 : 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
              topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 4),
                      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                      decoration: BoxDecoration(
                        color: themeState.textSecondary,
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
                      ),
                    ),
                  ),
                  
                  // Estimated Arrival Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Arrival',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: themeState.textSecondary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                      Text(
                        _estimatedArrivalTime != null 
                          ? _formatEstimatedArrivalTime(_estimatedArrivalTime.toString())
                          : '--:--',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                      Text(
                        _minutesUntilArrival != null && _minutesUntilArrival! > 0
                          ? 'Estimated arrival time $_minutesUntilArrival ${_minutesUntilArrival == 1 ? "minute" : "minutes"}'
                          : 'Estimated arrival time $_driverETA',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.gold,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  
                  // Trip Progress Bar
                  Column(
                    children: [
                      // Progress Bar with Location Dots
                      Container(
                        height: ResponsiveHelper.getResponsiveSpacing(context, 10),
                        child: Stack(
                          children: [
                            // Background Line
                            Container(
                              height: ResponsiveHelper.getResponsiveSpacing(context, 4),
                              margin: EdgeInsets.only(
                                top: ResponsiveHelper.getResponsiveSpacing(context, 3),
                                left: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                right: ResponsiveHelper.getResponsiveSpacing(context, 8),
                              ),
                              decoration: BoxDecoration(
                                color: themeState.fieldBorder,
                                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
                              ),
                            ),
                            // Progress Fill
                            Container(
                              height: ResponsiveHelper.getResponsiveSpacing(context, 4),
                              margin: EdgeInsets.only(
                                top: ResponsiveHelper.getResponsiveSpacing(context, 3),
                                left: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                right: ResponsiveHelper.getResponsiveSpacing(context, 8),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.75, // 75% progress
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
                                  ),
                                ),
                              ),
                            ),
                            // Start Location Dot (The Pearl Qatar)
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: themeState.panelBg,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            // End Location Dot (Hamad Airport)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                decoration: BoxDecoration(
                                  color: themeState.fieldBorder,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: themeState.panelBg,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      
                      // Locations
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Driver Location',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: themeState.textSecondary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                          Expanded(
                              child: Text(
                                _pickupAddress.isNotEmpty ? _pickupAddress : 'Your Location',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: themeState.textSecondary,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                ),
                                textAlign: TextAlign.right,
                              ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Driver Information Section
                  Row(
                    children: [
                      // Driver Profile Picture with Rating Badge
                      Stack(
                        children: [
                          Container(
                            width: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 80) : ResponsiveHelper.getResponsiveSpacing(context, 70),
                            height: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 80) : ResponsiveHelper.getResponsiveSpacing(context, 70),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeState.fieldBg,
                              border: Border.all(color: AppColors.gold, width: 2),
                            ),
                            child: ClipOval(
                              child: _driverPhotoUrl != null && _driverPhotoUrl!.isNotEmpty
                                  ? Image.network(
                                      _driverPhotoUrl!,
                                      fit: BoxFit.cover,
                                      width: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 80) : ResponsiveHelper.getResponsiveSpacing(context, 70),
                                      height: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 80) : ResponsiveHelper.getResponsiveSpacing(context, 70),
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person,
                                          color: themeState.textSecondary,
                                          size: isTablet ? ResponsiveHelper.getResponsiveIconSize(context, 40) : ResponsiveHelper.getResponsiveIconSize(context, 35),
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.person,
                                      color: themeState.textSecondary,
                                      size: isTablet ? ResponsiveHelper.getResponsiveIconSize(context, 40) : ResponsiveHelper.getResponsiveIconSize(context, 35),
                                    ),
                            ),
                          ),
                          // Rating Badge
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 6),
                                vertical: ResponsiveHelper.getResponsiveSpacing(context, 2),
                              ),
                              decoration: BoxDecoration(
                                color: themeState.fieldBg,
                                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                border: Border.all(color: themeState.fieldBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: AppColors.gold,
                                    size: ResponsiveHelper.getResponsiveIconSize(context, 12),
                                  ),
                                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                                  Text(
                                    _driverRating > 0 ? _driverRating.toStringAsFixed(1) : '0.0',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: themeState.textPrimary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      
                      // Driver Details
                      Expanded(
                        flex: isTablet ? 3 : 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _driverName.isNotEmpty ? _driverName : 'Driver',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: themeState.textPrimary,
                                fontSize: isTablet ? ResponsiveHelper.getResponsiveFontSize(context, 16) : 
                                        isSmallScreen ? ResponsiveHelper.getResponsiveFontSize(context, 11) : 
                                        ResponsiveHelper.getResponsiveFontSize(context, 12),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                            Text(
                              _driverCarModel.isNotEmpty ? _driverCarModel : 'Vehicle',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: themeState.textSecondary,
                                fontSize: isTablet ? ResponsiveHelper.getResponsiveFontSize(context, 14) : 
                                        isSmallScreen ? ResponsiveHelper.getResponsiveFontSize(context, 9) : 
                                        ResponsiveHelper.getResponsiveFontSize(context, 10),
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 6)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                vertical: ResponsiveHelper.getResponsiveSpacing(context, 2),
                              ),
                              decoration: BoxDecoration(
                                color: themeState.isDarkTheme ? Colors.blue.withOpacity(0.1) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 6)),
                                border: Border.all(color: themeState.isDarkTheme ? Colors.blue.withOpacity(0.3) : Colors.grey.shade300),
                              ),
                              child: Text(
                                _driverPlateNumber.isNotEmpty ? _driverPlateNumber : 'N/A',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: themeState.textPrimary,
                                  fontSize: isTablet ? ResponsiveHelper.getResponsiveFontSize(context, 14) : 
                                          isSmallScreen ? ResponsiveHelper.getResponsiveFontSize(context, 9) : 
                                          ResponsiveHelper.getResponsiveFontSize(context, 10),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Communication Buttons
                      Row(
                        children: [
                          Container(
                            width: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 56) : ResponsiveHelper.getResponsiveSpacing(context, 48),
                            height: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 56) : ResponsiveHelper.getResponsiveSpacing(context, 48),
                            decoration: BoxDecoration(
                              color: themeState.fieldBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: themeState.fieldBorder),
                            ),
                            child: IconButton(
                              onPressed: () {
                                if (_currentRideId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No active ride')),
                                  );
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      driverName: _driverName.isNotEmpty ? _driverName : 'Driver',
                                      driverAvatar: 'assets/avatars/driver.png',
                                      rideId: _currentRideId!,
                                    ),
                                  ),
                                );
                              },
                              icon: Image.asset(
                                'assets/icons/message.png',
                                width: isTablet ? ResponsiveHelper.getResponsiveIconSize(context, 24) : ResponsiveHelper.getResponsiveIconSize(context, 20),
                                height: isTablet ? ResponsiveHelper.getResponsiveIconSize(context, 24) : ResponsiveHelper.getResponsiveIconSize(context, 20),
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Container(
                            width: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 56) : ResponsiveHelper.getResponsiveSpacing(context, 48),
                            height: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 56) : ResponsiveHelper.getResponsiveSpacing(context, 48),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                // Handle call
                              },
                              icon: Icon(
                                Icons.phone,
                                color: Colors.black,
                                size: isTablet ? ResponsiveHelper.getResponsiveIconSize(context, 24) : ResponsiveHelper.getResponsiveIconSize(context, 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        iconAsset: 'assets/icons/share.png',
                        label: 'Share Trip',
                        onTap: () {},
                        themeState: themeState,
                      ),
                      _buildActionButton(
                        iconAsset: 'assets/icons/change_drop.png',
                        label: 'Change Drop',
                        onTap: () {},
                        themeState: themeState,
                      ),
                      _buildActionButton(
                        iconAsset: 'assets/icons/cancel.png',
                        label: 'Cancel Ride',
                        onTap: _showCancelRideDialog,
                        themeState: themeState,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverArrivedPanel(ThemeState themeState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return DraggableScrollableSheet(
      initialChildSize: isTablet ? 0.35 : 0.4,
      minChildSize: isTablet ? 0.25 : 0.3,
      maxChildSize: isTablet ? 0.5 : 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
              topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 4),
                      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                      decoration: BoxDecoration(
                        color: themeState.textSecondary,
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
                      ),
                    ),
                  ),
                  
                  // Driver Arrived Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver Has Arrived!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: themeState.textSecondary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                      Text(
                        '${_driverName.isNotEmpty ? _driverName : 'Your driver'} is waiting for you',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  
                  // Driver Details Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                    decoration: BoxDecoration(
                      color: themeState.fieldBg,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                      border: Border.all(color: themeState.fieldBorder),
                    ),
                    child: Column(
                      children: [
                        // Driver Profile
                        Row(
                          children: [
                            // Driver Avatar
                            Container(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 50),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 50),
                              decoration: BoxDecoration(
                                color: themeState.fieldBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.gold, width: 2),
                              ),
                              child: ClipOval(
                                child: _driverPhotoUrl != null && _driverPhotoUrl!.isNotEmpty
                                    ? Image.network(
                                        _driverPhotoUrl!,
                                        fit: BoxFit.cover,
                                        width: ResponsiveHelper.getResponsiveSpacing(context, 50),
                                        height: ResponsiveHelper.getResponsiveSpacing(context, 50),
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            color: themeState.textSecondary,
                                            size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: themeState.textSecondary,
                                        size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                                      ),
                              ),
                            ),
                            
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                            
                            // Driver Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _driverName.isNotEmpty ? _driverName : 'Driver',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: themeState.textPrimary,
                                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (_driverRating > 0) ...[
                                        Icon(
                                          Icons.star,
                                          color: AppColors.gold,
                                          size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          _driverRating.toStringAsFixed(1),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: themeState.textPrimary,
                                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                                  Text(
                                    _driverCarModel.isNotEmpty && _driverPlateNumber.isNotEmpty
                                        ? '$_driverCarModel - $_driverPlateNumber'
                                        : 'Vehicle',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: themeState.textSecondary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                        
                        // Action Buttons
                        Row(
                          children: [
                            // Message Button
                            Expanded(
                              child: _buildActionButton(
                                iconAsset: 'assets/icons/message.png',
                                label: 'Message',
                                onTap: () {
                                  if (_currentRideId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No active ride')),
                                    );
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        driverName: _driverName.isNotEmpty ? _driverName : 'Driver',
                                        driverAvatar: 'assets/images/driver_avatar.png',
                                        rideId: _currentRideId!,
                                      ),
                                    ),
                                  );
                                },
                                themeState: themeState,
                              ),
                            ),
                            
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                            
                            // Call Button
                            Expanded(
                              child: _buildActionButton(
                                iconAsset: 'assets/icons/call.png',
                                label: 'Report driver',
                                onTap: () {
                                  // Handle call action
                                },
                                themeState: themeState,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  
                  // Trip Info
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                    decoration: BoxDecoration(
                      color: themeState.fieldBg,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                      border: Border.all(color: themeState.fieldBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Details',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        
                        // Pickup Location
                        Row(
                          children: [
                            Container(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                            Expanded(
                              child: Text(
                                _bookingPickupLocation.isNotEmpty ? _bookingPickupLocation : 'Current Location',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: themeState.textPrimary,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        
                        // Destination Location
                        Row(
                          children: [
                            Container(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                            Expanded(
                              child: Text(
                                _bookingDestinationLocation.isNotEmpty ? _bookingDestinationLocation : 'Destination',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: themeState.textPrimary,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideStartedPanel(ThemeState themeState) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return DraggableScrollableSheet(
      initialChildSize: isTablet ? 0.35 : 0.4,
      minChildSize: isTablet ? 0.25 : 0.3,
      maxChildSize: isTablet ? 0.5 : 0.6,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
              topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 4),
                      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                      decoration: BoxDecoration(
                        color: themeState.textSecondary,
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
                      ),
                    ),
                  ),
                  
                  // Ride Started Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                            height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                          Text(
                            'Ride in Progress',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                      Text(
                        'Enjoy your ride!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  
                  // Driver Details Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                    decoration: BoxDecoration(
                      color: themeState.fieldBg,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                      border: Border.all(color: themeState.fieldBorder),
                    ),
                    child: Column(
                      children: [
                        // Driver Profile
                        Row(
                          children: [
                            // Driver Avatar
                            Container(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 50),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 50),
                              decoration: BoxDecoration(
                                color: themeState.fieldBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.gold, width: 2),
                              ),
                              child: ClipOval(
                                child: _driverPhotoUrl != null && _driverPhotoUrl!.isNotEmpty
                                    ? Image.network(
                                        _driverPhotoUrl!,
                                        fit: BoxFit.cover,
                                        width: ResponsiveHelper.getResponsiveSpacing(context, 50),
                                        height: ResponsiveHelper.getResponsiveSpacing(context, 50),
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.person,
                                            color: themeState.textSecondary,
                                            size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                                          );
                                        },
                                      )
                                    : Icon(
                                        Icons.person,
                                        color: themeState.textSecondary,
                                        size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                                      ),
                              ),
                            ),
                            
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                            
                            // Driver Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _driverName.isNotEmpty ? _driverName : 'Driver',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: themeState.textPrimary,
                                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (_driverRating > 0) ...[
                                        Icon(
                                          Icons.star,
                                          color: AppColors.gold,
                                          size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          _driverRating.toStringAsFixed(1),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: themeState.textPrimary,
                                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                                  Text(
                                    _driverCarModel.isNotEmpty && _driverPlateNumber.isNotEmpty
                                        ? '$_driverCarModel - $_driverPlateNumber'
                                        : 'Vehicle',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: themeState.textSecondary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                        
                        // Action Buttons
                        Row(
                          children: [
                            // Emergency Button
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.emergency,
                                label: 'Emergency',
                                onTap: _showEmergencyDialog,
                                themeState: themeState,
                                isDestructive: true,
                              ),
                            ),
                            
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                            
                            // Call Button
                            Expanded(
                              child: _buildActionButton(
                                iconAsset: 'assets/icons/call.png',
                                label: 'Report driver',
                                onTap: () {
                                  // Handle call action
                                },
                                themeState: themeState,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  
                  // Trip Progress Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                    decoration: BoxDecoration(
                      color: themeState.fieldBg,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                      border: Border.all(color: themeState.fieldBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Progress',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        
                        // Progress Indicator
                        Row(
                          children: [
                            // Pickup Location (Completed)
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: ResponsiveHelper.getResponsiveSpacing(context, 12),
                                    height: ResponsiveHelper.getResponsiveSpacing(context, 12),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                                  Text(
                                    'Picked up',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Progress Line
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                            
                            // Destination Location (In Progress)
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: ResponsiveHelper.getResponsiveSpacing(context, 12),
                                    height: ResponsiveHelper.getResponsiveSpacing(context, 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                                  Text(
                                    'En route',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: themeState.textSecondary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        
                        // Locations
                        Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                  height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                                Expanded(
                                  child: Text(
                                    _bookingPickupLocation.isNotEmpty ? _bookingPickupLocation : 'Current Location',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: themeState.textPrimary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                            
                            Row(
                              children: [
                                Container(
                                  width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                  height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                                Expanded(
                                  child: Text(
                                    _bookingDestinationLocation.isNotEmpty ? _bookingDestinationLocation : 'Destination',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: themeState.textPrimary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    String? iconAsset,
    required String label,
    required VoidCallback onTap,
    required ThemeState themeState,
    bool isDestructive = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenWidth < 360;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 64) : 
                   isSmallScreen ? ResponsiveHelper.getResponsiveSpacing(context, 48) : 
                   ResponsiveHelper.getResponsiveSpacing(context, 56),
            height: isTablet ? ResponsiveHelper.getResponsiveSpacing(context, 64) : 
                    isSmallScreen ? ResponsiveHelper.getResponsiveSpacing(context, 48) : 
                    ResponsiveHelper.getResponsiveSpacing(context, 56),
            decoration: BoxDecoration(
              color: themeState.fieldBg,
              shape: BoxShape.circle,
              border: Border.all(color: themeState.fieldBorder),
            ),
            child: iconAsset != null
                ? Image.asset(
                    iconAsset,
                    width: isTablet ? ResponsiveHelper.getResponsiveIconSize(context, 28) : 
                           isSmallScreen ? ResponsiveHelper.getResponsiveIconSize(context, 20) : 
                           ResponsiveHelper.getResponsiveIconSize(context, 24),
                    height: isTablet ? ResponsiveHelper.getResponsiveIconSize(context, 28) : 
                            isSmallScreen ? ResponsiveHelper.getResponsiveIconSize(context, 20) : 
                            ResponsiveHelper.getResponsiveIconSize(context, 24),
                    color: isDestructive ? Colors.red : themeState.textPrimary,
                  )
                : Icon(
                    icon ?? Icons.help_outline,
                    color: isDestructive ? Colors.red : themeState.textPrimary,
                    size: isTablet ? ResponsiveHelper.getResponsiveIconSize(context, 28) : 
                           isSmallScreen ? ResponsiveHelper.getResponsiveIconSize(context, 20) : 
                           ResponsiveHelper.getResponsiveIconSize(context, 24),
                  ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDestructive ? Colors.red : themeState.textSecondary,
              fontSize: isTablet ? ResponsiveHelper.getResponsiveFontSize(context, 14) : 
                     isSmallScreen ? ResponsiveHelper.getResponsiveFontSize(context, 10) : 
                     ResponsiveHelper.getResponsiveFontSize(context, 12),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingPanel(ThemeState themeState) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
              topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar with Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showBookingPanel = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 8)),
                          child: Icon(
                            Icons.close,
                            color: themeState.textSecondary,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                        ),
                      ),
                      Container(
                        width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 4),
                        decoration: BoxDecoration(
                          color: themeState.textSecondary,
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 36)), // Spacer to center the handle
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  // Pickup and Destination Section
                  _buildBookingLocationSection(themeState),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Choose a ride section
                  _buildBookingChooseRideSection(themeState),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Payment and Promo section
                  _buildBookingPaymentSection(themeState),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Confirm Button
                  _buildBookingConfirmButton(themeState),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingLocationSection(ThemeState themeState) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
      decoration: BoxDecoration(
        color: themeState.isDarkTheme ? Color(0xFF1A1A2E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        border: Border.all(
          color: themeState.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup icon with dot
              Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 20),
                height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme ? Colors.black : Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    Text(
                      _bookingPickupLocation,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Horizontal separator line
          Container(
            height: 1,
            color: themeState.textSecondary.withOpacity(0.3),
            margin: EdgeInsets.only(left: ResponsiveHelper.getResponsiveSpacing(context, 32)),
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Destination
          Row(
            children: [
              // Destination pin icon
              Icon(
                Icons.location_on,
                color: Colors.blue,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destination',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    Text(
                      _bookingDestinationLocation,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingChooseRideSection(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a ride',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        
        // Ride Options
        _buildBookingRideOption(
          themeState: themeState,
          rideType: 'Q-Standard',
          carIcon: Icons.directions_car,
          carImage: 'https://images.pexels.com/photos/100656/pexels-photo-100656.jpeg',
          passengers: '1-4',
          description: 'Affordable and reliable',
          priceValue: _ridePrices['Q-Standard'],
          isSelected: _selectedRideType == 'Q-Standard',
          hasDiscount: false,
        ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        
        _buildBookingRideOption(
          themeState: themeState,
          rideType: 'Q-Comfort',
          carIcon: Icons.directions_car,
          carImage: 'https://w0.peakpx.com/wallpaper/454/257/HD-wallpaper-toyota-fine-comfort-ride-concept-2017-cars-of-the-future-new-cars-japanese-cars-toyota.jpg',
          passengers: '1-4',
          description: 'Newer cars, extra space',
          priceValue: _ridePrices['Q-Comfort'],
          isSelected: _selectedRideType == 'Q-Comfort',
          hasDiscount: false,
        ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        
        _buildBookingRideOption(
          themeState: themeState,
          rideType: 'Q-XL',
          carIcon: Icons.directions_car,
          carImage: 'https://p7.hiclipart.com/preview/404/151/610/bus-mercedes-benz-sprinter-van-car-luxury-vehicle-van.jpg',
          passengers: '1-6',
          description: 'Extra large vehicle',
          priceValue: _ridePrices['Q-XL'],
          isSelected: _selectedRideType == 'Q-XL',
          hasDiscount: false,
        ),
      ],
    );
  }

  Widget _buildBookingRideOption({
    required ThemeState themeState,
    required String rideType,
    required IconData carIcon,
    String? carImage,
    required String passengers,
    required String description,
    double? priceValue,
    required bool isSelected,
    required bool hasDiscount,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRideType = rideType;
        });
      },
      child: Container(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
        decoration: BoxDecoration(
          color: themeState.panelBg,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          border: Border.all(
            color: isSelected ? AppColors.gold : themeState.fieldBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Car Image
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 60),
              height: ResponsiveHelper.getResponsiveSpacing(context, 40),
              decoration: BoxDecoration(
                color: themeState.fieldBg,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
              ),
              child: carImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                      child: Image.network(
                        carImage,
                        width: ResponsiveHelper.getResponsiveSpacing(context, 60),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            carIcon,
                            color: themeState.textSecondary,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 20),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      carIcon,
                      color: themeState.textSecondary,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                    ),
            ),
            
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            
            // Ride Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rideType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: themeState.textSecondary,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      Text(
                        passengers,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: themeState.textSecondary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: hasDiscount ? AppColors.gold : themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    ),
                  ),
                ],
              ),
            ),
            
            // Price display
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isFetchingPrices)
                  SizedBox(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 20),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  )
                else if (priceValue != null)
                  Text(
                    'QAR ${priceValue.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingPaymentSection(ThemeState themeState) {
    return Row(
      children: [
        // Payment Method Dropdown
        Expanded(
          child: GestureDetector(
            onTap: () => _showPaymentMethodDialog(themeState),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
              ),
              decoration: BoxDecoration(
                color: themeState.panelBg,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                border: Border.all(color: themeState.fieldBorder),
              ),
              child: Row(
                children: [
                  // Payment icon based on selection
                  _getPaymentIcon(),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: Text(
                      _selectedPaymentMethod,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: themeState.textSecondary,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Promo Button
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
          ),
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
            border: Border.all(color: themeState.fieldBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer,
                color: AppColors.gold,
                size: ResponsiveHelper.getResponsiveIconSize(context, 16),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
              Text(
                'Promo',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingConfirmButton(ThemeState themeState) {
    return GestureDetector(
      onTap: _isCreatingRide ? null : () async {        
        // Validate destination coordinates
        if (_destinationLatLng == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid destination'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }        
        // Calculate distance
        final distance = ApiService.calculateDistance(
          lat1: _currentPosition.latitude,
          lng1: _currentPosition.longitude,
          lat2: _destinationLatLng!.latitude,
          lng2: _destinationLatLng!.longitude,
        );
        
        // Calculate fare
        final fare = ApiService.calculateFare(distance);        
        
        // Set loading state and store calculated values
        setState(() {
          _isCreatingRide = true;
          _calculatedDistance = distance;
          _calculatedFare = fare;
        });
        
        try {
          // Call create ride API
          final response = await ApiService.createRide(
            pickupLat: _currentPosition.latitude,
            pickupLng: _currentPosition.longitude,
            pickupAddress: _bookingPickupLocation,
            dropoffLat: _destinationLatLng!.latitude,
            dropoffLng: _destinationLatLng!.longitude,
            dropoffAddress: _bookingDestinationLocation,
            estimatedFare: fare,
            carType: _selectedRideType,
          );
          
          print('🚗 CREATE RIDE API RESPONSE:');
          print('   Full Response: $response');
          print('   Success: ${response['success']}');
          if (response['data'] != null) {
            print('   Data: ${response['data']}');
          }
          if (response['error'] != null) {
            print('   Error: ${response['error']}');
          }
          
          // Extract pricing_details from response
          final pricingDetails = response['data']?['data']?['pricing_details'];
          if (pricingDetails != null && pricingDetails['estimated_fare'] != null) {
            final apiFare = (pricingDetails['estimated_fare'] as num).toDouble();
            setState(() {
              _calculatedFare = apiFare;
            });
            print('💰 UPDATED FARE FROM API: QAR ${apiFare.toStringAsFixed(2)}');
          }
          
          if (response['success']) {
            final successMessage = response['data']?['message'] ?? response['message'] ?? 'Ride created successfully!';
            
            // Handle double-nested structure: response['data']['data']['ride']['id']
            var rideId;
            final firstData = response['data'];
            
            if (firstData is Map && firstData.containsKey('data')) {
              final secondData = firstData['data'];              
              
              if (secondData is Map && secondData.containsKey('ride')) {
                final ride = secondData['ride'];
                rideId = ride?['id'];
              } else if (secondData is Map && secondData.containsKey('ride_id')) {
                rideId = secondData['ride_id'];
              } else if (secondData is Map && secondData.containsKey('id')) {
                rideId = secondData['id'];
              }
            } else {
              // Fallback: try direct extraction
              rideId = firstData?['ride']?['id'] ?? 
                      firstData?['ride_id'] ?? 
                      firstData?['id'];
            }            
            
            // Validate ride ID was extracted
            if (rideId == null) {              
              print('❌ RIDER - ERROR: Ride created but ID not found in response');
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Ride created but ID not found. Please try again.'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 4),
                  ),
                );
                
                setState(() {
                  _isCreatingRide = false;
                });
              }
              return;
            }
            
            print('✅ RIDER - RIDE CREATED SUCCESSFULLY - Ride ID: $rideId');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(successMessage),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              
        setState(() {
          _showBookingPanel = false;
                _isCreatingRide = false;
                _isConnectingToDriver = true; // Show connecting to driver UI
                _isDeliveryOrder = false; // Mark as ride order (not delivery)
                _currentRideId = rideId; // Store the ride ID
                
                // Start ripple animations
                _rippleController1.repeat();
                _rippleController2.repeat();
                _rippleController3.repeat();
              });
              
              print('🎯 RIDER - AFTER CREATING RIDE: connecting=$_isConnectingToDriver, rideId=$_currentRideId');
              
              // Save ride to RideCubit for persistence
              context.read<RideCubit>().startRideSearch(
                pickup: _bookingPickupLocation,
                destination: _bookingDestinationLocation,
                rideId: rideId.toString(),
              );
              
              // Start polling ride status
              _startRideStatusPolling();
              
              print('🔄 RIDER - POLLING STARTED FOR NEW RIDE');
            }
          } else {            
            String errorMessage = 'Failed to create ride. Please try again.';
            if (response['error'] != null) {
              if (response['error'] is String) {
                errorMessage = response['error'];
              } else if (response['error'] is Map) {
                final error = response['error'];
                errorMessage = error['message'] ?? error['error'] ?? 'Failed to create ride. Please try again.';
              }
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
              
              setState(() {
                _isCreatingRide = false;
              });
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Network error: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            
            setState(() {
              _isCreatingRide = false;
            });
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
        ),
        decoration: BoxDecoration(
          color: _isCreatingRide ? Colors.grey : AppColors.gold,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 32)),
          boxShadow: _isCreatingRide ? [] : [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.gold.withOpacity(0.2),
              blurRadius: 16,
              spreadRadius: 4,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: _isCreatingRide 
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  height: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                Text(
                  'Creating Ride...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(
          'Confirm $_selectedRideType',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingToDriverPanel(ThemeState themeState) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.45,
      maxChildSize: 0.45,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
              topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: ClampingScrollPhysics(),
            child: Column(
              children: [
                // Handle Bar
                Container(
                  width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                  height: ResponsiveHelper.getResponsiveSpacing(context, 4),
                  margin: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
                  ),
                ),
                
                
                // Ride Details Card
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  decoration: BoxDecoration(
                    color: themeState.fieldBg,
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pickup Location
                      Row(
                        children: [
                          Container(
                            width: ResponsiveHelper.getResponsiveSpacing(context, 12),
                            height: ResponsiveHelper.getResponsiveSpacing(context, 12),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pickup Location',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: themeState.textSecondary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                  ),
                                ),
                                Text(
                                  _bookingPickupLocation,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: themeState.textPrimary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      
                      // Destination Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.gold,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destination',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: themeState.textSecondary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                  ),
                                ),
                                Text(
                                  _bookingDestinationLocation,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: themeState.textPrimary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                      
                      // Fare Breakdown Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        decoration: BoxDecoration(
                          color: themeState.panelBg,
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: _buildFareBreakdownSection(themeState),
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      
                      // Payment Method
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        decoration: BoxDecoration(
                          color: themeState.panelBg,
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _getPaymentIcon(),
                                SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                                Text(
                                  _selectedPaymentMethod,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: themeState.textPrimary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                _showPaymentMethodDialog(themeState);
                              },
                              child: Text(
                                'Change',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                
                // Cancel Ride Button
                Container(
                  margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  child: Container(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                    ),
                    child: TextButton(
                      onPressed: _showCancelRideDialog,
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                        ),
                      ),
                      child: Text(
                        'Cancel Ride',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: themeState.panelBg,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFareBreakdownSection(ThemeState themeState) {
    // Use real calculated values (distance in km, fare in QAR)
    final distanceStr = '${_calculatedDistance.toStringAsFixed(2)} km';
    final fareStr = 'QAR ${_calculatedFare.toStringAsFixed(2)}';
    // Estimated time for ride
    final estimatedTimeStr = _routeDurationText.isNotEmpty 
        ? _routeDurationText 
        : (_routeDurationMinutes != null 
            ? '${_routeDurationMinutes} min' 
            : 'Calculating...');
    
    return Column(
      children: [
        // Distance
        _buildFareBreakdownRow('Distance', distanceStr, themeState),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        // Estimated time for ride
        _buildFareBreakdownRow('Estimated Time', estimatedTimeStr, themeState),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        // Total
        Container(
          padding: EdgeInsets.only(top: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: _buildFareBreakdownRow('Total Fare', fareStr, themeState, isTotal: true),
        ),
      ],
    );
  }

  Widget _buildFareBreakdownRow(String label, String amount, ThemeState themeState, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isTotal ? themeState.textPrimary : themeState.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isTotal ? AppColors.gold : themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }


  // Helper: Parse POINT geometry from PostGIS (format: "POINT(lng lat)")
  LatLng? _parsePointGeometry(String? pointString) {
    if (pointString == null || pointString.isEmpty) return null;
    
    try {
      // Remove "POINT(" and ")"
      final coords = pointString
          .replaceAll('POINT(', '')
          .replaceAll(')', '')
          .trim()
          .split(' ');
      
      if (coords.length == 2) {
        final lng = double.parse(coords[0]);
        final lat = double.parse(coords[1]);
        return LatLng(lat, lng);
      }
    } catch (e) {
      print('❌ RIDER - Error parsing POINT geometry: $e');
    }
    return null;
  }

  // Helper: Format ISO 8601 timestamp to readable time (e.g., "10:45 AM")
  String _formatEstimatedArrivalTime(String? isoTimestamp) {
    if (isoTimestamp == null || isoTimestamp.isEmpty) return '';
    
    try {
      final dateTime = DateTime.parse(isoTimestamp);
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      
      return '$displayHour:$minute $period';
    } catch (e) {
      print('❌ RIDER - Error parsing timestamp: $e');
      return '';
    }
  }

  // Helper: Calculate minutes remaining until arrival
  int? _calculateMinutesUntilArrival(DateTime? estimatedArrival) {
    if (estimatedArrival == null) return null;
    
    final now = DateTime.now();
    final difference = estimatedArrival.difference(now);
    
    if (difference.isNegative) return 0; // Driver is late or already arrived
    return difference.inMinutes;
  }

  // Helper: Update ETA from ride info response
  void _updateETAFromRideInfo(Map<String, dynamic>? rideData) {
    if (rideData == null) return;
    
    try {
      // Parse estimated_arrival_time
      final estimatedArrivalString = rideData['estimated_arrival_time'] as String?;
      if (estimatedArrivalString != null) {
        _estimatedArrivalTime = DateTime.parse(estimatedArrivalString);
        _minutesUntilArrival = _calculateMinutesUntilArrival(_estimatedArrivalTime);
        
        print('⏰ RIDER - ETA Updated:');
        print('   Estimated Arrival: ${_formatEstimatedArrivalTime(estimatedArrivalString)}');
        print('   Minutes Remaining: $_minutesUntilArrival min');
      }
      
      // Parse driver_current_location (POINT geometry)
      final driverLocationString = rideData['driver_current_location'] as String?;
      if (driverLocationString != null) {
        final driverLocation = _parsePointGeometry(driverLocationString);
        if (driverLocation != null) {
          print('📍 RIDER - Driver Location Updated: ${driverLocation.latitude}, ${driverLocation.longitude}');
          // Update driver marker on map (implementation depends on your marker logic)
          _updateDriverLocationOnMap(driverLocation);
        }
      }
    } catch (e) {
      print('❌ RIDER - Error updating ETA from ride info: $e');
    }
  }

  // Helper: Update driver location marker on map
  void _updateDriverLocationOnMap(LatLng driverLocation) {
    if (!mounted) return;
    // No longer needed - Google Maps handles markers automatically
  }

  // Get payment icon based on selected method
  Widget _getPaymentIcon() {
    if (_selectedPaymentMethod == 'Visa Card •••• 4242') {
      return Container(
        width: ResponsiveHelper.getResponsiveSpacing(context, 40),
        height: ResponsiveHelper.getResponsiveSpacing(context, 24),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 4)),
        ),
        child: Center(
          child: Text(
            'VISA',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (_selectedPaymentMethod == 'Cash Payment') {
      return Icon(
        Icons.money,
        color: Colors.green,
        size: ResponsiveHelper.getResponsiveIconSize(context, 24),
      );
    } else {
      // Default icon for "Payment Method"
      return Icon(
        Icons.payment,
        color: Colors.grey,
        size: ResponsiveHelper.getResponsiveIconSize(context, 24),
      );
    }
  }

  // Show payment method selection dialog
  void _showPaymentMethodDialog(ThemeState themeState) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        // Increase dialog width by reducing horizontal padding even more
        final horizontalPadding = screenWidth > 600 
            ? screenWidth * 0.15  // 15% padding on tablets (70% width dialog)
            : screenWidth * 0.02; // 2% padding on phones (96% width dialog)
        
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
          child: Container(
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeState.panelBg,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.purple.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.payment,
                        size: 40,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Select Payment Method',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: themeState.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Choose how you\'d like to pay for your ride',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeState.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Payment options
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildPaymentOption(
                        'Payment Method',
                        Icons.payment,
                        Colors.grey,
                        themeState,
                      ),
                      SizedBox(height: 12),
                      _buildPaymentOption(
                        'Visa Card •••• 4242',
                        Icons.credit_card,
                        Colors.blue,
                        themeState,
                      ),
                      SizedBox(height: 12),
                      _buildPaymentOption(
                        'Cash Payment',
                        Icons.money,
                        Colors.green,
                        themeState,
                      ),
                    ],
                  ),
                ),
                
                // Close button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: themeState.fieldBorder),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build payment option widget
  Widget _buildPaymentOption(String method, IconData icon, Color color, ThemeState themeState) {
    final isSelected = _selectedPaymentMethod == method;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
        Navigator.of(context).pop();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.1) 
              : themeState.panelBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? color 
                : themeState.fieldBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            // Icon container with background
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            
            SizedBox(width: 16),
            
            // Payment method text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: themeState.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  if (method == 'Visa Card •••• 4242') ...[
                    SizedBox(height: 4),
                    Text(
                      'Credit Card',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ] else if (method == 'Cash Payment') ...[
                    SizedBox(height: 4),
                    Text(
                      'Pay with cash to driver',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Selection indicator
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.green : themeState.fieldBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ========== Nearby Drivers Tracking Methods ==========

  // Load car icon bitmap (truly resized)
  Future<void> _loadCarIcon() async {
    try {
      // Desired logical size (visible size on map)
      const double logicalSize = 48; // Reduced for better balance

      // Load bytes
      final byteData = await rootBundle.load('assets/images/car.png');
      final Uint8List list = byteData.buffer.asUint8List();

      // Account for device pixel ratio for crisp rendering
      final double dpr = MediaQuery.of(context).devicePixelRatio;
      final int targetWidth = (logicalSize * dpr).round();

      // Decode and resize
      final ui.Codec codec = await ui.instantiateImageCodec(list, targetWidth: targetWidth);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ByteData? pngBytes = await fi.image.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes == null) throw Exception('Failed to convert image to bytes');

      // Create descriptor
      _carIcon = BitmapDescriptor.fromBytes(pngBytes.buffer.asUint8List());

      if (kDebugMode) {
        print('✅ Car icon loaded (logical ${logicalSize.toInt()}px, width ${targetWidth}px @dpr=${dpr.toStringAsFixed(2)})');
      }

      // Trigger initial fetch after icon is loaded
      if (mounted && !_isLocationLoading && !_isPollingNearbyDrivers) {
        _startNearbyDriversPolling();
      }

      // Force update markers if we already have drivers
      if (mounted && _driverMarkers.isNotEmpty) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading car icon: $e');
      }
      // Retry loading after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _carIcon == null) {
          _loadCarIcon();
        }
      });
    }
  }

  // Start polling for nearby drivers
  void _startNearbyDriversPolling() {
    if (_isPollingNearbyDrivers) {
      if (kDebugMode) {
        print('🚗 Already polling for nearby drivers');
      }
      return;
    }
    
    if (_carIcon == null) {
      if (kDebugMode) {
        print('⚠️ Car icon not loaded yet, waiting...');
      }
      return;
    }
    
    if (_isLocationLoading) {
      if (kDebugMode) {
        print('⚠️ Location not loaded yet, waiting...');
      }
      return;
    }
    
    _isPollingNearbyDrivers = true;
    
    if (kDebugMode) {
      print('🚗 Started polling for nearby drivers');
      print('   Current position: ${_currentPosition.latitude}, ${_currentPosition.longitude}');
    }
    
    // Poll immediately on start
    _fetchNearbyDrivers();
    
    // Then poll every 5 seconds (always show nearby drivers regardless of ride state)
    _nearbyDriversPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      _fetchNearbyDrivers();
    });
  }

  // Stop polling for nearby drivers
  void _stopNearbyDriversPolling() {
    _isPollingNearbyDrivers = false;
    _nearbyDriversPollingTimer?.cancel();
    _nearbyDriversPollingTimer = null;
    
    if (kDebugMode) {
      print('🚗 Stopped polling for nearby drivers');
    }
  }

  // Fetch nearby drivers from API
  Future<void> _fetchNearbyDrivers() async {
    // If we know the assigned driver is offline, don't show their car on the map
    if (_isDriverOnline == false && _currentRideId != null) {
      if (kDebugMode) {
        print('🚫 Skipping nearby drivers fetch: assigned driver is offline');
      }
      _clearAllDriverMarkers();
      return;
    }
    if (_carIcon == null) {
      if (kDebugMode) {
        print('⚠️ Cannot fetch nearby drivers: Car icon not loaded');
      }
      return; // Wait for location and icon to be ready
    }

    if (_isLocationLoading) {
      if (kDebugMode) {
        print('⚠️ Cannot fetch nearby drivers: Location still loading');
      }
      return;
    }

    if (kDebugMode) {
      print('🔍 Fetching nearby drivers...');
      print('   Position: ${_currentPosition.latitude}, ${_currentPosition.longitude}');
    }

    try {
      final response = await ApiService.getNearbyDrivers(
        latitude: _currentPosition.latitude,
        longitude: _currentPosition.longitude,
        radiusKm: 5,
        limit: 50,
      );

      if (!mounted) return;

      if (kDebugMode) {
        print('📡 Nearby drivers API response:');
        print('   Success: ${response['success']}');
        print('   Has data: ${response['data'] != null}');
        if (response['error'] != null) {
          print('   Error: ${response['error']}');
        }
      }

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        // Support both flat and nested data structures
        final drivers = (data is Map)
            ? (data['drivers'] as List? ?? (data['data'] is Map ? data['data']['drivers'] as List? : null))
            : null;

        if (kDebugMode) {
          print('   Drivers count: ${drivers?.length ?? 0}');
          if (drivers != null && drivers.isNotEmpty) {
            print('   📋 Full driver data sample: ${drivers[0]}');
          }
        }

        if (drivers != null && drivers.isNotEmpty) {
          final Set<String> currentDriverIds = {};
          final Set<String> onlineDriverIds = {}; // Track drivers that are online
          
          // Process each driver from API response
          for (final driverData in drivers) {
            final driverId = driverData['driver_id']?.toString();
            final location = driverData['location'];
            
            // Log full driver data for debugging
            if (kDebugMode) {
              print('   🔍 Processing driver: $driverId');
              print('     Full driver data: $driverData');
            }
            
            // Check multiple fields for driver status
            final isAvailable = driverData['is_available'] == true;
            
            // Check is_online field - STRICT: if field exists and is false, driver is offline
            final isOnlineField = driverData['is_online'];
            bool isOnline;
            if (isOnlineField != null) {
              // Field exists - check its value
              isOnline = isOnlineField == true;
            } else {
              // Field doesn't exist - check other indicators
              // If is_available is false, assume offline
              isOnline = isAvailable;
            }
            
            // Check status field (some APIs use 'online'/'offline' strings)
            final status = driverData['status']?.toString().toLowerCase();
            bool isStatusOnline;
            if (status != null) {
              // Status field exists - check if it indicates online
              isStatusOnline = status == 'online' || status == 'active' || status == 'available';
            } else {
              // No status field - rely on is_online and is_available
              isStatusOnline = isOnline;
            }
            
            // Also check for driver_status field (alternative field name)
            final driverStatus = driverData['driver_status']?.toString().toLowerCase();
            if (driverStatus != null) {
              isStatusOnline = driverStatus == 'online' || driverStatus == 'active' || driverStatus == 'available';
            }
            
            // Driver must be available AND online to show on map
            // If any check fails, driver is offline
            final shouldShow = isAvailable && isOnline && isStatusOnline;
            
            if (kDebugMode) {
              print('     Status check:');
              print('       is_available: $isAvailable');
              print('       is_online: $isOnline (field value: $isOnlineField)');
              print('       status: $status');
              print('       driver_status: $driverStatus');
              print('       shouldShow: $shouldShow');
            }
            
            // If driver is offline, remove them from map immediately
            if (driverId != null && _driverMarkers.containsKey(driverId) && !shouldShow) {
              if (kDebugMode) {
                print('     🚫 Driver $driverId went offline - removing from map');
              }
              _removeDriverMarker(driverId);
              continue;
            }
            
            // Only show drivers who are available AND online
            if (driverId == null || location == null || !shouldShow) {
              if (kDebugMode) {
                print('     ⏭️ Skipping driver: id=$driverId, location=$location, available=$isAvailable, online=$isOnline, status=$status');
              }
              continue;
            }

            final lat = (location['latitude'] as num?)?.toDouble();
            final lng = (location['longitude'] as num?)?.toDouble();
            final heading = (driverData['heading'] as num?)?.toDouble() ?? 0.0;

            if (lat == null || lng == null) {
              if (kDebugMode) {
                print('     Skipping driver $driverId: Invalid coordinates');
              }
              continue;
            }

            final newPosition = LatLng(lat, lng);
            currentDriverIds.add(driverId);
            onlineDriverIds.add(driverId); // Track as online

            if (kDebugMode) {
              print('     ✅ Adding driver $driverId at ($lat, $lng) heading: $heading');
            }

            // Check if this driver already exists
            if (_driverMarkers.containsKey(driverId)) {
              // Animate to new position
              final oldState = _driverMarkers[driverId]!;
              if (oldState.position != newPosition) {
                _animateDriver(driverId, oldState.position, newPosition, heading);
              } else {
                // Position hasn't changed, just update heading
                _updateDriverMarker(driverId, newPosition, heading);
              }
            } else {
              // New driver - add immediately
              _updateDriverMarker(driverId, newPosition, heading);
            }
          }

          // SECOND PASS: Check all drivers in response again to catch any that went offline
          // This ensures we catch drivers that were previously online but are now offline
          for (final driverData in drivers) {
            final driverId = driverData['driver_id']?.toString();
            if (driverId == null) continue;
            
            // If this driver is on the map but should not be shown, remove them
            if (_driverMarkers.containsKey(driverId)) {
              final isAvailable = driverData['is_available'] == true;
              final isOnlineField = driverData['is_online'];
              final isOnline = isOnlineField != null ? isOnlineField == true : isAvailable;
              final status = driverData['status']?.toString().toLowerCase();
              final driverStatus = driverData['driver_status']?.toString().toLowerCase();
              
              bool isStatusOnline = true;
              if (status != null) {
                isStatusOnline = status == 'online' || status == 'active' || status == 'available';
              } else if (driverStatus != null) {
                isStatusOnline = driverStatus == 'online' || driverStatus == 'active' || driverStatus == 'available';
              }
              
              final shouldShow = isAvailable && isOnline && isStatusOnline;
              
              if (!shouldShow && onlineDriverIds.contains(driverId)) {
                // Driver was online but is now offline - remove immediately
                if (kDebugMode) {
                  print('   🚫 SECOND PASS: Driver $driverId went offline - removing from map');
                }
                _removeDriverMarker(driverId);
                onlineDriverIds.remove(driverId);
              }
            }
          }
          
          // Remove drivers that are no longer in the response OR are now offline
          final driversToRemove = _driverMarkers.keys.where((id) => 
            !currentDriverIds.contains(id) || !onlineDriverIds.contains(id)
          ).toList();
          for (final driverId in driversToRemove) {
            if (kDebugMode) {
              print('   🗑️ Removing driver $driverId (not in response or went offline)');
            }
            _removeDriverMarker(driverId);
          }

          if (kDebugMode) {
            print('   Total driver markers on map: ${_driverMarkers.length}');
          }

          // Update markers set
          setState(() {});
        } else {
          if (kDebugMode) {
            print('   No drivers found in response');
          }
          // No drivers found - clear all markers
          _clearAllDriverMarkers();
        }
      } else {
        if (kDebugMode) {
          print('❌ API call failed or returned no data');
          print('   Response: $response');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error fetching nearby drivers: $e');
        print('   Stack trace: $stackTrace');
      }
    }
  }

  // Start polling assigned driver's online status
  void _startDriverOnlineStatusPolling() {
    // Only poll when there is an active ride
    if (_currentRideId == null) return;

    _driverOnlineStatusPollingTimer?.cancel();

    if (kDebugMode) {
      print('📡 Starting driver online status polling for ride: $_currentRideId');
    }

    // Poll immediately
    _checkDriverOnlineStatus();

    // Then poll periodically
    _driverOnlineStatusPollingTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || _currentRideId == null) {
        timer.cancel();
        return;
      }
      _checkDriverOnlineStatus();
    });
  }

  // Stop polling assigned driver's online status
  void _stopDriverOnlineStatusPolling() {
    if (kDebugMode) {
      print('📡 Stopping driver online status polling');
    }
    _driverOnlineStatusPollingTimer?.cancel();
    _driverOnlineStatusPollingTimer = null;
  }

  // Check assigned driver's online status via API
  Future<void> _checkDriverOnlineStatus() async {
    if (!ApiService.isAuthenticated || _currentRideId == null) {
      if (kDebugMode) {
        print('📡 Skipping driver-online-status: not authenticated or no active ride');
      }
      return;
    }

    try {
      final response = await ApiService.driverOnlineStatus();

      if (kDebugMode) {
        print('📡 Driver-online-status API response: $response');
      }

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        // Handle both flat and nested data shapes
        final inner = (data is Map && data['data'] is Map) ? data['data'] : data;

        final isOnline = inner['is_online'] == true;
        final canReceive = inner['can_receive_rides'] == true;
        final effectiveOnline = isOnline && canReceive;

        if (kDebugMode) {
          print('📡 Driver-online-status parsed: is_online=$isOnline, can_receive_rides=$canReceive, effective=$effectiveOnline');
        }

        if (!mounted) return;

        setState(() {
          _isDriverOnline = effectiveOnline;
        });

        if (!effectiveOnline) {
          // Hide assigned driver's car from the map
          if (kDebugMode) {
            print('🚫 Assigned driver is offline - clearing driver markers');
          }
          _clearAllDriverMarkers();
        } else {
          // If driver is online and we currently have no markers, trigger a refresh
          if (_driverMarkers.isEmpty && !_isLocationLoading) {
            if (kDebugMode) {
              print('✅ Assigned driver is online - ensuring markers are refreshed');
            }
            _fetchNearbyDrivers();
          }
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error checking driver-online-status: $e');
        print('   Stack trace: $stackTrace');
      }
    }
  }

  // Update or create driver marker
  void _updateDriverMarker(String driverId, LatLng position, double heading) {
    if (_carIcon == null) return;

    _driverMarkers[driverId] = _DriverMarkerState(
      position: position,
      heading: heading,
    );

    if (kDebugMode) {
      print('🚗 Updated driver marker: $driverId at (${position.latitude}, ${position.longitude}) heading: $heading');
    }
  }

  // Animate driver marker from old to new position
  void _animateDriver(String driverId, LatLng from, LatLng to, double heading) {
    // Cancel existing animation for this driver
    _driverAnimations[driverId]?.cancel();

    // Calculate distance to determine animation duration
    final distance = geo.Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    
    // Adjust duration based on distance for smoother animation
    // Base duration: 2 seconds, add more time for longer distances
    final baseDuration = 2000; // 2 seconds base
    final distanceMultiplier = (distance / 100).clamp(0.0, 3.0); // Max 3x for very long distances
    final durationMs = (baseDuration + (distance * distanceMultiplier)).round().clamp(1000, 5000);
    
    final startTime = DateTime.now();
    final fromLat = from.latitude;
    final fromLng = from.longitude;
    final latDiff = to.latitude - fromLat;
    final lngDiff = to.longitude - fromLng;

    _driverAnimations[driverId] = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || !_driverMarkers.containsKey(driverId)) {
        timer.cancel();
        _driverAnimations.remove(driverId);
        return;
      }

      final elapsed = DateTime.now().difference(startTime);
      final progress = (elapsed.inMilliseconds / durationMs).clamp(0.0, 1.0);
      
      // Apply easing function for smoother motion (ease-in-out)
      final easedProgress = progress < 0.5
          ? 2 * progress * progress
          : 1 - pow(-2 * progress + 2, 2) / 2;

      final currentLat = fromLat + (latDiff * easedProgress);
      final currentLng = fromLng + (lngDiff * easedProgress);
      final currentPosition = LatLng(currentLat, currentLng);

      _updateDriverMarker(driverId, currentPosition, heading);

      if (progress >= 1.0) {
        timer.cancel();
        _driverAnimations.remove(driverId);
        // Ensure final position is exact
        _updateDriverMarker(driverId, to, heading);
      } else {
        // Trigger rebuild to show animation (every frame)
        setState(() {});
      }
    });
  }

  // Remove driver marker
  void _removeDriverMarker(String driverId) {
    _driverAnimations[driverId]?.cancel();
    _driverAnimations.remove(driverId);
    _driverMarkers.remove(driverId);
    
    if (kDebugMode) {
      print('🚗 Removed driver marker: $driverId');
    }
  }

  // Clear all driver markers
  void _clearAllDriverMarkers() {
    for (final timer in _driverAnimations.values) {
      timer.cancel();
    }
    _driverAnimations.clear();
    _driverMarkers.clear();
    
    if (kDebugMode) {
      print('🚗 Cleared all driver markers');
    }
  }

  // Get driver markers set for GoogleMap
  Set<Marker> _getDriverMarkers() {
    final markers = _driverMarkers.entries.map((entry) {
      final driverId = entry.key;
      final state = entry.value;

      return Marker(
        markerId: MarkerId('driver_$driverId'),
        position: state.position,
        icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: state.heading,
        anchor: const Offset(0.5, 0.5),
        flat: true, // Flat against the map
      );
    }).toSet();

    if (kDebugMode && markers.isNotEmpty) {
      print('🗺️ Created ${markers.length} driver markers for map');
    }

    return markers;
  }
}

// Helper class to track driver marker state
class _DriverMarkerState {
  final LatLng position;
  final double heading;

  _DriverMarkerState({
    required this.position,
    required this.heading,
  });
}
