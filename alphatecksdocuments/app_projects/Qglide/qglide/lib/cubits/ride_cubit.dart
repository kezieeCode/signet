import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Ride Status Enum
enum RideStatus {
  none,
  searching,
  driverFound,
  driverArrived,
  rideStarted,
  rideCompleted,
}

// Ride State
class RideState {
  final RideStatus status;
  final String pickupLocation;
  final String destinationLocation;
  final String driverName;
  final String driverCar;
  final String driverRating;
  final String estimatedArrival;
  final String fare;
  final String tripProgress;
  final bool isRideStarted;
  final LatLng? driverLocation;
  final Map<String, dynamic> rideDetails;
  final String? rideId; // Add ride ID for tracking
  final String? apiStatus; // Actual API status string from backend for accurate sync

  const RideState({
    this.status = RideStatus.none,
    this.pickupLocation = '',
    this.destinationLocation = '',
    this.driverName = '',
    this.driverCar = '',
    this.driverRating = '',
    this.estimatedArrival = '',
    this.fare = '',
    this.tripProgress = '0%',
    this.isRideStarted = false,
    this.driverLocation,
    this.rideDetails = const {},
    this.rideId,
    this.apiStatus,
  });

  RideState copyWith({
    RideStatus? status,
    String? pickupLocation,
    String? destinationLocation,
    String? driverName,
    String? driverCar,
    String? driverRating,
    String? estimatedArrival,
    String? fare,
    String? tripProgress,
    bool? isRideStarted,
    LatLng? driverLocation,
    Map<String, dynamic>? rideDetails,
    String? rideId,
    String? apiStatus,
  }) {
    return RideState(
      status: status ?? this.status,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      driverName: driverName ?? this.driverName,
      driverCar: driverCar ?? this.driverCar,
      driverRating: driverRating ?? this.driverRating,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      fare: fare ?? this.fare,
      tripProgress: tripProgress ?? this.tripProgress,
      isRideStarted: isRideStarted ?? this.isRideStarted,
      driverLocation: driverLocation ?? this.driverLocation,
      rideDetails: rideDetails ?? this.rideDetails,
      rideId: rideId ?? this.rideId,
      apiStatus: apiStatus ?? this.apiStatus,
    );
  }
  
  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'pickupLocation': pickupLocation,
      'destinationLocation': destinationLocation,
      'driverName': driverName,
      'driverCar': driverCar,
      'driverRating': driverRating,
      'estimatedArrival': estimatedArrival,
      'fare': fare,
      'tripProgress': tripProgress,
      'isRideStarted': isRideStarted,
      'driverLocationLat': driverLocation?.latitude,
      'driverLocationLng': driverLocation?.longitude,
      'rideDetails': rideDetails,
      'rideId': rideId,
      'apiStatus': apiStatus,
    };
  }
  
  // Create from JSON
  factory RideState.fromJson(Map<String, dynamic> json) {
    LatLng? driverLoc;
    if (json['driverLocationLat'] != null && json['driverLocationLng'] != null) {
      driverLoc = LatLng(json['driverLocationLat'], json['driverLocationLng']);
    }
    
    return RideState(
      status: RideStatus.values[json['status'] ?? 0],
      pickupLocation: json['pickupLocation'] ?? '',
      destinationLocation: json['destinationLocation'] ?? '',
      driverName: json['driverName'] ?? '',
      driverCar: json['driverCar'] ?? '',
      driverRating: json['driverRating'] ?? '',
      estimatedArrival: json['estimatedArrival'] ?? '',
      fare: json['fare'] ?? '',
      tripProgress: json['tripProgress'] ?? '0%',
      isRideStarted: json['isRideStarted'] ?? false,
      driverLocation: driverLoc,
      rideDetails: Map<String, dynamic>.from(json['rideDetails'] ?? {}),
      rideId: json['rideId'],
      apiStatus: json['apiStatus'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RideState &&
        other.status == status &&
        other.pickupLocation == pickupLocation &&
        other.destinationLocation == destinationLocation &&
        other.driverName == driverName &&
        other.driverCar == driverCar &&
        other.driverRating == driverRating &&
        other.estimatedArrival == estimatedArrival &&
        other.fare == fare &&
        other.tripProgress == tripProgress &&
        other.isRideStarted == isRideStarted;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      pickupLocation,
      destinationLocation,
      driverName,
      driverCar,
      driverRating,
      estimatedArrival,
      fare,
      tripProgress,
      isRideStarted,
    );
  }
}

// Ride Cubit - with automatic persistence
class RideCubit extends HydratedCubit<RideState> {
  RideCubit() : super(const RideState());

  void startRideSearch({
    required String pickup,
    required String destination,
    String? rideId,
  }) {
    emit(state.copyWith(
      status: RideStatus.searching,
      pickupLocation: pickup,
      destinationLocation: destination,
      rideId: rideId,
    ));
  }

  void driverFound({
    required String driverName,
    required String driverCar,
    required String driverRating,
    required String estimatedArrival,
    required LatLng driverLocation,
  }) {
    emit(state.copyWith(
      status: RideStatus.driverFound,
      driverName: driverName,
      driverCar: driverCar,
      driverRating: driverRating,
      estimatedArrival: estimatedArrival,
      driverLocation: driverLocation,
      apiStatus: 'accepted', // Set API status
    ));
  }

  void driverArrived() {
    emit(state.copyWith(
      status: RideStatus.driverArrived,
      apiStatus: 'arrived', // Set API status
    ));
  }

  void rideStarted() {
    emit(state.copyWith(
      status: RideStatus.rideStarted,
      isRideStarted: true,
      apiStatus: 'started', // Set API status
    ));
  }

  void rideCompleted() {
    // Reset to none status to clear storage, just like cancelRide
    emit(const RideState(status: RideStatus.none));
  }

  void cancelRide() {    // Emit a state with none status to trigger storage clearing
    emit(const RideState(status: RideStatus.none));
    // The toJson will return null for 'none' status, clearing storage
  }

  void updateDriverLocation(LatLng location) {
    emit(state.copyWith(driverLocation: location));
  }

  void updateFare(String fare) {
    emit(state.copyWith(fare: fare));
  }

  void updateTripProgress(String progress) {
    emit(state.copyWith(tripProgress: progress));
  }

  void updateEstimatedArrival(String eta) {
    emit(state.copyWith(estimatedArrival: eta));
  }

  void updateRideDetails(Map<String, dynamic> details) {
    emit(state.copyWith(rideDetails: details));
  }
  
  /// Synchronize state from API status - THE SINGLE SOURCE OF TRUTH
  /// This method maps API status to the correct RideStatus
  void syncFromApiStatus(String apiStatus) {
    final normalizedStatus = apiStatus.trim().toLowerCase();
    print('🔄 RIDE_CUBIT - syncFromApiStatus called with: $normalizedStatus');
    print('   Current state: status=${state.status}, apiStatus=${state.apiStatus}');
    
    // Map API status to RideStatus
    // accepted/driver_assigned/confirmed/driver_found/assigned = driverFound
    // arrived/driver_arrived = driverArrived
    // started/in_progress = rideStarted
    // completed/finished = rideCompleted
    // cancelled/driver_cancelled = none
    
    if (normalizedStatus == 'completed' || 
        normalizedStatus == 'finished' ||
        normalizedStatus == 'trip_completed' ||
        normalizedStatus == 'ride_completed' ||
        normalizedStatus == 'ended' ||
        normalizedStatus == 'done') {
      print('✅ RIDE_CUBIT - Ride completed (status: $normalizedStatus)');
      rideCompleted();
    } else if (normalizedStatus == 'cancelled' || 
               normalizedStatus == 'driver_cancelled') {
      print('❌ RIDE_CUBIT - Ride cancelled');
      cancelRide();
    } else if (normalizedStatus == 'accepted' || 
               normalizedStatus == 'driver_assigned' ||
               normalizedStatus == 'confirmed' ||
               normalizedStatus == 'in_progress' ||
               normalizedStatus == 'driver_found' ||
               normalizedStatus == 'assigned' ||
               normalizedStatus == 'pending') {
      print('🚗 RIDE_CUBIT - Status: $normalizedStatus → driverFound');
      // Only update if we need to change status
      if (state.status != RideStatus.driverFound) {
        emit(state.copyWith(
          status: RideStatus.driverFound,
          apiStatus: normalizedStatus,
        ));
        print('✅ RIDE_CUBIT - Updated to driverFound');
      } else if (state.apiStatus != normalizedStatus) {
        // Just update apiStatus for tracking
        emit(state.copyWith(apiStatus: normalizedStatus));
      }
    } else if (normalizedStatus == 'arrived' || normalizedStatus == 'driver_arrived') {
      print('🚗 RIDE_CUBIT - Status: $normalizedStatus → driverArrived');
      // Only update if we need to change status
      if (state.status != RideStatus.driverArrived) {
        emit(state.copyWith(
          status: RideStatus.driverArrived,
          apiStatus: normalizedStatus,
        ));
        print('✅ RIDE_CUBIT - Updated to driverArrived');
      } else if (state.apiStatus != normalizedStatus) {
        // Just update apiStatus for tracking
        emit(state.copyWith(apiStatus: normalizedStatus));
      }
    } else if (normalizedStatus == 'started' || normalizedStatus == 'ongoing') {
      print('🚗 RIDE_CUBIT - Status: $normalizedStatus → rideStarted');
      // Only update if we need to change status
      if (state.status != RideStatus.rideStarted) {
        emit(state.copyWith(
          status: RideStatus.rideStarted,
          isRideStarted: true,
          apiStatus: normalizedStatus,
        ));
        print('✅ RIDE_CUBIT - Updated to rideStarted');
      } else if (state.apiStatus != normalizedStatus) {
        // Just update apiStatus for tracking
        emit(state.copyWith(apiStatus: normalizedStatus));
      }
    } else {
      print('⚠️ RIDE_CUBIT - Unknown status: $normalizedStatus - keeping current state');
      // Just update the apiStatus field for tracking
      if (state.apiStatus != normalizedStatus) {
        emit(state.copyWith(apiStatus: normalizedStatus));
      }
    }
    
    print('   New state: status=${state.status}, apiStatus=${state.apiStatus}');
  }
  
  @override
  RideState? fromJson(Map<String, dynamic> json) {
    try {
      print('🔄 RIDE_CUBIT - fromJson called with: $json');
      final state = RideState.fromJson(json);
      print('🔄 RIDE_CUBIT - Parsed state:');
      print('   status: ${state.status}');
      print('   rideId: ${state.rideId}');
      print('   apiStatus: ${state.apiStatus}');
      print('   pickupLocation: ${state.pickupLocation}');
      print('   destinationLocation: ${state.destinationLocation}');
      print('   driverName: ${state.driverName}');
      
      // Only restore if ride has driver assigned (not searching, completed, or none)
      // Don't restore 'searching' to prevent showing stale "connecting to driver" after cancellation
      if (state.status != RideStatus.none && 
          state.status != RideStatus.rideCompleted &&
          state.status != RideStatus.searching) {
        print('✅ RIDE_CUBIT - RESTORING STATE: ${state.status} (rideId: ${state.rideId})');
        return state;
      }
      print('❌ RIDE_CUBIT - NOT RESTORING (status: ${state.status})');
      return null;
    } catch (e) {
      print('❌ RIDE_CUBIT - fromJson ERROR: $e');
      print('   Stack trace: ${StackTrace.current}');
      return null;
    }
  }
  
  @override
  Map<String, dynamic>? toJson(RideState state) {
    try {
      print('💾 RIDE_CUBIT - toJson called with status: ${state.status}');
      
      // Only save if ride is active (has driver assigned or ride in progress)
      // Don't persist 'searching' status to avoid persisting cancelled searches
      if (state.status == RideStatus.none || 
          state.status == RideStatus.rideCompleted ||
          state.status == RideStatus.searching) {
        print('💾 RIDE_CUBIT - CLEARING STORAGE (status: ${state.status})');
        return null; // Clear storage
      }
      print('💾 RIDE_CUBIT - SAVING STATE to storage');
      return state.toJson();
    } catch (e) {
      print('❌ RIDE_CUBIT - toJson ERROR: $e');
      return null;
    }
  }
}
