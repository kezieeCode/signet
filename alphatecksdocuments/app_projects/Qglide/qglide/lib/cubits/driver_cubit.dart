import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../services/api_service.dart';

// Driver State
class DriverState {
  final bool isOnline;
  final double slidePosition;
  final bool isSliding;
  final String todayEarnings;
  final String todayRides;
  final int currentBottomNavIndex;
  final bool isOnTrip;
  final String tripProgress;
  final String passengerName;
  final String passengerRating;
  final String destination;
  final String estimatedTime;
  final String distance;
  // Trip location coordinates for persistence
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String pickupAddress;
  // Trip stage to differentiate between pickup and destination phases
  final String tripStage; // 'none', 'heading_to_pickup', 'heading_to_destination'
  final String? rideId; // Store ride ID for API calls
  final String? apiStatus; // Actual API status string from backend for accurate sync

  const DriverState({
    this.isOnline = true,
    this.slidePosition = 0.0,
    this.isSliding = false,
    this.todayEarnings = 'QAR 345.50',
    this.todayRides = '12',
    this.currentBottomNavIndex = 0,
    this.isOnTrip = false,
    this.tripProgress = '0',
    this.passengerName = 'Fatima Al-Thani',
    this.passengerRating = '4.9',
    this.destination = 'The Pearl-Qatar, Doha',
    this.estimatedTime = '8 min',
    this.distance = '2.1 km',
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.pickupAddress = '',
    this.tripStage = 'none',
    this.rideId,
    this.apiStatus,
  });

  DriverState copyWith({
    bool? isOnline,
    double? slidePosition,
    bool? isSliding,
    String? todayEarnings,
    String? todayRides,
    int? currentBottomNavIndex,
    bool? isOnTrip,
    String? tripProgress,
    String? passengerName,
    String? passengerRating,
    String? destination,
    String? estimatedTime,
    String? distance,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? pickupAddress,
    String? tripStage,
    String? rideId,
    String? apiStatus,
  }) {
    return DriverState(
      isOnline: isOnline ?? this.isOnline,
      slidePosition: slidePosition ?? this.slidePosition,
      isSliding: isSliding ?? this.isSliding,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayRides: todayRides ?? this.todayRides,
      currentBottomNavIndex: currentBottomNavIndex ?? this.currentBottomNavIndex,
      isOnTrip: isOnTrip ?? this.isOnTrip,
      tripProgress: tripProgress ?? this.tripProgress,
      passengerName: passengerName ?? this.passengerName,
      passengerRating: passengerRating ?? this.passengerRating,
      destination: destination ?? this.destination,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      distance: distance ?? this.distance,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      tripStage: tripStage ?? this.tripStage,
      // Only update rideId if provided and not empty, otherwise keep existing value
      rideId: (rideId != null && rideId.isNotEmpty) ? rideId : this.rideId,
      apiStatus: apiStatus ?? this.apiStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverState &&
        other.isOnline == isOnline &&
        other.slidePosition == slidePosition &&
        other.isSliding == isSliding &&
        other.todayEarnings == todayEarnings &&
        other.todayRides == todayRides &&
        other.currentBottomNavIndex == currentBottomNavIndex &&
        other.isOnTrip == isOnTrip &&
        other.tripProgress == tripProgress &&
        other.passengerName == passengerName &&
        other.passengerRating == passengerRating &&
        other.destination == destination &&
        other.estimatedTime == estimatedTime &&
        other.distance == distance &&
        other.pickupLat == pickupLat &&
        other.pickupLng == pickupLng &&
        other.dropoffLat == dropoffLat &&
        other.dropoffLng == dropoffLng &&
        other.pickupAddress == pickupAddress &&
        other.tripStage == tripStage &&
        other.rideId == rideId &&
        other.apiStatus == apiStatus;
  }

  @override
  int get hashCode {
    return Object.hash(
      isOnline,
      slidePosition,
      isSliding,
      todayEarnings,
      todayRides,
      currentBottomNavIndex,
      isOnTrip,
      tripProgress,
      passengerName,
      passengerRating,
      destination,
      estimatedTime,
      distance,
      Object.hash(pickupLat, pickupLng, dropoffLat, dropoffLng, pickupAddress, tripStage, rideId, apiStatus),
    );
  }
  
  // Serialization for persistence
  Map<String, dynamic> toJson() {
    return {
      'isOnline': isOnline,
      'slidePosition': slidePosition,
      'isSliding': isSliding,
      'todayEarnings': todayEarnings,
      'todayRides': todayRides,
      'currentBottomNavIndex': currentBottomNavIndex,
      'isOnTrip': isOnTrip,
      'tripProgress': tripProgress,
      'passengerName': passengerName,
      'passengerRating': passengerRating,
      'destination': destination,
      'estimatedTime': estimatedTime,
      'distance': distance,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'pickupAddress': pickupAddress,
      'tripStage': tripStage,
      'rideId': rideId,
      'apiStatus': apiStatus,
    };
  }
  
  factory DriverState.fromJson(Map<String, dynamic> json) {
    return DriverState(
      isOnline: json['isOnline'] as bool? ?? true,
      slidePosition: (json['slidePosition'] as num?)?.toDouble() ?? 0.0,
      isSliding: json['isSliding'] as bool? ?? false,
      todayEarnings: json['todayEarnings'] as String? ?? 'QAR 345.50',
      todayRides: json['todayRides'] as String? ?? '12',
      currentBottomNavIndex: json['currentBottomNavIndex'] as int? ?? 0,
      isOnTrip: json['isOnTrip'] as bool? ?? false,
      tripProgress: json['tripProgress'] as String? ?? '0',
      passengerName: json['passengerName'] as String? ?? 'Fatima Al-Thani',
      passengerRating: json['passengerRating'] as String? ?? '4.9',
      destination: json['destination'] as String? ?? 'The Pearl-Qatar, Doha',
      estimatedTime: json['estimatedTime'] as String? ?? '8 min',
      distance: json['distance'] as String? ?? '2.1 km',
      pickupLat: (json['pickupLat'] as num?)?.toDouble(),
      pickupLng: (json['pickupLng'] as num?)?.toDouble(),
      dropoffLat: (json['dropoffLat'] as num?)?.toDouble(),
      dropoffLng: (json['dropoffLng'] as num?)?.toDouble(),
      pickupAddress: json['pickupAddress'] as String? ?? '',
      tripStage: json['tripStage'] as String? ?? 'none',
      rideId: json['rideId'] as String?,
      apiStatus: json['apiStatus'] as String?,
    );
  }
}

// Driver Cubit - now with automatic persistence
class DriverCubit extends HydratedCubit<DriverState> {
  DriverCubit() : super(const DriverState());

  void setOnline(bool isOnline) {
    emit(state.copyWith(isOnline: isOnline));
  }

  void setSlidePosition(double position) {
    emit(state.copyWith(slidePosition: position));
  }

  void setSliding(bool isSliding) {
    emit(state.copyWith(isSliding: isSliding));
  }

  void updateEarnings(String earnings) {
    emit(state.copyWith(todayEarnings: earnings));
  }

  void updateRideCount(String rideCount) {
    emit(state.copyWith(todayRides: rideCount));
  }

  void setBottomNavIndex(int index) {
    emit(state.copyWith(currentBottomNavIndex: index));
  }

  Future<Map<String, dynamic>> goOffline() async {
    // Optimistically update local state
    emit(state.copyWith(isOnline: false, slidePosition: 9999.0)); // Large number, UI will clamp to maxSlide
    
    // Sync with backend
    final result = await ApiService.driverSetStatus(isOnline: false);
    return result;
  }
 
  Future<Map<String, dynamic>> goOnline() async {
    // Optimistically update local state
    emit(state.copyWith(isOnline: true, slidePosition: 0.0));
    
    // Sync with backend
    final result = await ApiService.driverSetStatus(isOnline: true);
    return result;
  }

  void startTrip({
    String? passengerName,
    String? passengerRating,
    String? destination,
    String? estimatedTime,
    String? distance,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? pickupAddress,
    String? rideId,
  }) {
    // Ensure rideId is not empty - use existing rideId if provided one is empty
    final validRideId = (rideId != null && rideId.isNotEmpty) ? rideId : state.rideId;
    
    emit(state.copyWith(
      isOnTrip: true,
      tripProgress: '0', // Start at 0, will be calculated in real-time
      passengerName: passengerName ?? state.passengerName,
      passengerRating: passengerRating ?? state.passengerRating,
      destination: destination ?? state.destination,
      estimatedTime: estimatedTime ?? state.estimatedTime,
      distance: distance ?? state.distance,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      pickupAddress: pickupAddress ?? '',
      tripStage: 'heading_to_pickup',
      rideId: validRideId,
      apiStatus: 'accepted', // Initial API status when trip starts
    ));
    
    print('✅ DRIVER_CUBIT - startTrip() called with rideId: $validRideId');
    print('   State rideId after startTrip: ${state.rideId}');
  }
  
  void startHeadingToDestination() {
    emit(state.copyWith(
      tripProgress: '0', // Reset progress for destination phase
      tripStage: 'heading_to_destination',
      apiStatus: 'started', // Update API status
    ));
  }

  void updateTripProgress(String progress) {
    emit(state.copyWith(tripProgress: progress));
  }

  void updateEstimatedTime(String estimatedTime) {
    emit(state.copyWith(estimatedTime: estimatedTime));
  }

  void completeTrip() {
    emit(state.copyWith(
      isOnTrip: false,
      tripProgress: '0',
      pickupLat: null,
      pickupLng: null,
      dropoffLat: null,
      dropoffLng: null,
      pickupAddress: '',
      tripStage: 'none',
      rideId: null,
      apiStatus: null,
    ));
  }
  
  /// Synchronize state from API status - THE SINGLE SOURCE OF TRUTH
  /// This method maps API status to the correct tripStage
  /// IMPORTANT: Always preserves rideId when updating state
  void syncFromApiStatus(String apiStatus, {String? rideId}) {
    final normalizedStatus = apiStatus.trim().toLowerCase();
    print('🔄 DRIVER_CUBIT - syncFromApiStatus called with: $normalizedStatus');
    print('   Current state: isOnTrip=${state.isOnTrip}, tripStage=${state.tripStage}, apiStatus=${state.apiStatus}, rideId=${state.rideId}');
    print('   Provided rideId: $rideId');
    
    // Use provided rideId or keep existing one - NEVER clear it unless trip is completed
    final preservedRideId = rideId ?? state.rideId;
    print('   Preserved rideId: $preservedRideId');
    
    // Map API status to tripStage
    // pending/accepted = heading_to_pickup (driver accepted, going to pickup rider)
    // started/in_progress/ongoing = heading_to_destination (rider picked up, going to destination)
    // completed/cancelled = trip over
    
    if (normalizedStatus == 'completed' || normalizedStatus == 'cancelled') {
      print('❌ DRIVER_CUBIT - Ride $normalizedStatus - clearing trip');
      completeTrip();
    } else if (normalizedStatus == 'pending' || normalizedStatus == 'accepted' || normalizedStatus == 'requested') {
      print('🚗 DRIVER_CUBIT - Status: $normalizedStatus → heading_to_pickup');
      // Only update if we need to change stage
      if (state.tripStage != 'heading_to_pickup') {
        emit(state.copyWith(
          tripStage: 'heading_to_pickup',
          apiStatus: normalizedStatus,
          rideId: preservedRideId, // PRESERVE rideId
        ));
        print('✅ DRIVER_CUBIT - Updated to heading_to_pickup, rideId preserved: $preservedRideId');
      } else if (state.apiStatus != normalizedStatus) {
        // Just update apiStatus for tracking, preserve rideId
        emit(state.copyWith(
          apiStatus: normalizedStatus,
          rideId: preservedRideId, // PRESERVE rideId
        ));
      }
    } else if (normalizedStatus == 'started' || 
               normalizedStatus == 'in_progress' || 
               normalizedStatus == 'ongoing') {
      print('🚗 DRIVER_CUBIT - Status: $normalizedStatus → heading_to_destination');
      // Only update if we need to change stage
      if (state.tripStage != 'heading_to_destination') {
        emit(state.copyWith(
          tripStage: 'heading_to_destination',
          tripProgress: '0', // Reset progress for new phase
          apiStatus: normalizedStatus,
          rideId: preservedRideId, // PRESERVE rideId
        ));
        print('✅ DRIVER_CUBIT - Updated to heading_to_destination, rideId preserved: $preservedRideId');
      } else if (state.apiStatus != normalizedStatus) {
        // Just update apiStatus for tracking, preserve rideId
        emit(state.copyWith(
          apiStatus: normalizedStatus,
          rideId: preservedRideId, // PRESERVE rideId
        ));
      }
    } else {
      print('⚠️ DRIVER_CUBIT - Unknown status: $normalizedStatus - keeping current state');
      // Just update the apiStatus field for tracking, preserve rideId
      if (state.apiStatus != normalizedStatus) {
        emit(state.copyWith(
          apiStatus: normalizedStatus,
          rideId: preservedRideId, // PRESERVE rideId
        ));
      }
    }
    
    print('   New state: isOnTrip=${state.isOnTrip}, tripStage=${state.tripStage}, apiStatus=${state.apiStatus}, rideId=${state.rideId}');
  }
  
  @override
  DriverState? fromJson(Map<String, dynamic> json) {
    try {
      return DriverState.fromJson(json);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Map<String, dynamic>? toJson(DriverState state) {
    try {
      return state.toJson();
    } catch (e) {
      return null;
    }
  }
}
