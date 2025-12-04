import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import 'schedule_ride_screen.dart';

class RideBookingScreen extends StatefulWidget {
  final String pickupLocation;
  final String destinationLocation;
  
  const RideBookingScreen({
    super.key, 
    required this.pickupLocation,
    required this.destinationLocation,
  });

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  String _selectedRideType = 'Q-Standard';

  void _handleConfirmRide() {
    // Navigate back to home screen with connecting to driver state
    Navigator.pop(context, {
      'pickupLocation': widget.pickupLocation,
      'destinationLocation': widget.destinationLocation,
      'rideType': _selectedRideType,
      'status': 'connecting',
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.gold,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Book a Ride',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Handle Bar
              Center(
                child: Container(
                  width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                  height: ResponsiveHelper.getResponsiveSpacing(context, 4),
                  margin: EdgeInsets.symmetric(vertical: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  decoration: BoxDecoration(
                    color: themeState.textSecondary,
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
                  ),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup and Destination Section
                _buildLocationSection(themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                      // Choose a ride section
                      _buildChooseRideSection(themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                      // Payment and Promo section
                      _buildPaymentSection(themeState),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                    ],
                  ),
                ),
              ),
              
              // Confirm Button
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
                child: _buildConfirmButton(themeState),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationSection(ThemeState themeState) {
    return Column(
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
                    color: Colors.white,
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
                    widget.pickupLocation,
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
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
        
        // Dotted line
                Container(
                  width: ResponsiveHelper.getResponsiveSpacing(context, 2),
          height: ResponsiveHelper.getResponsiveSpacing(context, 30),
          margin: EdgeInsets.only(left: ResponsiveHelper.getResponsiveSpacing(context, 9)),
                  child: CustomPaint(
                    painter: DottedLinePainter(
                      color: themeState.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
        
        // Destination
        Row(
          children: [
            // Destination pin icon
            Icon(
              Icons.location_on,
              color: AppColors.gold,
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
                    widget.destinationLocation,
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
    );
  }

  Widget _buildChooseRideSection(ThemeState themeState) {
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
        _buildRideOption(
          themeState: themeState,
          rideType: 'Q-Standard',
          carIcon: Icons.directions_car,
          carImage: 'assets/cars/white_sedan.png',
          passengers: '1-4',
          description: 'Drop-off by 10:50 PM',
          price: 'QAR 45.50',
          originalPrice: 'QAR 50.00',
          isSelected: _selectedRideType == 'Q-Standard',
          hasDiscount: true,
        ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        
        _buildRideOption(
          themeState: themeState,
          rideType: 'Q-Comfort',
          carIcon: Icons.directions_car,
          carImage: 'assets/cars/black_sedan.png',
          passengers: '1-4',
          description: 'Newer cars, extra space',
          price: 'QAR 58.00',
          originalPrice: null,
          isSelected: _selectedRideType == 'Q-Comfort',
          hasDiscount: false,
        ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        
        _buildRideOption(
          themeState: themeState,
          rideType: 'Q-XL',
          carIcon: Icons.directions_car,
          carImage: 'assets/cars/suv.png',
          passengers: '1-6',
          description: 'Extra large vehicle',
          price: 'QAR 75.00',
          originalPrice: null,
          isSelected: _selectedRideType == 'Q-XL',
          hasDiscount: false,
        ),
      ],
    );
  }

  Widget _buildRideOption({
    required ThemeState themeState,
    required String rideType,
    required IconData carIcon,
    required String carImage,
    required String passengers,
    required String description,
    required String price,
    String? originalPrice,
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
              child: Icon(
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
            
            // Price Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (originalPrice != null) ...[
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 2)),
                  Text(
                    originalPrice,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                      decoration: TextDecoration.lineThrough,
          ),
        ),
      ],
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPaymentSection(ThemeState themeState) {
    return Row(
      children: [
        // Payment Method
        Expanded(
          child: Row(
            children: [
              // VISA Card Icon
              Container(
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
        ),
        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Text(
                '**** 4242',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Icon(
                Icons.keyboard_arrow_down,
                color: themeState.textSecondary,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ],
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
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
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

  Widget _buildConfirmButton(ThemeState themeState) {
    return GestureDetector(
      onTap: _handleConfirmRide,
      child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
          ),
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          ),
          child: Text(
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
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 4.0;
    const double dashSpace = 3.0;
    double startY = 0.0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is DottedLinePainter && oldDelegate.color != color;
  }
}
