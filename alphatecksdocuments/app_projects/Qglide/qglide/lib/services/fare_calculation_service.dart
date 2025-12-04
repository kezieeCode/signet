class FareCalculationService {
  // Base fare rates (in QAR)
  static const double _baseFare = 45.50;
  static const double _perKmRate = 2.50;
  static const double _perMinuteRate = 0.50;
  static const double _bookingFee = 5.00;
  
  // Minimum fare
  static const double _minimumFare = 25.00;

  /// Calculates the fare breakdown for a ride
  /// 
  /// [distance] - Distance in kilometers
  /// [duration] - Duration in minutes
  /// [surgeMultiplier] - Optional surge pricing multiplier (default: 1.0)
  static FareBreakdown calculateFare({
    required double distance,
    required double duration,
    double surgeMultiplier = 1.0,
  }) {
    // Calculate individual components
    double distanceCost = distance * _perKmRate;
    double timeCost = duration * _perMinuteRate;
    
    // Calculate subtotal
    double subtotal = _baseFare + distanceCost + timeCost;
    
    // Apply surge pricing if applicable
    if (surgeMultiplier > 1.0) {
      subtotal *= surgeMultiplier;
    }
    
    // Add booking fee
    double total = subtotal + _bookingFee;
    
    // Ensure minimum fare
    total = total < _minimumFare ? _minimumFare : total;
    
    return FareBreakdown(
      baseFare: _baseFare,
      distanceFare: distanceCost,
      timeFare: timeCost,
      bookingFee: _bookingFee,
      surgeMultiplier: surgeMultiplier,
      subtotal: subtotal,
      total: total,
    );
  }

  /// Estimates fare for a given route
  /// This is a simplified calculation for display purposes
  static FareBreakdown estimateFare({
    required double distance,
    required double duration,
  }) {
    return calculateFare(
      distance: distance,
      duration: duration,
    );
  }

  /// Get static fare for demo purposes
  /// Returns the fare breakdown shown in the UI
  static FareBreakdown getDemoFare() {
    return FareBreakdown(
      baseFare: 45.50,
      distanceFare: 25.00,
      timeFare: 10.00,
      bookingFee: 5.00,
      surgeMultiplier: 1.0,
      subtotal: 80.50,
      total: 85.50,
    );
  }
}

class FareBreakdown {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double bookingFee;
  final double surgeMultiplier;
  final double subtotal;
  final double total;

  FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.bookingFee,
    required this.surgeMultiplier,
    required this.subtotal,
    required this.total,
  });

  /// Formats amount as QAR currency
  String formatAmount(double amount) {
    return 'QAR ${amount.toStringAsFixed(2)}';
  }

  /// Gets the formatted base fare
  String get formattedBaseFare => formatAmount(baseFare);

  /// Gets the formatted distance fare
  String get formattedDistanceFare => formatAmount(distanceFare);

  /// Gets the formatted time fare
  String get formattedTimeFare => formatAmount(timeFare);

  /// Gets the formatted booking fee
  String get formattedBookingFee => formatAmount(bookingFee);

  /// Gets the formatted total
  String get formattedTotal => formatAmount(total);
}
