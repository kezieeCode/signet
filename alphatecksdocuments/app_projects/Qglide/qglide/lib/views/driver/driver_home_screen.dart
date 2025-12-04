import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/driver_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import 'driver_earnings_screen.dart';
import 'driver_profile_screen.dart';
import '../chat/chat_screen.dart';
// import '../../utils/app_colors.dart'; // Will use Colors.amber instead

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with TickerProviderStateMixin, RestorationMixin, WidgetsBindingObserver {
  @override
  String? get restorationId => 'driver_home_screen';
  
  final RestorableBool _showRideRequestPanelRestoration = RestorableBool(false);
  final RestorableString _rideIdRestoration = RestorableString('');
  final RestorableString _riderNameRestoration = RestorableString('');
  final RestorableString _pickupAddressRestoration = RestorableString('');
  final RestorableString _dropoffAddressRestoration = RestorableString('');
  final RestorableDouble _estimatedFareRestoration = RestorableDouble(0.0);
  final RestorableDouble _distanceToPickupRestoration = RestorableDouble(0.0);
  final RestorableDouble _pickupLatRestoration = RestorableDouble(0.0);
  final RestorableDouble _pickupLngRestoration = RestorableDouble(0.0);
  final RestorableDouble _dropoffLatRestoration = RestorableDouble(0.0);
  final RestorableDouble _dropoffLngRestoration = RestorableDouble(0.0);
  
  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_showRideRequestPanelRestoration, 'show_ride_request');
    registerForRestoration(_rideIdRestoration, 'ride_id');
    registerForRestoration(_riderNameRestoration, 'rider_name');
    registerForRestoration(_pickupAddressRestoration, 'pickup_address');
    registerForRestoration(_dropoffAddressRestoration, 'dropoff_address');
    registerForRestoration(_estimatedFareRestoration, 'estimated_fare');
    registerForRestoration(_distanceToPickupRestoration, 'distance_to_pickup');
    registerForRestoration(_pickupLatRestoration, 'pickup_lat');
    registerForRestoration(_pickupLngRestoration, 'pickup_lng');
    registerForRestoration(_dropoffLatRestoration, 'dropoff_lat');
    registerForRestoration(_dropoffLngRestoration, 'dropoff_lng');
    
    // Restore the panel state
    if (_showRideRequestPanelRestoration.value) {
      _showRideRequestPanel = true;
      _rideId = _rideIdRestoration.value;
      _riderName = _riderNameRestoration.value;
      _pickupAddress = _pickupAddressRestoration.value;
      _dropoffAddress = _dropoffAddressRestoration.value;
      _estimatedFare = _estimatedFareRestoration.value;
      _distanceToPickup = _distanceToPickupRestoration.value;
      if (_pickupLatRestoration.value != 0.0 && _pickupLngRestoration.value != 0.0) {
        _pickupLocation = LatLng(_pickupLatRestoration.value, _pickupLngRestoration.value);
      }
      if (_dropoffLatRestoration.value != 0.0 && _dropoffLngRestoration.value != 0.0) {
        _dropoffLocation = LatLng(_dropoffLatRestoration.value, _dropoffLngRestoration.value);
      }
      
      // Restart animation and timer
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _slideController.forward();
        _rideRequestTimer?.cancel(); // Cancel any existing timer
        _startCountdownTimer();
      });
    }
  }
  GoogleMapController? _mapController;
  Timer? _rideRequestTimer;
  Timer? _nearbyRidesPollingTimer;
  Timer? _rideStatusPollingTimer;
  Timer? _locationUpdateTimer; // Timer for updating driver location to backend
  bool _showRideRequestPanel = false;
  int _countdownSeconds = 30; // 30 seconds countdown
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // Driver's current location
  Position? _currentPosition;
  LatLng? _driverLocation;
  bool _isLoadingLocation = true;
  
  // Nearby ride data from API
  Map<String, dynamic>? _currentRideRequest;
  String _rideId = ''; // Only set when ride is ACCEPTED
  String __pendingRideId = ''; // Private backing field
  String get _pendingRideId => __pendingRideId;
  set _pendingRideId(String value) {
    print('🔧 _pendingRideId CHANGED: "$__pendingRideId" → "$value"');
    print('   Stack trace: ${StackTrace.current}');
    __pendingRideId = value;
  }
  String _riderName = '';
  String _riderPhone = '';
  String _pickupAddress = '';
  String _dropoffAddress = '';
  double _estimatedFare = 0.0;
  double _distanceToPickup = 0.0; // Calculated distance to rider
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  bool _isRespondingToRide = false; // Loading state for accept/decline
  DateTime? _rideAcceptedAt; // Track when ride was accepted to prevent premature state clearing
  
  // Cancel ride reason
  final TextEditingController _declineReasonController = TextEditingController();
  
  // Earnings data from API
  double _todayNetEarnings = 0.0;
  int _todayRidesCount = 0;
    String _currency = 'QAR';
  
  // Trip progress tracking
  Timer? _tripProgressTimer;
  double _initialDistanceToPickup = 0.0; // Total distance at trip start
  double _currentDistanceToPickup = 0.0; // Current distance to pickup
  bool _hasShownPickupArrival = false; // Flag to prevent showing arrival message multiple times
  String _estimatedTimeToPickup = '-- min'; // Estimated time from Google Maps
  int _progressUpdateCounter = 0; // Counter for ETA recalculation
  
  // Route polyline
  Set<Polyline> _routePolylines = {};
  Set<Marker> _tripMarkers = {};
  
  // Google Maps API Key
  static const String _googleMapsApiKey = 'AIzaSyBrThzOJlW4SbyUHKLoCrv9yK5AAs_esao';

  final List<Map<String, dynamic>> _bottomNavItems = [
    {'label': 'Home', 'icon': Icons.home},
    {'label': 'Earnings', 'icon': Icons.pie_chart},
    {'label': 'Profile', 'icon': Icons.person},
  ];

  @override
  void initState() {
    super.initState();
    
    // CRITICAL FIX: Clear any persisted trip state IMMEDIATELY before first UI build
    // This prevents showing stale trip panel while backend verification happens
    final driverState = context.read<DriverCubit>().state;
    if (driverState.isOnTrip) {
      print('⚠️ DRIVER - initState: Clearing persisted trip state before first build');
      context.read<DriverCubit>().completeTrip();
      _rideId = '';
    }
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize slide animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    // Load persisted ride request state
    _loadRideRequestState();
    
    // Get driver's current location
    _getDriverLocation();
    
    // Fetch driver earnings
    _fetchDriverEarnings();
    
    // Start polling for nearby rides (every 1 second)
    _startNearbyRidesPolling();
    
    // Start updating driver location to backend (every 5 seconds)
    _startLocationUpdates();
    
    // Check for persisted trip state and resume tracking if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndResumeTripTracking();
      // Note: _checkAndResumeTripTracking() will call _checkBackendForActiveTrips() internally
    });
  }
  
  // Check if there's a persisted trip and resume tracking
  void _checkAndResumeTripTracking() async {
    print('╔════════════════════════════════════════════════════════════════╗');
    print('║  🚗 DRIVER - _checkAndResumeTripTracking called                 ║');
    print('╚════════════════════════════════════════════════════════════════╝');
    print('   Note: State was already cleared in initState to prevent stale UI');
    print('   Now checking backend for any active trips...');
    
    // Wait a bit to let nearby rides polling show any pending requests first
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check backend for any active trips (will restore if found)
    await _checkBackendForActiveTrips();
      
      // After verification, check if state was restored
      final stateAfterVerification = context.read<DriverCubit>().state;
      if (stateAfterVerification.isOnTrip) {
        print('✅ DRIVER - Trip was restored by backend check - it was a real accepted trip');
      } else {
      print('✅ DRIVER - No active trip found on backend');
    }
  }
  
  /// Check backend for any active trips (handles logout/login scenario)
  Future<void> _checkBackendForActiveTrips() async {
    await _checkBackendForActiveTripsWithRideId(null);
  }
  
  /// Check backend for any active trips with a specific ride ID
  Future<void> _checkBackendForActiveTripsWithRideId(String? rideIdToCheck) async {
    final rideIdParam = rideIdToCheck ?? (_rideId.isNotEmpty ? _rideId : null);
    
    print('╔════════════════════════════════════════════════════════════════╗');
    print('║  🔍 DRIVER - CHECKING BACKEND FOR ACTIVE TRIPS                  ║');
    print('╚════════════════════════════════════════════════════════════════╝');
    print('   Ride ID to check: $rideIdParam');
    print('   Current isOnTrip: ${context.read<DriverCubit>().state.isOnTrip}');
    print('   _showRideRequestPanel: $_showRideRequestPanel');
    print('   _pendingRideId: $_pendingRideId');
    print('   _rideId: $_rideId');
    
    // CRITICAL: Do NOT restore trips if we're showing a ride request panel
    // This prevents the backend check from overriding a pending ride request
    if (_showRideRequestPanel) {
      print('⚠️ DRIVER - SKIPPING backend check: Ride request panel is active');
      print('   User needs to accept/reject the current request first');
      return;
    }
    
    try {
      // Pass ride_id if available to get specific ride status
      final response = await ApiService.getDriverRideStatus(
        rideId: rideIdParam,
      );
      
      print('📡 DRIVER - _checkBackendForActiveTrips API RESPONSE:');
      print('   Success: ${response['success']}');
      print('   Full response: $response');
      
      if (response['success']) {
        final data = response['data'];
        
        print('📊 DRIVER - _checkBackendForActiveTrips data structure:');
        print('   Type: ${data.runtimeType}');
        if (data is Map) {
          print('   Keys: ${data.keys.toList()}');
        }
        
        // Handle double/triple nesting: response['data']['data']['ride']
        final actualData = data is Map && data.containsKey('data') ? data['data'] : data;
        print('📊 DRIVER - Actual data keys: ${actualData is Map ? actualData.keys.toList() : "not a map"}');
        
        final rideData = actualData is Map ? actualData['ride'] : null;
        print('📊 DRIVER - Ride data: ${rideData != null ? "EXISTS" : "NULL"}');
        
        // If there's no ride object, there's no active trip
        if (rideData == null) {
          print('✅ DRIVER - No active trip found on backend (no ride object)');
          
          // CRITICAL FIX: Clear DriverCubit state if it was showing stale trip
          final currentDriverState = context.read<DriverCubit>().state;
          if (currentDriverState.isOnTrip) {
            print('🧹 DRIVER - Clearing stale trip state from DriverCubit');
            context.read<DriverCubit>().completeTrip();
            
            // Also clear local ride ID
            if (mounted) {
              setState(() {
                _rideId = '';
              });
            }
          }
          return;
        }
        
        final status = rideData['status']?.toString().toLowerCase() ?? '';
        final rideId = rideData['id']?.toString() ?? rideData['ride_id']?.toString() ?? '';
        
        print('🔍 DRIVER - Found ride on backend!');
        print('   Status: $status');
        print('   RideId: $rideId');
        
        // CRITICAL: Only restore rides that driver has ACCEPTED
        // "pending" rides should appear in nearby rides polling, not as active trips
        final acceptedStatuses = ['accepted', 'started', 'in_progress', 'ongoing', 'arrived', 'driver_arrived'];
        
        if (!acceptedStatuses.contains(status)) {
          print('⚠️ DRIVER - Ride status is "$status" - NOT an accepted trip');
          print('   This ride should appear in nearby rides polling instead');
          print('   Only restoring trips with status: ${acceptedStatuses.join(", ")}');
          
          // CRITICAL FIX: Clear DriverCubit state if it was showing stale trip
          final currentDriverState = context.read<DriverCubit>().state;
          if (currentDriverState.isOnTrip) {
            print('🧹 DRIVER - Clearing stale trip state (ride not accepted)');
            context.read<DriverCubit>().completeTrip();
            
            // Also clear local ride ID
            if (mounted) {
              setState(() {
                _rideId = '';
              });
            }
          }
          return;
        }
        
        // Check if ride is completed or cancelled
        if (status == 'completed' || status == 'cancelled') {
          print('⚠️ DRIVER - Trip already completed/cancelled on backend');
          
          // CRITICAL FIX: Clear DriverCubit state if it was showing stale trip
          final currentDriverState = context.read<DriverCubit>().state;
          if (currentDriverState.isOnTrip) {
            print('🧹 DRIVER - Clearing stale trip state (ride completed/cancelled)');
            context.read<DriverCubit>().completeTrip();
            
            // Also clear local ride ID
            if (mounted) {
              setState(() {
                _rideId = '';
              });
            }
          }
          return;
        }
        
        // CRITICAL FIX: If backend has an active ride, restore it (don't auto-cancel)
        // This follows the same pattern as the rider - restore ride state from backend
        print('✅ DRIVER - Restoring ride from backend');
        print('   RideId: $rideId, Status: $status');
        
        print('✅ DRIVER - Ride is ACCEPTED and local state exists - will restore trip');
        
        // Extract trip details
        final passengerName = rideData['rider_name'] ?? rideData['passenger_name'] ?? rideData['rider']?['name'] ?? 'Passenger';
        
        print('🐛 DEBUG - Rider name extraction:');
        print('   rideData keys: ${rideData.keys.toList()}');
        print('   rider_name: ${rideData['rider_name']}');
        print('   passenger_name: ${rideData['passenger_name']}');
        print('   rider object: ${rideData['rider']}');
        print('   Final passengerName: $passengerName');
        final pickupAddress = _extractAddress(rideData['pickup_address']);
        final dropoffAddress = _extractAddress(rideData['dropoff_address']);
        final estimatedFare = rideData['estimated_fare'] ?? rideData['fare'] ?? 0.0;
        
        print('✅ DRIVER - Restoring trip from backend...');
        print('   Pickup address: $pickupAddress');
        print('   Dropoff address: $dropoffAddress');
        
        // Parse location strings: "(lat,lng)" format
        final pickupLocationStr = rideData['pickup_location']?.toString();
        final dropoffLocationStr = rideData['dropoff_location']?.toString();
        
        print('   Pickup location string: $pickupLocationStr');
        print('   Dropoff location string: $dropoffLocationStr');
        
        // Set pickup location
        if (pickupLocationStr != null && pickupLocationStr.isNotEmpty) {
          try {
            // Remove parentheses and split by comma
            final cleanStr = pickupLocationStr.replaceAll('(', '').replaceAll(')', '');
            final parts = cleanStr.split(',');
            if (parts.length == 2) {
              _pickupLocation = LatLng(
                double.parse(parts[0].trim()),
                double.parse(parts[1].trim()),
              );
              print('   ✅ Parsed pickup location: ${_pickupLocation}');
            }
          } catch (e) {
            print('   ❌ Error parsing pickup location: $e');
          }
        }
        
        // Set dropoff location
        if (dropoffLocationStr != null && dropoffLocationStr.isNotEmpty) {
          try {
            // Remove parentheses and split by comma
            final cleanStr = dropoffLocationStr.replaceAll('(', '').replaceAll(')', '');
            final parts = cleanStr.split(',');
            if (parts.length == 2) {
              _dropoffLocation = LatLng(
                double.parse(parts[0].trim()),
                double.parse(parts[1].trim()),
              );
              print('   ✅ Parsed dropoff location: ${_dropoffLocation}');
            }
          } catch (e) {
            print('   ❌ Error parsing dropoff location: $e');
          }
        }
        
        _rideId = rideId;
        _pickupAddress = pickupAddress;
        _dropoffAddress = dropoffAddress;
        _estimatedFare = (estimatedFare is num) ? estimatedFare.toDouble() : double.tryParse(estimatedFare.toString()) ?? 0.0;
        
        // Start trip in cubit
        context.read<DriverCubit>().startTrip(
          passengerName: passengerName,
          destination: dropoffAddress,
          pickupLat: _pickupLocation?.latitude,
          pickupLng: _pickupLocation?.longitude,
          dropoffLat: _dropoffLocation?.latitude,
          dropoffLng: _dropoffLocation?.longitude,
          pickupAddress: pickupAddress,
          rideId: rideId,
        );
        
        // Sync with API status to set correct stage, preserve rideId
        final currentRideId = context.read<DriverCubit>().state.rideId ?? _rideId;
        context.read<DriverCubit>().syncFromApiStatus(status, rideId: currentRideId);
        
        // CRITICAL: Hide ride request panel and clear any pending requests
        _rideRequestTimer?.cancel();
        _showRideRequestPanel = false;
        _showRideRequestPanelRestoration.value = false;
        
        print('🚫 DRIVER - Hiding ride request panel (trip restored from backend)');
        
        // Force UI update
        if (mounted) {
          setState(() {});
        }
        
        // Start tracking
        _startTripProgressTracking();
        _startDriverRideStatusPolling();
        
        print('✅ DRIVER - Trip restored from backend successfully');
      }
    } catch (e) {
      print('❌ DRIVER - Error checking backend for active trips: $e');
    }
  }
  
  // Verify backend status before showing trip UI
  Future<void> _verifyAndResumeTrip(DriverState driverState) async {
    try {
      print('🚗 DRIVER - VERIFYING BACKEND STATUS...');
      print('   Current state: isOnTrip=${driverState.isOnTrip}, rideId=${driverState.rideId}');
      print('   tripStage=${driverState.tripStage}, apiStatus=${driverState.apiStatus}');
      
      // Pass ride_id to get specific ride status
      final rideIdToUse = driverState.rideId ?? _rideId;
      final response = await ApiService.getDriverRideStatus(
        rideId: rideIdToUse.isNotEmpty ? rideIdToUse : null,
      );
      
      print('📡 DRIVER - RAW API RESPONSE FROM driver-ride-status:');
      print('   Requested ride_id: $rideIdToUse');
      print('   Success: ${response['success']}');
      print('   Full response: $response');
      
      if (response['success']) {
        final data = response['data'];
        
        print('📊 DRIVER - Response data structure:');
        print('   Type: ${data.runtimeType}');
        if (data is Map) {
          print('   Keys: ${data.keys.toList()}');
        }
        
        // Handle double/triple nesting: response['data']['data']['ride']
        final actualData = data is Map && data.containsKey('data') ? data['data'] : data;
        print('📊 DRIVER - Actual data keys: ${actualData is Map ? actualData.keys.toList() : "not a map"}');
        
        final rideData = actualData is Map ? actualData['ride'] : null;
        print('📊 DRIVER - Ride object: ${rideData != null ? "EXISTS" : "NULL"}');
        
        // If there's no ride object, no active trip
        if (rideData == null) {
          // Don't clear state if ride was just accepted (backend might be slow to sync)
          // NOTE: On hot restart, _rideAcceptedAt is null, so this check will be skipped
          if (_rideAcceptedAt != null) {
            final timeSinceAcceptance = DateTime.now().difference(_rideAcceptedAt!).inSeconds;
            if (timeSinceAcceptance < 10) {
              print('⏰ DRIVER - Ride was accepted $timeSinceAcceptance seconds ago, backend might be syncing. Keeping state.');
              return;
            }
          }
          
          print('❌ DRIVER - NO ACTIVE RIDE IN BACKEND - CLEARING STALE STATE');
          print('   (On hot restart, this immediately clears stale trips)');
          _rideAcceptedAt = null; // Reset timestamp
          context.read<DriverCubit>().completeTrip();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No active trip found'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
        
        final status = rideData['status']?.toString().toLowerCase() ?? '';
        final rideId = rideData['ride_id']?.toString() ?? rideData['id']?.toString() ?? '';
        
        print('🚗 DRIVER - BACKEND STATUS: $status - Ride ID: $rideId');
        
        // CRITICAL: Only restore rides that driver has ACCEPTED
        // "pending" rides should appear in nearby rides polling, not as active trips
        final acceptedStatuses = ['accepted', 'started', 'in_progress', 'ongoing', 'arrived', 'driver_arrived'];
        
        if (!acceptedStatuses.contains(status)) {
          print('⚠️ DRIVER - Ride status is "$status" - NOT an accepted trip');
          print('   This ride should appear in nearby rides polling instead');
          print('   Clearing state and letting nearby rides polling handle it');
          _rideAcceptedAt = null;
          context.read<DriverCubit>().completeTrip();
          return;
        }
        
        print('✅ DRIVER - Ride is ACCEPTED - will resume trip');
        
        // Check if ride is completed or cancelled
        if (status == 'completed' || status == 'cancelled') {
          print('❌ DRIVER - RIDE $status IN BACKEND - CLEARING STATE');
          _rideAcceptedAt = null; // Reset timestamp
          context.read<DriverCubit>().completeTrip();
          return;
        }
        
        // Restore ride data
        _rideId = rideId;
        print('🔄 DRIVER - RESTORED RIDE ID: $_rideId');
        
        // Restore locations from state
        if (driverState.pickupLat != null && driverState.pickupLng != null) {
          _pickupLocation = LatLng(driverState.pickupLat!, driverState.pickupLng!);
        }
        if (driverState.dropoffLat != null && driverState.dropoffLng != null) {
          _dropoffLocation = LatLng(driverState.dropoffLat!, driverState.dropoffLng!);
        }
        
        _pickupAddress = _extractAddress(driverState.pickupAddress);
        _dropoffAddress = _extractAddress(driverState.destination);
        
        // Use the centralized sync method to determine panel based on API status
        print('🚗 DRIVER - Backend status is $status - Syncing with cubit');
        // Preserve rideId when syncing
        final cubitState = context.read<DriverCubit>().state;
        final currentRideId = cubitState.rideId ?? _rideId;
        context.read<DriverCubit>().syncFromApiStatus(status, rideId: currentRideId);
        
        // CRITICAL: Hide ride request panel and clear any pending requests
        _rideRequestTimer?.cancel();
        _showRideRequestPanel = false;
        _showRideRequestPanelRestoration.value = false;
        
        print('🚫 DRIVER - Hiding ride request panel (trip resumed)');
        
        // Force UI update after status is determined
        if (mounted) {
          setState(() {});
        }
        
        print('🚗 DRIVER - Panel set based on API status: ${context.read<DriverCubit>().state.tripStage}');
        
        // Resume trip progress tracking
        _startTripProgressTracking();
        
        // Start status polling
        _startDriverRideStatusPolling();
        
        print('✅ DRIVER - TRIP RESUMED WITH CORRECT PANEL (tripStage=${context.read<DriverCubit>().state.tripStage})');
      } else {
        print('❌ DRIVER - FAILED TO GET BACKEND STATUS');
        // Don't clear state immediately after acceptance
        if (_rideAcceptedAt != null) {
          final timeSinceAcceptance = DateTime.now().difference(_rideAcceptedAt!).inSeconds;
          if (timeSinceAcceptance < 10) {
            print('⏰ DRIVER - API error but ride was just accepted. Keeping state.');
            return;
          }
        }
        // Clear state on error
        _rideAcceptedAt = null;
        context.read<DriverCubit>().completeTrip();
      }
    } catch (e) {
      print('❌ DRIVER - ERROR VERIFYING STATUS: $e');
      // Keep local state on network error
    }
  }
  
  // Keys for SharedPreferences
  static const String _keyShowRideRequest = 'show_ride_request_panel';
  static const String _keyRideId = 'ride_request_id';
  static const String _keyRiderName = 'ride_request_rider_name';
  static const String _keyRiderPhone = 'ride_request_rider_phone';
  static const String _keyPickupAddress = 'ride_request_pickup_address';
  static const String _keyDropoffAddress = 'ride_request_dropoff_address';
  static const String _keyEstimatedFare = 'ride_request_estimated_fare';
  static const String _keyDistanceToPickup = 'ride_request_distance_to_pickup';
  static const String _keyPickupLat = 'ride_request_pickup_lat';
  static const String _keyPickupLng = 'ride_request_pickup_lng';
  static const String _keyDropoffLat = 'ride_request_dropoff_lat';
  static const String _keyDropoffLng = 'ride_request_dropoff_lng';
  
  // Load persisted ride request state
  Future<void> _loadRideRequestState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final showRideRequest = prefs.getBool(_keyShowRideRequest) ?? false;
      
      if (showRideRequest && mounted) {
        final rideId = prefs.getString(_keyRideId) ?? '';
        final riderName = prefs.getString(_keyRiderName) ?? '';
        final riderPhone = prefs.getString(_keyRiderPhone) ?? '';
        final pickupAddress = prefs.getString(_keyPickupAddress) ?? '';
        final dropoffAddress = prefs.getString(_keyDropoffAddress) ?? '';
        final estimatedFare = prefs.getDouble(_keyEstimatedFare) ?? 0.0;
        final distanceToPickup = prefs.getDouble(_keyDistanceToPickup) ?? 0.0;
        final pickupLat = prefs.getDouble(_keyPickupLat);
        final pickupLng = prefs.getDouble(_keyPickupLng);
        final dropoffLat = prefs.getDouble(_keyDropoffLat);
        final dropoffLng = prefs.getDouble(_keyDropoffLng);
        
        setState(() {
          _rideId = rideId;
          _riderName = riderName;
          _riderPhone = riderPhone;
          _pickupAddress = pickupAddress;
          _dropoffAddress = dropoffAddress;
          _estimatedFare = estimatedFare;
          _distanceToPickup = distanceToPickup;
          if (pickupLat != null && pickupLng != null) {
            _pickupLocation = LatLng(pickupLat, pickupLng);
          }
          if (dropoffLat != null && dropoffLng != null) {
            _dropoffLocation = LatLng(dropoffLat, dropoffLng);
          }
          _showRideRequestPanel = true;
          _countdownSeconds = 30;
        });
        
        _slideController.forward();
        _rideRequestTimer?.cancel(); // Cancel any existing timer
        _startCountdownTimer();
      }
    } catch (e) {
      // Silent error handling
    }
  }
  
  // Save ride request state
  Future<void> _saveRideRequestState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowRideRequest, _showRideRequestPanel);
      await prefs.setString(_keyRideId, _rideId);
      await prefs.setString(_keyRiderName, _riderName);
      await prefs.setString(_keyRiderPhone, _riderPhone);
      await prefs.setString(_keyPickupAddress, _pickupAddress);
      await prefs.setString(_keyDropoffAddress, _dropoffAddress);
      await prefs.setDouble(_keyEstimatedFare, _estimatedFare);
      await prefs.setDouble(_keyDistanceToPickup, _distanceToPickup);
      if (_pickupLocation != null) {
        await prefs.setDouble(_keyPickupLat, _pickupLocation!.latitude);
        await prefs.setDouble(_keyPickupLng, _pickupLocation!.longitude);
      }
      if (_dropoffLocation != null) {
        await prefs.setDouble(_keyDropoffLat, _dropoffLocation!.latitude);
        await prefs.setDouble(_keyDropoffLng, _dropoffLocation!.longitude);
      }
    } catch (e) {
      // Silent error handling
    }
  }
  
  // Clear ride request state
  Future<void> _clearRideRequestState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyShowRideRequest);
      await prefs.remove(_keyRideId);
      await prefs.remove(_keyRiderName);
      await prefs.remove(_keyRiderPhone);
      await prefs.remove(_keyPickupAddress);
      await prefs.remove(_keyDropoffAddress);
      await prefs.remove(_keyEstimatedFare);
      await prefs.remove(_keyDistanceToPickup);
      await prefs.remove(_keyPickupLat);
      await prefs.remove(_keyPickupLng);
      await prefs.remove(_keyDropoffLat);
      await prefs.remove(_keyDropoffLng);
    } catch (e) {
      // Silent error handling
    }
  }
  
  Future<void> _fetchDriverEarnings() async {
    try {
      final response = await ApiService.getDriverEarnings();
      
      if (response['success'] == true && response['data'] != null) {
        // Handle potential double nesting
        final outerData = response['data'];
        final data = outerData['data'] ?? outerData;
        
        final today = data['today'] ?? {};
        final todayEarnings = today['earnings'] ?? {};
        
        if (mounted) {
          setState(() {
            _todayNetEarnings = (todayEarnings['net_amount'] ?? 0).toDouble();
            _todayRidesCount = today['rides_completed'] ?? 0;
            _currency = todayEarnings['currency'] ?? 'QAR';
          });
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  // Get driver's current GPS location
  Future<void> _getDriverLocation() async {
    debugPrint('\n📍📍📍 DRIVER - Getting driver location...');
    debugPrint('   BEFORE: _currentPosition = $_currentPosition');
    debugPrint('   BEFORE: _driverLocation = $_driverLocation');
    
    try {
      // Get current position
      debugPrint('   Calling LocationService.getCurrentPosition()...');
      final position = await LocationService.getCurrentPosition();
      debugPrint('   LocationService returned: $position');
      
      if (position == null) {
        debugPrint('❌❌❌ DRIVER - LocationService returned NULL!');
        debugPrint('   This means GPS permission may be denied or location services are off');
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
        }
        return;
      }
      
      debugPrint('✅ DRIVER - Location obtained: ${position.latitude}, ${position.longitude}');
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _driverLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        
        debugPrint('✅✅✅ DRIVER - Location variables SET!');
        debugPrint('   AFTER: _currentPosition = $_currentPosition');
        debugPrint('   AFTER: _driverLocation = $_driverLocation\n');
        
        // Move camera to driver's location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_driverLocation!, 16.0),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ DRIVER - EXCEPTION getting location:');
      debugPrint('   Error: $e');
      debugPrint('   Stack: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Calculate distance between two coordinates in kilometers
  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    ) / 1000; // Convert meters to kilometers
  }

  // Start tracking trip progress
  void _startTripProgressTracking() {
    final driverState = context.read<DriverCubit>().state;
    
    // Reset arrival flag when starting new trip tracking
    _hasShownPickupArrival = false;
    
    // Determine target location based on trip stage
    LatLng? targetLocation;
    if (driverState.tripStage == 'heading_to_destination') {
      targetLocation = _dropoffLocation;
    } else {
      targetLocation = _pickupLocation;
    }
    
    if (targetLocation == null || _driverLocation == null) return;
    
    // Set initial distance
    _initialDistanceToPickup = _calculateDistance(_driverLocation!, targetLocation);
    _currentDistanceToPickup = _initialDistanceToPickup;
    
    // Draw the route on map
    _drawRouteToTarget(targetLocation);
    
    // Calculate initial estimated time
    _calculateEstimatedTimeToTarget(targetLocation);
    
    // Update progress every 3 seconds
    _tripProgressTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _updateTripProgress();
    });
  }
  
  // Draw route to target (pickup or destination)
  void _drawRouteToTarget(LatLng target) {
    if (_driverLocation == null) return;
    
    setState(() {
      // Create route polyline
      _routePolylines = {
        Polyline(
          polylineId: const PolylineId('route_to_target'),
          points: [_driverLocation!, target],
          color: Colors.amber,
          width: 5,
          patterns: [PatternItem.dash(30), PatternItem.gap(20)],
        ),
      };
      
      // Add markers for driver and target
      _tripMarkers = {
        Marker(
          markerId: const MarkerId('driver_location'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
        Marker(
          markerId: const MarkerId('target_location'),
          position: target,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: context.read<DriverCubit>().state.tripStage == 'heading_to_destination' 
                ? 'Destination' 
                : 'Pickup Location',
            snippet: context.read<DriverCubit>().state.tripStage == 'heading_to_destination'
                ? _dropoffAddress 
                : _pickupAddress,
          ),
        ),
      };
    });
    
    // Adjust camera to show both markers
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              _driverLocation!.latitude < target.latitude 
                  ? _driverLocation!.latitude 
                  : target.latitude,
              _driverLocation!.longitude < target.longitude 
                  ? _driverLocation!.longitude 
                  : target.longitude,
            ),
            northeast: LatLng(
              _driverLocation!.latitude > target.latitude 
                  ? _driverLocation!.latitude 
                  : target.latitude,
              _driverLocation!.longitude > target.longitude 
                  ? _driverLocation!.longitude 
                  : target.longitude,
            ),
          ),
          100.0, // padding
        ),
      );
    }
  }
  
  // Calculate estimated time to target
  Future<void> _calculateEstimatedTimeToTarget(LatLng target) async {
    if (_driverLocation == null) return;
    
    try {
      final origin = '${_driverLocation!.latitude},${_driverLocation!.longitude}';
      final destination = '${target.latitude},${target.longitude}';
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json?'
        'origins=$origin&destinations=$destination&'
        'mode=driving&key=$_googleMapsApiKey'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && 
            data['rows'] != null && 
            data['rows'].isNotEmpty &&
            data['rows'][0]['elements'] != null &&
            data['rows'][0]['elements'].isNotEmpty) {
          
          final element = data['rows'][0]['elements'][0];
          
          if (element['status'] == 'OK') {
            final durationText = element['duration']['text'];
            
            setState(() {
              _estimatedTimeToPickup = durationText;
            });
            
            // Update in DriverCubit as well
            context.read<DriverCubit>().updateEstimatedTime(durationText);
          }
        }
      }
    } catch (e) {
      setState(() {
        _estimatedTimeToPickup = '-- min';
      });
    }
  }

  // Update trip progress based on current location
  Future<void> _updateTripProgress() async {
    final driverState = context.read<DriverCubit>().state;
    
    // CRITICAL: Only update progress if driver is still on a trip
    if (!driverState.isOnTrip) {
      print('⚠️ DRIVER - Skipping trip progress update: driver not on trip');
      _stopTripProgressTracking();
      return;
    }
    
    // Determine target location based on trip stage
    LatLng? targetLocation;
    if (driverState.tripStage == 'heading_to_destination') {
      targetLocation = _dropoffLocation;
    } else {
      targetLocation = _pickupLocation;
    }
    
    if (targetLocation == null) return;
    
    try {
      // Get current driver location
      final position = await LocationService.getCurrentPosition();
      if (position == null) return;
      
      final currentLocation = LatLng(position.latitude, position.longitude);
      
      // Calculate current distance to target
      _currentDistanceToPickup = _calculateDistance(currentLocation, targetLocation);
      
      // Calculate progress percentage
      double progress = 0.0;
      if (_initialDistanceToPickup > 0) {
        progress = (((_initialDistanceToPickup - _currentDistanceToPickup) / _initialDistanceToPickup) * 100)
            .clamp(0.0, 100.0);
      }
      
      // Update driver location on map
      if (mounted) {
        setState(() {
          _driverLocation = currentLocation;
          
          // Update route polyline with new driver location
          if (_routePolylines.isNotEmpty && targetLocation != null) {
            _routePolylines = {
              Polyline(
                polylineId: const PolylineId('route_to_target'),
                points: [currentLocation, targetLocation],
                color: Colors.amber,
                width: 5,
                patterns: [PatternItem.dash(30), PatternItem.gap(20)],
              ),
            };
            
            // Update driver marker
            _tripMarkers = _tripMarkers.map((marker) {
              if (marker.markerId.value == 'driver_location') {
                return marker.copyWith(positionParam: currentLocation);
              }
              return marker;
            }).toSet();
          }
        });
        
        // Update DriverCubit with real-time progress
        context.read<DriverCubit>().updateTripProgress(progress.toStringAsFixed(0));
        
        // Recalculate estimated time every 5 updates (every 15 seconds)
        _progressUpdateCounter++;
        if (_progressUpdateCounter >= 5) {
          _progressUpdateCounter = 0;
          _calculateEstimatedTimeToTarget(targetLocation);
        }
      }
      
      // Stop tracking if we're very close (within 50 meters)
      // CRITICAL: Only show arrival message if:
      // 1. Driver is still on trip
      // 2. Trip stage is "heading_to_pickup" (not destination)
      // 3. We haven't already shown this message
      if (_currentDistanceToPickup < 0.05 && 
          driverState.isOnTrip && 
          driverState.tripStage == 'heading_to_pickup') {
        _tripProgressTimer?.cancel();
        
        // Only show message once - use a flag to prevent multiple toasts
        if (mounted && !_hasShownPickupArrival) {
          _hasShownPickupArrival = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have arrived at the pickup location!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  // Stop tracking trip progress
  void _stopTripProgressTracking() {
    _tripProgressTimer?.cancel();
    _initialDistanceToPickup = 0.0;
    _currentDistanceToPickup = 0.0;
    _progressUpdateCounter = 0;
    _hasShownPickupArrival = false; // Reset flag when stopping tracking
    
    // Clear route and trip markers
    setState(() {
      _routePolylines.clear();
      _tripMarkers.clear();
      _estimatedTimeToPickup = '-- min';
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rideRequestTimer?.cancel();
    _nearbyRidesPollingTimer?.cancel();
    _tripProgressTimer?.cancel();
    _rideStatusPollingTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _slideController.dispose();
    _declineReasonController.dispose();
    _showRideRequestPanelRestoration.dispose();
    _rideIdRestoration.dispose();
    _riderNameRestoration.dispose();
    _pickupAddressRestoration.dispose();
    _dropoffAddressRestoration.dispose();
    _estimatedFareRestoration.dispose();
    _distanceToPickupRestoration.dispose();
    _pickupLatRestoration.dispose();
    _pickupLngRestoration.dispose();
    _dropoffLatRestoration.dispose();
    _dropoffLngRestoration.dispose();
    super.dispose();
  }
  
  // Helper method to extract address string from API response
  String _extractAddress(dynamic addressData) {
    if (addressData == null) return '';
    if (addressData is String) return addressData;
    if (addressData is Map) {
      // If it's a map, try to extract a formatted address string
      print('🗺️ DRIVER - Address is a Map, extracting string...');
      print('   Map data: $addressData');
      final extracted = addressData['formatted_address']?.toString() ?? 
             addressData['address']?.toString() ?? 
             addressData['name']?.toString() ?? 
             '';
      print('   Extracted: $extracted');
      return extracted;
    }
    return addressData.toString();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      print('📱 DRIVER - APP RESUMED - RE-VERIFYING BACKEND STATUS');
      
      // Check if driver has an active trip
      final driverState = context.read<DriverCubit>().state;
      if (driverState.isOnTrip && driverState.rideId != null) {
        // Re-verify backend status when app resumes
        _verifyAndResumeTrip(driverState);
      } else {
        print('✅ DRIVER - No active trip, continuing normal operation');
      }
    }
  }

  void _startNearbyRidesPolling() {
    print('🚀 DRIVER - Starting nearby rides polling (every 3 seconds)');
    
    // Poll for nearby rides every 3 seconds
    _nearbyRidesPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final driverState = context.read<DriverCubit>().state;
      
      print('🔄 NEARBY RIDES POLLING TICK:');
      print('   mounted: $mounted');
      print('   _driverLocation: $_driverLocation');
      print('   isOnline: ${driverState.isOnline}');
      print('   isOnTrip: ${driverState.isOnTrip}');
      
      // Only check for rides if driver is online AND not on an active trip
      if (mounted && _driverLocation != null && driverState.isOnline && !driverState.isOnTrip) {
        print('✅ NEARBY RIDES - Conditions met, calling _checkForNearbyRides()');
        await _checkForNearbyRides();
      } else {
        print('❌ NEARBY RIDES - Skipping (conditions not met)');
      }
    });
  }
  
  // Start updating driver location to backend
  void _startLocationUpdates() {
    print('🚗 DRIVER - Starting location updates to backend (every 5 seconds)');
    
    // Update location immediately
    _updateLocationToBackend();
    
    // Then update every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _updateLocationToBackend();
    });
  }
  
  // Update driver location to backend API
  Future<void> _updateLocationToBackend() async {
    final driverState = context.read<DriverCubit>().state;
    
    // Only update if driver is online and has location
    if (!driverState.isOnline || _driverLocation == null) {
      if (kDebugMode) {
        print('⏭️ DRIVER - Skipping location update: online=${driverState.isOnline}, location=${_driverLocation != null}');
      }
      return;
    }
    
    try {
      // Get current position for heading if available
      Position? position;
      double? heading;
      
      try {
        position = await LocationService.getCurrentPosition();
        if (position != null) {
          final headingValue = position.heading;
          if (headingValue != null && headingValue >= 0 && headingValue <= 360) {
            heading = headingValue;
          }
        }
      } catch (e) {
        // Heading not available, continue without it
        if (kDebugMode) {
          print('⚠️ DRIVER - Could not get heading: $e');
        }
      }
      
      // Determine availability: online and not on trip
      final isAvailable = driverState.isOnline && !driverState.isOnTrip;
      
      if (kDebugMode) {
        print('📤 DRIVER - Updating location to backend:');
        print('   Lat: ${_driverLocation!.latitude}, Lng: ${_driverLocation!.longitude}');
        print('   Heading: ${heading ?? "N/A"}');
        print('   Available: $isAvailable');
      }
      
      final response = await ApiService.updateDriverLocation(
        latitude: _driverLocation!.latitude,
        longitude: _driverLocation!.longitude,
        heading: heading,
        isAvailable: isAvailable,
      );
      
      if (kDebugMode) {
        if (response['success'] == true) {
          print('✅ DRIVER - Location updated successfully');
        } else {
          print('❌ DRIVER - Location update failed: ${response['error']}');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ DRIVER - Error updating location to backend: $e');
        print('   Stack trace: $stackTrace');
      }
    }
  }
  
  Future<void> _checkForNearbyRides() async {
    print('📡 NEARBY RIDES - _checkForNearbyRides() called');
    
    try {
      final driverState = context.read<DriverCubit>().state;
      
      // Only poll for nearby rides when driver is online AND not on an active trip
      if (!driverState.isOnline || driverState.isOnTrip) {
        print('❌ NEARBY RIDES - Skipping API call (offline or on trip)');
        return;
      }
      
      if (_driverLocation == null) {
        print('❌ NEARBY RIDES - Skipping API call (no driver location)');
        return;
      }
      
      // Calculate radius dynamically - start with 10km
      final radiusKm = 10.0;
      
      print('📞 NEARBY RIDES - Calling API getNearbyRides...');
      print('   Driver location: ${_driverLocation!.latitude}, ${_driverLocation!.longitude}');
      print('   Radius: $radiusKm km');
      
      final response = await ApiService.getNearbyRides(
        driverLat: _driverLocation!.latitude,
        driverLng: _driverLocation!.longitude,
        radiusKm: radiusKm,
        limit: 10,
      );
      
      print('📡 NEARBY RIDES - API Response:');
      print('   Success: ${response['success']}');
      print('   Full Response: $response');
      
      if (response['success'] && response['data'] != null) {
        // Handle potential double nesting
        final outerData = response['data'];
        final data = outerData['data'] ?? outerData;
        
        final rides = data['rides'] as List?;
        
        print('📊 NEARBY RIDES - Processing response:');
        print('   Rides found: ${rides?.length ?? 0}');
        if (rides != null && rides.isNotEmpty) {
          print('   First ride: ${rides[0]}');
        }
        print('   _showRideRequestPanel: $_showRideRequestPanel');
        print('   DriverCubit isOnTrip: ${context.read<DriverCubit>().state.isOnTrip}');
        
        // CRITICAL: If no rides found AND panel is showing, clear stale data!
        if ((rides == null || rides.isEmpty) && _showRideRequestPanel) {
          print('🧹 NEARBY RIDES - No rides found, clearing stale ride request panel');
          if (mounted) {
            setState(() {
              _showRideRequestPanel = false;
              _pendingRideId = '';
              _currentRideRequest = null;
              _rideRequestTimer?.cancel();
              _countdownSeconds = 30;
              
              // Clear restoration values
              _showRideRequestPanelRestoration.value = false;
              _rideIdRestoration.value = '';
              _riderNameRestoration.value = '';
              _pickupAddressRestoration.value = '';
              _dropoffAddressRestoration.value = '';
              _estimatedFareRestoration.value = 0.0;
              _distanceToPickupRestoration.value = 0.0;
            });
            _clearRideRequestState();
            print('✅ NEARBY RIDES - Stale panel cleared successfully');
          }
          return;
        }
        
        if (rides != null && rides.isNotEmpty) {
          print('✅ NEARBY RIDES - Found ${rides.length} rides, processing first one...');
          
          // Get the first ride
          final ride = rides[0];
          
          // CRITICAL: Check ride status to determine which panel to show
          final rideStatus = ride['status']?.toString().toLowerCase() ?? 'pending';
          final rideId = ride['id']?.toString() ?? '';
          print('📍 NEARBY RIDE - Status: $rideStatus, ID: $rideId');
          print('   Current _showRideRequestPanel: $_showRideRequestPanel');
          print('   Current isOnTrip: ${context.read<DriverCubit>().state.isOnTrip}');
          
          // Treat "requested" and "pending" as the same - both mean ride is available for driver to accept
          final isPendingRide = (rideStatus == 'pending' || rideStatus == 'requested');
          
          // If ride is already accepted/started, it should appear in driver-ride-status polling, not here
          // So only show ride REQUEST panel for pending/requested rides
          if (isPendingRide && !_showRideRequestPanel) {
            print('✅ NEARBY RIDE - Will show ride request panel (status: $rideStatus)');
            // Continue to show ride request panel (existing code below)
          } else if (isPendingRide && _showRideRequestPanel) {
            // Check if it's a DIFFERENT ride
            if (_pendingRideId != rideId) {
              print('🔄 NEARBY RIDE - NEW ride while panel showing (old: "$_pendingRideId", new: "$rideId")');
              print('   Will update panel with new ride details');
              // Continue to update the panel with new ride details
            } else {
              print('⚠️ NEARBY RIDE - Same ride request panel already showing, skipping');
              return;
            }
          } else if (!isPendingRide && rideStatus != 'unknown') {
            // Ride has been accepted/started - sync with DriverCubit to show trip panel
            print('🚗 NEARBY RIDE - Ride status is "$rideStatus" (accepted/started)');
            print('   Syncing with DriverCubit to show appropriate trip panel');
            
            // Store ride ID and sync status
            _rideId = rideId;
            // Preserve rideId when syncing
            context.read<DriverCubit>().syncFromApiStatus(rideStatus, rideId: rideId);
            
            // Start trip tracking
            final driverState = context.read<DriverCubit>().state;
            if (driverState.isOnTrip) {
              // Set trip details
              final passengerName = ride['rider_name'] ?? 'Passenger';
              
              print('🐛 DEBUG - Ride request rider name extraction:');
              print('   ride keys: ${ride.keys.toList()}');
              print('   rider_name: ${ride['rider_name']}');
              print('   Final passengerName: $passengerName');
              final pickupAddress = _extractAddress(ride['pickup_address']);
              final dropoffAddress = _extractAddress(ride['dropoff_address']);
              
              if (mounted) {
                setState(() {
                  _riderName = passengerName;
                  _pickupAddress = pickupAddress;
                  _dropoffAddress = dropoffAddress;
                });
              }
              
              // Start polling for this ride
              _startDriverRideStatusPolling();
              
              print('✅ NEARBY RIDE - Trip panel will be shown based on status: $rideStatus');
            }
            return; // Don't show ride request panel
          } else {
            print('⚠️ NEARBY RIDE - Unknown status or already showing panel, skipping');
            return;
          }
          
          print('✅ NEARBY RIDE - Proceeding to show ride request panel');
          print('   Parsing ride details...');
          
          // Parse pickup location from string format "(lat,lng)"
          final pickupLocationStr = ride['pickup_location'] as String;
          print('   Pickup location string: $pickupLocationStr');
          final pickupCoords = pickupLocationStr.replaceAll('(', '').replaceAll(')', '').split(',');
          final pickupLat = double.parse(pickupCoords[0]);
          final pickupLng = double.parse(pickupCoords[1]);
          
          // Calculate precise distance using Geolocator
          final distance = Geolocator.distanceBetween(
            _driverLocation!.latitude,
            _driverLocation!.longitude,
            pickupLat,
            pickupLng,
          ) / 1000; // Convert meters to kilometers
          
          // Parse dropoff location
          final dropoffLocationStr = ride['dropoff_location'] as String;
          final dropoffCoords = dropoffLocationStr.replaceAll('(', '').replaceAll(')', '').split(',');
          final dropoffLat = double.parse(dropoffCoords[0]);
          final dropoffLng = double.parse(dropoffCoords[1]);
          
      print('🎯 NEARBY RIDE - About to show panel via setState');
      if (mounted) {
        setState(() {
          _currentRideRequest = ride;
          _pendingRideId = ride['id'] ?? ''; // Use pending ID, NOT _rideId!
          print('📍 NEW RIDE REQUEST - Pending Ride ID: $_pendingRideId (Status: $rideStatus)');
          print('⚠️ CRITICAL: This is a PENDING ride request, NOT an active trip!');
          print('   _rideId is EMPTY (will only be set on accept): "$_rideId"');
          _riderName = ride['rider_name'] ?? 'Rider';
          
          print('🐛 DEBUG - New ride request rider name extraction:');
          print('   ride keys: ${ride.keys.toList()}');
          print('   rider_name: ${ride['rider_name']}');
          print('   Final _riderName: $_riderName');
          _riderPhone = ride['rider_phone'] ?? '';
          _pickupAddress = _extractAddress(ride['pickup_address']);
          _dropoffAddress = _extractAddress(ride['dropoff_address']);
          _estimatedFare = (ride['estimated_fare'] ?? 0).toDouble();
          _distanceToPickup = distance;
          _pickupLocation = LatLng(pickupLat, pickupLng);
          _dropoffLocation = LatLng(dropoffLat, dropoffLng);
          
          _showRideRequestPanel = true;
          _countdownSeconds = 30;
          
          print('✅ NEARBY RIDE - setState completed:');
          print('   _showRideRequestPanel: $_showRideRequestPanel');
          print('   _pendingRideId: $_pendingRideId');
          print('   _riderName: $_riderName');
          
          print('🛑 DRIVER - RIDE REQUEST PANEL SHOWN - Backend checks will be BLOCKED');
          print('   Driver MUST accept or reject manually!');
          
          // Update restoration values
          _showRideRequestPanelRestoration.value = true;
          _rideIdRestoration.value = _rideId;
          _riderNameRestoration.value = _riderName;
          _pickupAddressRestoration.value = _pickupAddress;
          _dropoffAddressRestoration.value = _dropoffAddress;
          _estimatedFareRestoration.value = _estimatedFare;
          _distanceToPickupRestoration.value = _distanceToPickup;
          _pickupLatRestoration.value = pickupLat;
          _pickupLngRestoration.value = pickupLng;
          _dropoffLatRestoration.value = dropoffLat;
          _dropoffLngRestoration.value = dropoffLng;
        });
        _slideController.forward();
        
        // Cancel any existing timer before starting a new one
        _rideRequestTimer?.cancel();
        _startCountdownTimer();
        _saveRideRequestState();
      }
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  void _startCountdownTimer() {
    print('⏰ STARTING COUNTDOWN TIMER - 30 seconds');
    print('   _pendingRideId at start: "$_pendingRideId"');
    _rideRequestTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdownSeconds--;
        });
        
        if (_countdownSeconds <= 0) {
          timer.cancel();
          print('⏰ COUNTDOWN EXPIRED - Auto-declining ride');
          print('   _pendingRideId: "$_pendingRideId"');
          
          // Only auto-decline if we have a valid pending ride ID
          if (_pendingRideId.isNotEmpty) {
            _rejectRide();
          } else {
            print('⚠️ COUNTDOWN - No valid ride to reject, just hiding panel');
            _hideRideRequestPanel();
          }
        }
      }
    });
  }

  void _hideRideRequestPanel() {
    _slideController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showRideRequestPanel = false;
          _showRideRequestPanelRestoration.value = false;
          _pendingRideId = ''; // Clear pending ride ID
          print('🧹 DRIVER - Cleared pending ride ID (panel hidden)');
        });
        _clearRideRequestState();
      }
    });
  }
  
  void _showDriverCancelRideDialog() {
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
                    // Title
                    Text(
                      'Cancel Ride?',
                      style: TextStyle(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Text(
                      'Please provide a reason for canceling',
                      style: TextStyle(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // Reason Text Field
                    TextField(
                      controller: _declineReasonController,
                      maxLines: 3,
                      style: TextStyle(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter cancellation reason...',
                        hintStyle: TextStyle(
                          color: themeState.textSecondary.withOpacity(0.6),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                        filled: true,
                        fillColor: themeState.fieldBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                          borderSide: BorderSide(color: themeState.fieldBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                          borderSide: BorderSide(color: themeState.fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                          borderSide: BorderSide(color: Colors.amber, width: 2),
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
                                color: themeState.fieldBorder,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                            ),
                            child: TextButton(
                              onPressed: () {
                                _declineReasonController.clear();
                                Navigator.of(dialogContext).pop();
                              },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                ),
                              ),
                              child: Text(
                                'Go Back',
                                style: TextStyle(
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
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                _performDriverCancelRide();
                              },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                                ),
                              ),
                              child: Text(
                                'Confirm',
                                style: TextStyle(
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
        );
      },
    );
  }
  
  Future<void> _performDriverCancelRide() async {
    // Use robust rideId retrieval helper
    final rideId = await _getRideId();
    
    if (rideId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Ride ID not found. Please try again or restart the app.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    final declineReason = _declineReasonController.text.trim();
    if (declineReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a cancellation reason'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    print('🚫 CANCELING RIDE - Ride ID: $rideId, Reason: $declineReason');
    
    try {
      final response = await ApiService.cancelRide(
        rideId: rideId,
        cancelledBy: 'driver',
        reason: declineReason,
      );
      
      if (response['success'] == true) {
        print('🚫 RIDE CANCELED SUCCESSFULLY - Ride ID: $rideId');
        // Stop trip tracking and polling
        _stopTripProgressTracking();
        _stopDriverRideStatusPolling();
        
        // Complete the trip in cubit
        _rideAcceptedAt = null; // Reset timestamp
        context.read<DriverCubit>().completeTrip();
        
        // Clear the text field
        _declineReasonController.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride cancelled successfully'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Extract error message
        String errorMsg = "Unknown error";
        if (response['error'] != null) {
          if (response['error'] is String) {
            errorMsg = response['error'];
          } else if (response['error'] is Map) {
            final errorMap = response['error'] as Map;
            errorMsg = errorMap['message']?.toString() ?? 
                      errorMap['error']?.toString() ?? 
                      errorMap['details']?.toString() ?? 
                      "Unknown error";
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel: $errorMsg'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // Start polling ride status for drivers
  void _startDriverRideStatusPolling() {
    // Don't start polling if driver isn't on a trip
    if (!context.read<DriverCubit>().state.isOnTrip) {
      print('⚠️ DRIVER - Cannot start polling: driver not on trip');
      return;
    }
    
    _rideStatusPollingTimer?.cancel();
    
    print('🔄 DRIVER - Starting ride status polling');
    print('   Will poll driver-ride-status with Ride ID: $_rideId');
    
    _rideStatusPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final driverState = context.read<DriverCubit>().state;
      
      if (!driverState.isOnTrip) {
        print('⚠️ DRIVER - Stopping polling: driver no longer on trip');
        _stopDriverRideStatusPolling();
        return;
      }
      
      try {
        // Pass ride_id to track specific ride lifecycle
        final response = await ApiService.getDriverRideStatus(
          rideId: _rideId.isNotEmpty ? _rideId : null,
        );
        
        print('📡 DRIVER POLLING - driver-ride-status API RESPONSE:');
        print('   Ride ID: $_rideId');
        print('   Success: ${response['success']}');
        print('   Full Response: $response');
        
        if (response['success']) {
          final data = response['data'];
          
          print('📊 DRIVER POLLING - Data structure:');
          print('   Data type: ${data.runtimeType}');
          print('   Data keys: ${data is Map ? data.keys.toList() : "not a map"}');
          
          // Handle double/triple nesting: response['data']['data']['ride']
          final actualData = data is Map && data.containsKey('data') ? data['data'] : data;
          final rideData = actualData is Map ? actualData['ride'] : null;
          
          print('📊 DRIVER POLLING - Actual data:');
          print('   Actual data keys: ${actualData is Map ? actualData.keys.toList() : "not a map"}');
          print('   Ride data exists: ${rideData != null}');
          if (rideData != null) {
            print('   Ride data: $rideData');
          }
          
          // If there's no ride object, no active trip
          if (rideData == null) {
            print('⚠️ DRIVER POLLING - Backend says no active ride');
            print('   Local state: isOnTrip=${driverState.isOnTrip}, rideId=${driverState.rideId}');
            print('   Local _rideId: $_rideId');
            
            // CRITICAL: If ride was just accepted (within 30 seconds), backend might be slow to sync - ignore
            // Also check if we're in the process of starting the ride (heading_to_pickup stage)
            if (_rideAcceptedAt != null) {
              final timeSinceAcceptance = DateTime.now().difference(_rideAcceptedAt!).inSeconds;
              if (timeSinceAcceptance < 30) {
                print('⏰ DRIVER - Ride was accepted $timeSinceAcceptance seconds ago, backend might be syncing. Keeping state.');
                return;
              }
            }
            
            // If we're in heading_to_pickup stage, the ride might not be fully synced yet
            // Give it more time before marking as completed
            if (driverState.tripStage == 'heading_to_pickup') {
              print('⏰ DRIVER - Still heading to pickup, backend might not have ride data yet. Keeping state.');
              return;
            }
            
            // Only clear state if we've been waiting a long time AND we're not in an active trip stage
            // This prevents premature completion when backend is slow
            if (_rideAcceptedAt != null) {
              final timeSinceAcceptance = DateTime.now().difference(_rideAcceptedAt!).inSeconds;
              if (timeSinceAcceptance < 60) {
                print('⏰ DRIVER - Ride was accepted $timeSinceAcceptance seconds ago, giving backend more time. Keeping state.');
                return;
              }
            }
            
            // If we've been in this state for a while and backend still says no active ride,
            // the ride was likely completed/cancelled on backend - clear local state
            print('❌ DRIVER - Backend consistently says no active ride after waiting - CLEARING LOCAL STATE');
            _rideAcceptedAt = null;
            _stopDriverRideStatusPolling();
            _stopTripProgressTracking();
            context.read<DriverCubit>().completeTrip();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trip ended by system'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }
          
          print('✅ DRIVER POLLING - Backend confirms active ride');
          
          // rideData was already extracted above, no need to get it again
          
          final status = rideData['status']?.toString().toLowerCase() ?? '';
          final pollingRideId = rideData['id']?.toString() ?? rideData['ride_id']?.toString() ?? '';
          
          print('📊 DRIVER POLLING - STATUS: $status');
          print('   Ride ID from API: $pollingRideId');
          print('   Local _rideId: $_rideId');
          print('   DriverCubit state rideId: ${driverState.rideId}');
          
          // CRITICAL: Always extract and preserve rideId from API response
          // BUT: Don't update to a completed/cancelled ride if we're currently on a trip
          // This prevents overwriting a new active ride ID with an old completed one
          if (pollingRideId.isNotEmpty) {
            // If the polled ride is completed/cancelled AND we're on a trip, 
            // it might be an old ride - only update if it matches our current rideId
            if ((status == 'completed' || status == 'cancelled') && 
                driverState.isOnTrip && 
                driverState.rideId != null && 
                driverState.rideId!.isNotEmpty &&
                pollingRideId != driverState.rideId) {
              print('⚠️ DRIVER POLLING - Ignoring completed/cancelled ride from polling (different ID)');
              print('   Current rideId: ${driverState.rideId}, Polled rideId: $pollingRideId');
              print('   This is likely an old completed ride, keeping current active ride');
            } else {
              // Update local _rideId if it's different
              if (_rideId != pollingRideId) {
                print('🔄 DRIVER POLLING - Updating local _rideId from API: $pollingRideId');
                _rideId = pollingRideId;
              }
              
              // Ensure DriverCubit state has the rideId
              if (driverState.rideId != pollingRideId) {
                print('🔄 DRIVER POLLING - Syncing rideId to DriverCubit state: $pollingRideId');
                // Use syncFromApiStatus to update with rideId
              }
            }
          }
          
          // Safeguard: If ride was just accepted (within 10 seconds), ignore 'started' status
          // This prevents premature stage transitions when backend updates too quickly
          var effectiveStatus = status;
          if (_rideAcceptedAt != null) {
            final timeSinceAcceptance = DateTime.now().difference(_rideAcceptedAt!).inSeconds;
            if (timeSinceAcceptance < 10 && 
                (status == 'started' || status == 'in_progress' || status == 'ongoing')) {
              print('⚠️ DRIVER POLLING - Backend says "$status" but ride was just accepted $timeSinceAcceptance seconds ago');
              print('   Overriding status to "accepted" to prevent premature stage transition');
              effectiveStatus = 'accepted';
            }
          }
          
          // Use the centralized sync method to update state based on API status
          final previousStage = driverState.tripStage;
          // CRITICAL: Always use rideId from API if available, otherwise preserve existing
          final currentRideId = pollingRideId.isNotEmpty ? pollingRideId : (driverState.rideId ?? _rideId);
          print('🔄 DRIVER POLLING - Syncing with rideId: $currentRideId');
          context.read<DriverCubit>().syncFromApiStatus(effectiveStatus, rideId: currentRideId);
          final newState = context.read<DriverCubit>().state;
          
          // Check if ride is completed or cancelled
          if (!newState.isOnTrip) {
            print('❌ DRIVER - RIDE ENDED - STOPPING POLLING');
            _rideAcceptedAt = null; // Reset timestamp
            _stopDriverRideStatusPolling();
            _stopTripProgressTracking();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ride ${status == 'completed' ? 'completed' : 'ended'}'),
                  backgroundColor: status == 'completed' ? Colors.green : Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }
          
          // Check if stage changed from pickup to destination
          if (previousStage == 'heading_to_pickup' && newState.tripStage == 'heading_to_destination') {
            print('🔄 DRIVER POLLING - Stage transition detected: pickup → destination');
            
            // Stop current trip progress tracking (to pickup)
            _stopTripProgressTracking();
            
            // Force UI update
            if (mounted) {
              setState(() {});
            }
            
            // Restart trip progress tracking (to destination)
            _startTripProgressTracking();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Heading to destination...'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            
            print('✅ DRIVER POLLING - Panel transition complete. New stage: ${newState.tripStage}');
          } else {
            print('✅ DRIVER POLLING - Maintaining stage: ${newState.tripStage}');
          }
        }
      } catch (e) {
        // Silent error handling, continue polling
      }
    });
  }
  
  void _stopDriverRideStatusPolling() {
    _rideStatusPollingTimer?.cancel();
    _rideStatusPollingTimer = null;
  }

  // Robust rideId retrieval helper - tries multiple sources with fallback
  Future<String> _getRideId() async {
    final driverState = context.read<DriverCubit>().state;
    
    // Try 1: DriverCubit state (most reliable after acceptance)
    if (driverState.rideId != null && driverState.rideId!.isNotEmpty) {
      // Sync to local variable for consistency
      if (_rideId != driverState.rideId) {
        _rideId = driverState.rideId!;
        print('🔄 DRIVER - Synced local _rideId from DriverCubit: $_rideId');
      }
      return driverState.rideId!;
    }
    
    // Try 2: Local _rideId variable
    if (_rideId.isNotEmpty) {
      // Sync to DriverCubit if it's missing there
      if (driverState.isOnTrip && driverState.rideId == null) {
        print('🔄 DRIVER - Syncing rideId to DriverCubit from local variable: $_rideId');
        context.read<DriverCubit>().startTrip(rideId: _rideId);
      }
      return _rideId;
    }
    
    // Try 3: Fetch from backend API as last resort
    print('⚠️ DRIVER - rideId not found locally, fetching from backend...');
    try {
      final rideStatusResponse = await ApiService.getDriverRideStatus();
      if (rideStatusResponse['success'] == true && rideStatusResponse['data'] != null) {
        final data = rideStatusResponse['data'];
        final actualData = data is Map && data.containsKey('data') ? data['data'] : data;
        final rideData = actualData is Map ? actualData['ride'] : null;
        
        if (rideData != null) {
          final fetchedRideId = rideData['id']?.toString() ?? rideData['ride_id']?.toString() ?? '';
          final fetchedStatus = rideData['status']?.toString().toLowerCase() ?? '';
          
          // CRITICAL: Don't use completed/cancelled rides if we're currently on a trip
          // This prevents using old completed ride IDs when a new ride has been accepted
          if (fetchedRideId.isNotEmpty) {
            if ((fetchedStatus == 'completed' || fetchedStatus == 'cancelled') && driverState.isOnTrip) {
              print('⚠️ DRIVER - Backend returned completed/cancelled ride, but driver is on trip - ignoring');
              print('   This likely means a new ride was accepted but backend still has old ride');
              return '';
            }
            
            print('✅ DRIVER - Fetched rideId from backend: $fetchedRideId (status: $fetchedStatus)');
            // Update both local and cubit state
            _rideId = fetchedRideId;
            if (driverState.isOnTrip) {
              context.read<DriverCubit>().startTrip(rideId: fetchedRideId);
            }
            return fetchedRideId;
          }
        }
      }
    } catch (e) {
      print('❌ DRIVER - Error fetching rideId from backend: $e');
    }
    
    // All sources failed
    print('❌ DRIVER - Could not retrieve rideId from any source');
    return '';
  }

  Future<void> _acceptRide() async {
    debugPrint('🚨🚨🚨 _acceptRide() METHOD STARTED 🚨🚨🚨');
    print('\n\n');
    print('═══════════════════════════════════════════════════════');
    print('🔵🔵🔵 ACCEPT RIDE BUTTON TAPPED! 🔵🔵🔵');
    print('═══════════════════════════════════════════════════════');
    print('🔵 ACCEPT BUTTON PRESSED!');
    print('   _pendingRideId: "$_pendingRideId"');
    print('   _rideId: "$_rideId"');
    print('   _isRespondingToRide: $_isRespondingToRide');
    print('   _pickupAddress: "$_pickupAddress" (type: ${_pickupAddress.runtimeType})');
    print('   _dropoffAddress: "$_dropoffAddress" (type: ${_dropoffAddress.runtimeType})');
    
    if (_pendingRideId.isEmpty || _isRespondingToRide) {
      print('❌ ACCEPT BLOCKED: pendingRideId empty or already responding');
      print('   _pendingRideId.isEmpty: ${_pendingRideId.isEmpty}');
      print('   _isRespondingToRide: $_isRespondingToRide');
      print('═══════════════════════════════════════════════════════\n\n');
      
      // Show error to user if pending ride ID is missing
      if (_pendingRideId.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request expired. Please wait for a new ride.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    print('✅ ACCEPTING RIDE - Pending Ride ID: $_pendingRideId');
    print('   Current _rideId (should be empty): "$_rideId"');
    print('📍 ACCEPT CALLED FROM: ${StackTrace.current}');
    
    setState(() {
      _isRespondingToRide = true;
    });
    
    try {
      // Parse estimated time to numeric minutes
      int estimatedMinutes = 5; // Default fallback
      if (_estimatedTimeToPickup.isNotEmpty && _estimatedTimeToPickup != '-- min') {
        final match = RegExp(r'(\d+)').firstMatch(_estimatedTimeToPickup);
        if (match != null) {
          estimatedMinutes = int.parse(match.group(1)!);
        }
      }
      
      // Get current location - use _currentPosition first, fallback to _driverLocation
      double? latitude = _currentPosition?.latitude ?? _driverLocation?.latitude;
      double? longitude = _currentPosition?.longitude ?? _driverLocation?.longitude;
      
      print('📍 DRIVER - Preparing ride response with location & ETA:');
      print('   _currentPosition: ${_currentPosition != null ? "Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}" : "NULL"}');
      print('   _driverLocation: ${_driverLocation != null ? "Lat: ${_driverLocation!.latitude}, Lng: ${_driverLocation!.longitude}" : "NULL"}');
      print('   Using: Lat: $latitude, Lng: $longitude');
      print('   Estimated Time to Pickup: $_estimatedTimeToPickup → $estimatedMinutes minutes');
      
      // Validate location before sending
      if (latitude == null || longitude == null) {
        throw Exception('Location not available. Please ensure GPS is enabled and try again.');
      }
      
      final response = await ApiService.rideResponse(
        rideId: _pendingRideId, // Use pending ID for API call
        action: 'accept',
        currentLatitude: latitude,
        currentLongitude: longitude,
        estimatedArrivalMinutes: estimatedMinutes,
      );
      
      print('📥 API Response Raw Type Check:');
      print('   response type: ${response.runtimeType}');
      print('   response[\'success\'] type: ${response['success'].runtimeType}');
      if (response['data'] != null) {
        print('   response[\'data\'] type: ${response['data'].runtimeType}');
      }
      
      if (response['success'] == true) {
        print('✅ RIDE ACCEPTED SUCCESSFULLY - Ride ID: $_pendingRideId');
        
        // CRITICAL: Clear any old ride ID before setting the new one
        // This prevents using old completed ride IDs after logout/login
        print('🧹 DRIVER - Clearing old ride ID before accepting new ride');
        print('   Old _rideId: "$_rideId"');
        print('   Old DriverCubit rideId: ${context.read<DriverCubit>().state.rideId}');
        
        // CRITICAL: Set rideId in BOTH local variable AND DriverCubit state immediately
        // This ensures rideId is preserved even after logout/login cycles
        _rideId = _pendingRideId;
        print('✅ DRIVER - _rideId NOW SET TO: "$_rideId" (ride accepted)');
        print('   This ride ID will be used for driver-ride-status polling');
        
        // Track acceptance time to prevent premature state clearing
        _rideAcceptedAt = DateTime.now();
        print('⏰ DRIVER - Ride accepted at: $_rideAcceptedAt');
        
        // Hide the panel
    _hideRideRequestPanel();
        
        // DEBUG: Check types before calling startTrip
        print('🔍 DEBUG - BEFORE startTrip() call:');
        print('   _pickupAddress type: ${_pickupAddress.runtimeType}');
        print('   _pickupAddress value: $_pickupAddress');
        print('   _dropoffAddress type: ${_dropoffAddress.runtimeType}');
        print('   _dropoffAddress value: $_dropoffAddress');
        print('   _riderName type: ${_riderName.runtimeType}');
        print('   _riderName value: $_riderName');
        
        // Extract addresses safely
        final extractedPickupAddress = _extractAddress(_pickupAddress);
        final extractedDropoffAddress = _extractAddress(_dropoffAddress);
        
        print('🔍 DEBUG - AFTER _extractAddress() calls:');
        print('   extractedPickupAddress type: ${extractedPickupAddress.runtimeType}');
        print('   extractedPickupAddress value: $extractedPickupAddress');
        print('   extractedDropoffAddress type: ${extractedDropoffAddress.runtimeType}');
        print('   extractedDropoffAddress value: $extractedDropoffAddress');
        
        // Start trip using DriverCubit with ride details and locations
        // CRITICAL: Pass rideId to ensure it's stored in DriverCubit state
        print('🔍 DEBUG - Calling startTrip() now...');
        print('   _rideId value: "$_rideId"');
        print('   _rideId isEmpty: ${_rideId.isEmpty}');
        
        if (_rideId.isEmpty) {
          print('❌ ERROR - _rideId is empty before calling startTrip()!');
          print('   This should not happen - ride was just accepted');
        }
        
        try {
          context.read<DriverCubit>().startTrip(
            passengerName: _riderName,
            destination: extractedDropoffAddress,
            distance: '${_distanceToPickup.toStringAsFixed(1)} km',
            pickupLat: _pickupLocation?.latitude,
            pickupLng: _pickupLocation?.longitude,
            dropoffLat: _dropoffLocation?.latitude,
            dropoffLng: _dropoffLocation?.longitude,
            pickupAddress: extractedPickupAddress,
            rideId: _rideId, // CRITICAL: Store ride ID in DriverCubit state immediately
          );
          print('✅ DEBUG - startTrip() completed successfully');
          print('   DriverCubit state rideId after startTrip: ${context.read<DriverCubit>().state.rideId}');
          
          // Verify rideId is stored correctly
          final stateAfterStart = context.read<DriverCubit>().state;
          if (stateAfterStart.rideId != _rideId) {
            print('⚠️ WARNING - rideId mismatch after startTrip!');
            print('   Expected: $_rideId');
            print('   Got: ${stateAfterStart.rideId}');
            // Force update if mismatch
            context.read<DriverCubit>().startTrip(rideId: _rideId);
          } else {
            print('✅ VERIFIED - rideId correctly stored in DriverCubit state');
          }
        } catch (e, stackTrace) {
          print('❌ DEBUG - ERROR in startTrip():');
          print('   Error: $e');
          print('   Stack trace: $stackTrace');
          rethrow;
        }
        
        print('✅ DRIVER - DriverCubit.startTrip() called - isOnTrip should now be TRUE');
        print('   Current DriverCubit state: ${context.read<DriverCubit>().state.isOnTrip}');
        
        // Start tracking trip progress with real-time location updates
        _startTripProgressTracking();
        
        // Move camera to driver's location with rider's zoom level after accepting ride
        if (_mapController != null && _driverLocation != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_driverLocation!, 16.5),
          );
        }
        
        // Delay status polling longer to allow backend to update and prevent immediate stage transition
        // The backend needs time to process the acceptance before we start polling
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _startDriverRideStatusPolling();
            print('🔄 DRIVER - Started status polling after acceptance delay');
          }
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride accepted! Navigating to pickup location...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message - extract from Map if needed
        String errorMessage = 'Failed to accept ride. Please try again.';
        if (response['error'] != null) {
          if (response['error'] is String) {
            errorMessage = response['error'];
          } else if (response['error'] is Map) {
            // Extract message from error Map
            final errorMap = response['error'] as Map;
            errorMessage = errorMap['message']?.toString() ?? 
                          errorMap['error']?.toString() ?? 
                          errorMap['details']?.toString() ?? 
                          'Failed to accept ride. Please try again.';
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('\n\n❌❌❌ CRITICAL ERROR IN _acceptRide() ❌❌❌');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace:');
      print(stackTrace);
      print('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌\n\n');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRespondingToRide = false;
        });
      }
    }
  }

  Future<void> _rejectRide() async {
    print('🔴 REJECT BUTTON PRESSED!');
    print('   _pendingRideId: "$_pendingRideId"');
    print('   _rideId: "$_rideId"');
    print('   _isRespondingToRide: $_isRespondingToRide');
    
    if (_pendingRideId.isEmpty || _isRespondingToRide) {
      print('❌ REJECT BLOCKED: pendingRideId empty or already responding');
      return;
    }
    
    print('❌ REJECTING RIDE - Pending Ride ID: $_pendingRideId');
    print('   _rideId remains empty (ride not accepted): "$_rideId"');
    
    setState(() {
      _isRespondingToRide = true;
    });
    
    try {
      final response = await ApiService.rideResponse(
        rideId: _pendingRideId, // Use pending ID for API call
        action: 'decline',
      );
      
      if (response['success'] == true) {
        print('✅ RIDE REJECTED - Clearing pending ID');
        _pendingRideId = ''; // Clear pending ID after rejection
        print('❌ RIDE REJECTED SUCCESSFULLY - Ride ID: $_rideId');
        
        // Hide the panel
    _hideRideRequestPanel();
        
        // Show message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride declined'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message - extract from Map if needed
        String errorMessage = 'Failed to decline ride. Please try again.';
        if (response['error'] != null) {
          if (response['error'] is String) {
            errorMessage = response['error'];
          } else if (response['error'] is Map) {
            // Extract message from error Map
            final errorMap = response['error'] as Map;
            errorMessage = errorMap['message']?.toString() ?? 
                          errorMap['error']?.toString() ?? 
                          errorMap['details']?.toString() ?? 
                          'Failed to decline ride. Please try again.';
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRespondingToRide = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocListener<DriverCubit, DriverState>(
          listener: (context, driverState) {
            // Dismiss ride request panel when driver goes offline
            if (!driverState.isOnline && _showRideRequestPanel) {
              print('📴 DRIVER WENT OFFLINE - Dismissing ride request panel');
              _hideRideRequestPanel();
              _rideRequestTimer?.cancel();
            }
          },
          child: BlocBuilder<DriverCubit, DriverState>(
            builder: (context, driverState) {
              print('🎨 DRIVER UI - BUILD: isOnTrip=${driverState.isOnTrip}, tripStage=${driverState.tripStage}, rideId=${driverState.rideId}');
              print('🎨 DRIVER UI - _showRideRequestPanel=$_showRideRequestPanel, isOnline=${driverState.isOnline}');
              
              return Scaffold(
                backgroundColor: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.grey.shade100,
                body: Stack(
                  children: [
                    // Map
                    _buildMap(themeState, driverState),
                    
                    // Top App Bar
                    _buildTopAppBar(themeState, driverState),
                    
                    // Bottom Panel (only show when NOT on trip)
                    if (!driverState.isOnTrip) ...[
                      () {
                        print('🎨 DRIVER UI - RENDERING: Bottom Panel (not on trip)');
                        return _buildBottomPanel(themeState, driverState);
                      }(),
                    ],
                    
                    // Ride Request Panel (only show if online AND not on trip)
                    if (_showRideRequestPanel && driverState.isOnline && !driverState.isOnTrip) ...[
                      () {
                        print('🎨 DRIVER UI - RENDERING: Ride Request Panel');
                        return _buildRideRequestPanel(themeState);
                      }(),
                    ],
                  
                  // Trip Panel
                  if (driverState.isOnTrip) ...[
                    () {
                      print('🎨 DRIVER UI - RENDERING: Trip Panel (${driverState.tripStage})');
                      return _buildTripPanel(themeState, driverState);
                    }(),
                  ],
                  
                  // Location Button (positioned lower for visibility)
                  _buildLocationButton(themeState, driverState),
                ],
              ),
              bottomNavigationBar: driverState.isOnTrip ? null : _buildBottomNavigationBar(themeState, driverState),
            );
          },
        ),
        );
      },
    );
  }

  Widget _buildMap(ThemeState themeState, DriverState driverState) {
    // Use actual driver location or fallback to Qatar (Doha) coordinates
    final LatLng mapCenter = _driverLocation ?? const LatLng(25.2854, 51.5310);
    
    // Determine which markers to show
    Set<Marker> mapMarkers;
    if (_tripMarkers.isNotEmpty) {
      // Show trip markers (driver + pickup) when on trip
      mapMarkers = _tripMarkers;
    } else if (_driverLocation != null) {
      // Show only driver marker when not on trip
      // Color changes based on online/offline status: green when online, red when offline
      final markerHue = driverState.isOnline 
          ? BitmapDescriptor.hueGreen 
          : BitmapDescriptor.hueRed;
      
      mapMarkers = {
        Marker(
          markerId: const MarkerId('driver_location'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
        ),
      };
    } else {
      mapMarkers = {};
    }
    
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: mapCenter,
        zoom: _driverLocation == null ? 11.0 : 16.0, // Show Qatar overview while loading, zoom in when location is ready (matching rider)
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        // If location is already loaded, animate to it
        if (_driverLocation != null) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_driverLocation!, 16.0),
          );
        }
      },
      markers: mapMarkers,
      polylines: _routePolylines, // Show route when on trip
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // Disable built-in button, use custom one
      style: themeState.isDarkTheme ? _darkMapStyle : null,
    );
  }

  Widget _buildTopAppBar(ThemeState themeState, DriverState driverState) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
        child: Row(
          children: [
            // Hamburger Menu
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
              height: ResponsiveHelper.getResponsiveSpacing(context, 40),
              decoration: BoxDecoration(
                color: themeState.panelBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu,
                color: themeState.textPrimary,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ),
            
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            
            // Online Status
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
              ),
              decoration: BoxDecoration(
                color: themeState.panelBg,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                    decoration: BoxDecoration(
                      color: driverState.isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                  Text(
                    driverState.isOnline ? 'You are Online' : 'You are Offline',
                    style: TextStyle(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Profile Picture - Person Icon
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
              height: ResponsiveHelper.getResponsiveSpacing(context, 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeState.fieldBg,
                border: Border.all(
                  color: themeState.fieldBorder,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person,
                color: themeState.textPrimary,
                size: ResponsiveHelper.getResponsiveIconSize(context, 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton(ThemeState themeState, DriverState driverState) {
    // Calculate bottom position based on whether on trip and bottom nav bar
    // When on trip, the panel includes: progress section (~80px), pickup info (~80px), 
    // passenger info (~100px), button (~60px), bottom nav (~80px), and padding (~20px)
    // Total approximate trip panel height: ~420px
    final tripPanelHeight = driverState.isOnTrip 
        ? ResponsiveHelper.getResponsiveSpacing(context, 420) // Trip panel height when visible (includes bottom nav)
        : 0.0;
    
    final bottomNavHeight = driverState.isOnTrip 
        ? 0.0 // Bottom nav is included in trip panel height
        : ResponsiveHelper.getResponsiveSpacing(context, 80); // Approximate bottom nav height when not on trip
    final bottomPanelHeight = driverState.isOnTrip 
        ? 0.0 
        : ResponsiveHelper.getResponsiveSpacing(context, 280); // Approximate bottom panel height when not on trip
    
    return Positioned(
      right: ResponsiveHelper.getResponsiveSpacing(context, 16),
      bottom: driverState.isOnTrip 
          ? tripPanelHeight + ResponsiveHelper.getResponsiveSpacing(context, 80) // Above trip panel when on trip (moved up)
          : bottomPanelHeight + bottomNavHeight + ResponsiveHelper.getResponsiveSpacing(context, 80), // Above bottom panel when not on trip (moved up)
      child: SafeArea(
        child: Container(
          width: ResponsiveHelper.getResponsiveSpacing(context, 48),
          height: ResponsiveHelper.getResponsiveSpacing(context, 48),
          decoration: BoxDecoration(
            color: driverState.isOnline ? Colors.green : Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                if (_driverLocation != null && _mapController != null) {
                  await _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_driverLocation!, 16.0),
                  );
                } else {
                  // If location not available, try to get it
                  await _getDriverLocation();
                  if (_driverLocation != null && _mapController != null) {
                    await _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(_driverLocation!, 16.0),
                    );
                  }
                }
              },
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveSpacing(context, 24),
              ),
              child: Icon(
                Icons.my_location,
                color: Colors.white,
                size: ResponsiveHelper.getResponsiveIconSize(context, 24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(ThemeState themeState, DriverState driverState) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Slide to Go Offline
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveHelper.getResponsiveSpacing(context, 20),
                bottom: ResponsiveHelper.getResponsiveSpacing(context, 16),
              ),
              child: Text(
                driverState.isOnline ? 'Slide to Go Offline' : 'Swipe to Go Online',
                style: TextStyle(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            // Slide to Go Offline Button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
              ),
              child: _OptimizedSlider(
                isOnline: driverState.isOnline,
                slidePosition: driverState.slidePosition,
                isSliding: driverState.isSliding,
                onSlidingStart: () => context.read<DriverCubit>().setSliding(true),
                onSlidingUpdate: (position) => context.read<DriverCubit>().setSlidePosition(position),
                onSlidingEnd: (position, velocity) async {
                  context.read<DriverCubit>().setSliding(false);
                  final containerWidth = MediaQuery.of(context).size.width - 
                      ResponsiveHelper.getResponsiveSpacing(context, 40);
                  final buttonWidth = ResponsiveHelper.getResponsiveSpacing(context, 52);
                  final maxSlide = containerWidth - buttonWidth - 8.0;
                  final threshold = maxSlide * 0.7;
                  
                  if (driverState.isOnline) {
                    if (position > threshold || (velocity > 500 && position > maxSlide * 0.5)) {
                      final result = await context.read<DriverCubit>().goOffline();
                      if (result['success'] != true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to go offline. Please try again.'),
                          ),
                        );
                      }
                    } else {
                      context.read<DriverCubit>().setSlidePosition(0.0);
                    }
                  } else {
                    if (position < (maxSlide * 0.3) || (velocity < -500 && position < maxSlide * 0.5)) {
                      final result = await context.read<DriverCubit>().goOnline();
                      if (result['success'] != true && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to go online. Please try again.'),
                          ),
                        );
                      }
                    } else {
                      context.read<DriverCubit>().setSlidePosition(maxSlide);
                    }
                  }
                },
                themeState: themeState,
              ),
            ),
            
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
            
            // Stats Cards
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatsCard(
                      'Today\'s Earnings',
                      '$_currency ${_todayNetEarnings.toStringAsFixed(2)}',
                      themeState,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: _buildStatsCard(
                      'Today\'s Rides',
                      '$_todayRidesCount',
                      themeState,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String value, ThemeState themeState) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
          Text(
            value,
            style: TextStyle(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(ThemeState themeState, DriverState driverState) {
    return Container(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveSpacing(context, 20),
        top: ResponsiveHelper.getResponsiveSpacing(context, 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _bottomNavItems.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> item = entry.value;
          bool isSelected = index == driverState.currentBottomNavIndex;
          
          return InkWell(
            onTap: () {
              context.read<DriverCubit>().setBottomNavIndex(index);
              
              // Handle navigation based on selected tab
              if (index == 1) {
                // Navigate to Earnings screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverEarningsScreen()),
                ).then((_) {
                  // Reset to home tab when returning
                  context.read<DriverCubit>().setBottomNavIndex(0);
                });
              } else if (index == 2) {
                // Navigate to Profile screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
                ).then((_) {
                  // Reset to home tab when returning
                  context.read<DriverCubit>().setBottomNavIndex(0);
                });
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item['icon'],
                  color: isSelected ? Colors.amber : themeState.textSecondary,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                Text(
                  item['label'],
                  style: TextStyle(
                    color: isSelected ? Colors.amber : themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRideRequestPanel(ThemeState themeState) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5), // Semi-transparent overlay
        child: SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(
                left: ResponsiveHelper.getResponsiveSpacing(context, 16),
                right: ResponsiveHelper.getResponsiveSpacing(context, 16),
                bottom: ResponsiveHelper.getResponsiveSpacing(context, 100), // Above bottom nav
              ),
              decoration: BoxDecoration(
                color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                    child: Row(
                      children: [
                        Text(
                          'New Ride Request',
                          style: TextStyle(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        // Countdown Timer
                        Container(
                          width: ResponsiveHelper.getResponsiveSpacing(context, 50),
                          height: ResponsiveHelper.getResponsiveSpacing(context, 50),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
                          ),
                          child: Stack(
                            children: [
                              // Progress indicator with border
                              Center(
                                child: SizedBox(
                                  width: ResponsiveHelper.getResponsiveSpacing(context, 42),
                                  height: ResponsiveHelper.getResponsiveSpacing(context, 42),
                                  child: CircularProgressIndicator(
                                    value: _countdownSeconds / 30,
                                    strokeWidth: 4,
                                    backgroundColor: Colors.amber.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '$_countdownSeconds',
                                  style: TextStyle(
                                    color: themeState.textPrimary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Ride Summary Card
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                    ),
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme ? const Color(0xFF132036) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                    ),
                    child: Row(
                      children: [
                        // Est. Fare
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Est. Fare',
                                style: TextStyle(
                                  color: themeState.textSecondary,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                              Text(
                                'QAR ${_estimatedFare.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Divider
                        Container(
                          height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                          width: 1,
                          color: themeState.textSecondary.withOpacity(0.3),
                        ),
                        
                        // Distance
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Distance',
                                style: TextStyle(
                                  color: themeState.textSecondary,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                              Text(
                                '${_distanceToPickup.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  color: themeState.textPrimary,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Divider
                        Container(
                          height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                          width: 1,
                          color: themeState.textSecondary.withOpacity(0.3),
                        ),
                        
                        // Duration
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Duration',
                                style: TextStyle(
                                  color: themeState.textSecondary,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                              Text(
                                '15 min',
                                style: TextStyle(
                                  color: themeState.textPrimary,
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  // Pickup and Drop-off Details
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                    ),
                    child: Column(
                      children: [
                        // Pickup
                        Row(
                          children: [
                            Container(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 12),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 12),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PICKUP',
                                    style: TextStyle(
                                      color: themeState.textSecondary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                                  Text(
                                    _pickupAddress.isNotEmpty ? _pickupAddress : 'Pickup Location',
                                    style: TextStyle(
                                      color: themeState.textPrimary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        
                        // Drop-off
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: themeState.textSecondary,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DROP-OFF',
                                    style: TextStyle(
                                      color: themeState.textSecondary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                                  Text(
                                    _dropoffAddress.isNotEmpty ? _dropoffAddress : 'Dropoff Location',
                                    style: TextStyle(
                                      color: themeState.textPrimary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  
                  // Action Buttons
                  Padding(
                    padding: EdgeInsets.only(
                      left: ResponsiveHelper.getResponsiveSpacing(context, 20),
                      right: ResponsiveHelper.getResponsiveSpacing(context, 20),
                      bottom: ResponsiveHelper.getResponsiveSpacing(context, 20),
                    ),
                    child: Row(
                      children: [
                        // Reject Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isRespondingToRide ? null : _rejectRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeState.isDarkTheme ? const Color(0xFF132036) : Colors.grey.shade200,
                              foregroundColor: themeState.textPrimary,
                              padding: EdgeInsets.symmetric(
                                vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child: Text(
                              'Reject',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        
                        // Accept Ride Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isRespondingToRide ? null : () async {
                              debugPrint('\n\n');
                              debugPrint('🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢');
                              debugPrint('ACCEPT BUTTON TAPPED!!!');
                              debugPrint('🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢');
                              debugPrint('_currentPosition: $_currentPosition');
                              debugPrint('_driverLocation: $_driverLocation');
                              debugPrint('_pendingRideId: "$_pendingRideId"');
                              debugPrint('🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢🟢\n\n');
                              
                              // Get fresh location before accepting
                              await _getDriverLocation();
                              debugPrint('After refresh: _currentPosition: $_currentPosition, _driverLocation: $_driverLocation');
                              
                              _acceptRide();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: Colors.grey.shade300,
                            ),
                            child: _isRespondingToRide
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                    ),
                                  )
                                : Text(
                              'Accept Ride',
                              style: TextStyle(
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

  Widget _buildTripPanel(ThemeState themeState, DriverState driverState) {
    // Show different panel based on trip stage
    if (driverState.tripStage == 'heading_to_destination') {
      return _buildTripToDestinationPanel(themeState, driverState);
    }
    // Default to pickup panel
    return _buildTripToPickupPanel(themeState, driverState);
  }
  
  Widget _buildTripToPickupPanel(ThemeState themeState, DriverState driverState) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trip Progress
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Trip to Pickup Rider',
                        style: TextStyle(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${driverState.tripProgress}%',
                        style: TextStyle(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  // Progress Bar
                  Container(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 4)),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: int.parse(driverState.tripProgress) / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 4)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Drop-off Information
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
              ),
              child: Row(
                children: [
                  // Destination Icon
                  Container(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.flag,
                      color: Colors.amber,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  
                  // Destination Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PICKUP LOCATION',
                          style: TextStyle(
                            color: themeState.textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                        Text(
                          driverState.pickupAddress.isNotEmpty 
                              ? driverState.pickupAddress 
                              : driverState.destination,
                          style: TextStyle(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Time and Distance
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        driverState.estimatedTime,
                        style: TextStyle(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      Text(
                        driverState.distance,
                        style: TextStyle(
                          color: themeState.textSecondary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Passenger Information
            Container(
              margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20)),
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
              decoration: BoxDecoration(
                color: themeState.isDarkTheme ? const Color(0xFF16213E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
              child: Row(
                children: [
                  // Passenger Avatar
                  Container(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 50),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  
                  // Passenger Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverState.passengerName,
                          style: TextStyle(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                            Text(
                              driverState.passengerRating,
                              style: TextStyle(
                                color: themeState.textPrimary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  Row(
                    children: [
                      // Chat Button
                      GestureDetector(
                        onTap: () async {
                          final driverState = context.read<DriverCubit>().state;
                          
                          // Use robust rideId retrieval helper
                          final rideId = await _getRideId();
                          
                          if (rideId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ride ID not found. Cannot open chat.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                driverName: driverState.passengerName.isNotEmpty 
                                    ? driverState.passengerName 
                                    : 'Rider',
                                driverAvatar: '', // Add riderAvatar to DriverState if needed
                                rideId: rideId,
                                userType: 'driver', // NEW: Identify this as driver using the chat
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                          height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                          decoration: BoxDecoration(
                            color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: themeState.textPrimary,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      
                      // Call Button
                      Container(
                        width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        decoration: BoxDecoration(
                          color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.call,
                          color: themeState.textPrimary,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Rider Picked Up Button
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final driverState = context.read<DriverCubit>().state;
                  
                  // Use robust rideId retrieval helper
                  final rideId = await _getRideId();
                  
                  print('DEBUG: driverState.rideId = ${driverState.rideId}');
                  print('DEBUG: _rideId = $_rideId');
                  print('DEBUG: final rideId = $rideId');
                  
                  if (rideId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: Ride ID not found. Driver state rideId: ${driverState.rideId}, Local _rideId: $_rideId'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 4),
                      ),
                    );
                    return;
                  }
                  
                  try {
                    print('🚗 STARTING RIDE (Rider Picked Up) - Ride ID: $rideId');
                    
                    // CRITICAL: Temporarily stop status polling to prevent race conditions
                    // The polling might be getting stale "completed" status from previous rides
                    _stopDriverRideStatusPolling();
                    print('⏸️ DRIVER - Stopped status polling before startRide call');
                    
                    // Verify current ride status before attempting to start
                    try {
                      final statusCheck = await ApiService.getDriverRideStatus(rideId: rideId);
                      if (statusCheck['success'] == true) {
                        final statusData = statusCheck['data'];
                        final actualData = statusData is Map && statusData.containsKey('data') ? statusData['data'] : statusData;
                        final rideData = actualData is Map ? actualData['ride'] : null;
                        
                        if (rideData != null) {
                          final currentStatus = rideData['status']?.toString().toLowerCase() ?? '';
                          print('📊 DRIVER - Current ride status before startRide: $currentStatus');
                          
                          // If status is already completed, don't proceed
                          if (currentStatus == 'completed' || currentStatus == 'cancelled') {
                            print('❌ DRIVER - Ride is already $currentStatus, cannot start');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cannot start ride: Ride is already $currentStatus'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                            // Restart polling
                            _startDriverRideStatusPolling();
                            return;
                          }
                        }
                      }
                    } catch (e) {
                      print('⚠️ DRIVER - Could not verify ride status before startRide: $e');
                      // Continue anyway - the startRide API will validate
                    }
                    
                    // Call start-ride API
                    final response = await ApiService.startRide(rideId: rideId);
                    
                    if (response['success'] == true) {
                      print('🚗 RIDE STARTED SUCCESSFULLY - Ride ID: $rideId');
                      
                      // Stop current trip progress tracking (to pickup)
                      _stopTripProgressTracking();
                      
                      // Transition to heading to destination phase
                      context.read<DriverCubit>().startHeadingToDestination();
                      
                      // Update local state to reflect "started" status
                      context.read<DriverCubit>().syncFromApiStatus('started', rideId: rideId);
                      
                      // Restart trip progress tracking (to destination)
                      _startTripProgressTracking();
                      
                      // Restart status polling with a small delay to allow backend to update
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted && context.read<DriverCubit>().state.isOnTrip) {
                          _startDriverRideStatusPolling();
                          print('🔄 DRIVER - Restarted status polling after startRide');
                        }
                      });
                      
                      // Show confirmation
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rider picked up! Heading to destination...'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      // Extract error message
                      String errorMsg = "Unknown error";
                      if (response['error'] != null) {
                        if (response['error'] is String) {
                          errorMsg = response['error'];
                        } else if (response['error'] is Map) {
                          final errorMap = response['error'] as Map;
                          errorMsg = errorMap['message']?.toString() ?? 
                                    errorMap['error']?.toString() ?? 
                                    errorMap['details']?.toString() ?? 
                                    "Unknown error";
                        }
                      }
                      
                      print('❌ DRIVER - startRide API failed: $errorMsg');
                      
                      // Restart polling if it failed
                      if (mounted && context.read<DriverCubit>().state.isOnTrip) {
                        _startDriverRideStatusPolling();
                      }
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to start ride: $errorMsg'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  } catch (e, stackTrace) {
                    print('❌ DRIVER - Exception in startRide: $e');
                    print('   Stack: $stackTrace');
                    
                    // Restart polling on error
                    if (mounted && context.read<DriverCubit>().state.isOnTrip) {
                      _startDriverRideStatusPolling();
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'RIDER PICKED UP',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Cancel Ride Button
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
              ),
              child: ElevatedButton(
                onPressed: () => _showDriverCancelRideDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'CANCEL RIDE',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNavigationBar(themeState, driverState),
            
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTripToDestinationPanel(ThemeState themeState, DriverState driverState) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trip Progress
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Trip to Destination',
                        style: TextStyle(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${driverState.tripProgress}%',
                        style: TextStyle(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  // Progress Bar
                  Container(
                    width: double.infinity,
                    height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 4)),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: int.parse(driverState.tripProgress) / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 4)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Destination Information
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
              ),
              child: Row(
                children: [
                  // Destination Icon
                  Container(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.amber,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  
                  // Destination Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DESTINATION',
                          style: TextStyle(
                            color: themeState.textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                        Text(
                          driverState.destination,
                          style: TextStyle(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Time and Distance
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        driverState.estimatedTime,
                        style: TextStyle(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                      Text(
                        driverState.distance,
                        style: TextStyle(
                          color: themeState.textSecondary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Passenger Information
            Container(
              margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20)),
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
              decoration: BoxDecoration(
                color: themeState.isDarkTheme ? const Color(0xFF16213E) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              ),
              child: Row(
                children: [
                  // Passenger Avatar
                  Container(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 50),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop&crop=face'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  
                  // Passenger Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverState.passengerName,
                          style: TextStyle(
                            color: themeState.textPrimary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                            Text(
                              driverState.passengerRating,
                              style: TextStyle(
                                color: themeState.textPrimary,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  Row(
                    children: [
                      // Chat Button
                      GestureDetector(
                        onTap: () async {
                          final driverState = context.read<DriverCubit>().state;
                          // Use robust rideId retrieval helper
                          final rideId = await _getRideId();
                          
                          if (rideId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ride ID not found. Cannot open chat.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                driverName: driverState.passengerName.isNotEmpty 
                                    ? driverState.passengerName 
                                    : 'Rider',
                                driverAvatar: '', // Add riderAvatar to DriverState if needed
                                rideId: rideId,
                                userType: 'driver', // NEW: Identify this as driver using the chat
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                          height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                          decoration: BoxDecoration(
                            color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: themeState.textPrimary,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      
                      // Call Button
                      Container(
                        width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                        decoration: BoxDecoration(
                          color: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.call,
                          color: themeState.textPrimary,
                          size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Open Google Maps Button
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final driverState = context.read<DriverCubit>().state;
                  
                  // Get destination coordinates
                  double? destLat = driverState.dropoffLat;
                  double? destLng = driverState.dropoffLng;
                  
                  // Fallback to stored location if state doesn't have it
                  if (destLat == null || destLng == null) {
                    destLat = _dropoffLocation?.latitude;
                    destLng = _dropoffLocation?.longitude;
                  }
                  
                  if (destLat == null || destLng == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Destination location not available'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  
                  // Create Google Maps URL with directions
                  final googleMapsUrl = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving'
                  );
                  
                  try {
                    if (await canLaunchUrl(googleMapsUrl)) {
                      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open Google Maps'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error opening Google Maps: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  Icons.directions,
                  color: Colors.white,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                ),
                label: Text(
                  'Open Directions in Google Maps',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            
            // Complete Trip Button
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  // Use robust rideId retrieval helper
                  final rideId = await _getRideId();
                  
                  if (rideId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Ride ID not found'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  
                  try {
                    print('🏁 COMPLETING RIDE - Ride ID: $rideId');
                    
                    // Call complete-ride API
                    final response = await ApiService.completeRide(rideId: rideId);
                    
                    if (response['success'] == true) {
                      print('🏁 RIDE COMPLETED SUCCESSFULLY - Ride ID: $rideId');
                      
                      // Stop tracking trip progress and polling
                  _stopTripProgressTracking();
                      _stopDriverRideStatusPolling();
                  
                  // Complete the trip in the cubit
                  _rideAcceptedAt = null; // Reset timestamp
                  context.read<DriverCubit>().completeTrip();
                  
                  // Show confirmation
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip completed successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                      }
                    } else {
                      // Extract error message
                      String errorMsg = "Unknown error";
                      if (response['error'] != null) {
                        if (response['error'] is String) {
                          errorMsg = response['error'];
                        } else if (response['error'] is Map) {
                          final errorMap = response['error'] as Map;
                          errorMsg = errorMap['message']?.toString() ?? 
                                    errorMap['error']?.toString() ?? 
                                    errorMap['details']?.toString() ?? 
                                    "Unknown error";
                        }
                      }
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to complete trip: $errorMsg'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'COMPLETE TRIP',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Bottom Navigation
            _buildBottomNavigationBar(themeState, driverState),
            
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
          ],
        ),
      ),
    );
  }
}

// Optimized slider widget for smooth dragging
class _OptimizedSlider extends StatefulWidget {
  final bool isOnline;
  final double slidePosition;
  final bool isSliding;
  final VoidCallback onSlidingStart;
  final ValueChanged<double> onSlidingUpdate;
  final ValueChanged2<double, double> onSlidingEnd; // position, velocity
  final ThemeState themeState;

  const _OptimizedSlider({
    required this.isOnline,
    required this.slidePosition,
    required this.isSliding,
    required this.onSlidingStart,
    required this.onSlidingUpdate,
    required this.onSlidingEnd,
    required this.themeState,
  });

  @override
  State<_OptimizedSlider> createState() => _OptimizedSliderState();
}

class _OptimizedSliderState extends State<_OptimizedSlider>
    with SingleTickerProviderStateMixin {
  double _localPosition = 0.0;
  bool _isDragging = false;
  double _dragStartPosition = 0.0;
  late AnimationController _animationController;
  late Animation<double> _springAnimation;
  double _lastVelocity = 0.0;
  DateTime _lastUpdateTime = DateTime.now();
  double _lastPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _localPosition = widget.slidePosition;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _springAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.addListener(_onAnimationUpdate);
  }

  @override
  void didUpdateWidget(_OptimizedSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update local position if not dragging and position changed externally
    if (!_isDragging && oldWidget.slidePosition != widget.slidePosition) {
      _localPosition = widget.slidePosition;
      _animateToPosition(widget.slidePosition);
    }
  }

  void _onAnimationUpdate() {
    if (!_isDragging && mounted) {
      setState(() {
        _localPosition = _springAnimation.value;
      });
    }
  }

  void _animateToPosition(double targetPosition) {
    final containerWidth = MediaQuery.of(context).size.width -
        ResponsiveHelper.getResponsiveSpacing(context, 40);
    final buttonWidth = ResponsiveHelper.getResponsiveSpacing(context, 52);
    final maxSlide = containerWidth - buttonWidth - 8.0;
    final clampedTarget = targetPosition.clamp(0.0, maxSlide);

    _springAnimation = Tween<double>(
      begin: _localPosition,
      end: clampedTarget,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward(from: 0.0);
  }

  void _calculateVelocity(double currentPosition) {
    final now = DateTime.now();
    final timeDelta = now.difference(_lastUpdateTime).inMilliseconds;
    if (timeDelta > 0) {
      final positionDelta = currentPosition - _lastPosition;
      _lastVelocity = (positionDelta / timeDelta) * 1000; // pixels per second
    }
    _lastUpdateTime = now;
    _lastPosition = currentPosition;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width -
        ResponsiveHelper.getResponsiveSpacing(context, 40);
    final buttonWidth = ResponsiveHelper.getResponsiveSpacing(context, 52);
    final maxSlide = containerWidth - buttonWidth - 8.0;

    // Use local position during drag, widget position otherwise
    final displayPosition = (_isDragging ? _localPosition : widget.slidePosition)
        .clamp(0.0, maxSlide);

    return Container(
      width: double.infinity,
      height: ResponsiveHelper.getResponsiveSpacing(context, 60),
      decoration: BoxDecoration(
        color: widget.themeState.isDarkTheme
            ? const Color(0xFF16213E)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 30)),
      ),
      child: Stack(
        children: [
          // Background content
          Positioned.fill(
            child: Center(
              child: Text(
                widget.isOnline ? 'Slide to Go Offline' : 'Swipe to Go Online',
                style: TextStyle(
                  color: widget.themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Sliding button
          Positioned(
            left: 4.0 + displayPosition,
            top: 4.0,
            child: GestureDetector(
              onHorizontalDragStart: (details) {
                _isDragging = true;
                _dragStartPosition = widget.slidePosition;
                _localPosition = widget.slidePosition;
                _lastUpdateTime = DateTime.now();
                _lastPosition = widget.slidePosition;
                _lastVelocity = 0.0;
                _animationController.stop();
                widget.onSlidingStart();
              },
              onHorizontalDragUpdate: (details) {
                if (_isDragging) {
                  final newPosition =
                      (_localPosition + details.delta.dx).clamp(0.0, maxSlide);
                  setState(() {
                    _localPosition = newPosition;
                  });
                  _calculateVelocity(newPosition);
                  // Throttle cubit updates to reduce rebuilds
                  if ((newPosition - _dragStartPosition).abs() > 2.0) {
                    widget.onSlidingUpdate(newPosition);
                    _dragStartPosition = newPosition;
                  }
                }
              },
              onHorizontalDragEnd: (details) {
                if (_isDragging) {
                  _isDragging = false;
                  final finalPosition = _localPosition.clamp(0.0, maxSlide);
                  widget.onSlidingEnd(finalPosition, _lastVelocity);
                }
              },
              onHorizontalDragCancel: () {
                if (_isDragging) {
                  _isDragging = false;
                  final finalPosition = _localPosition.clamp(0.0, maxSlide);
                  widget.onSlidingEnd(finalPosition, _lastVelocity);
                }
              },
              child: Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 52),
                height: ResponsiveHelper.getResponsiveSpacing(context, 52),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_car,
                  color: widget.themeState.textPrimary,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper typedef for callback with two parameters
typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

