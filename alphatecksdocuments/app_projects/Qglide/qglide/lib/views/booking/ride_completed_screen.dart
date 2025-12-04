import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../services/api_service.dart';
import '../../utils/responsive_helper.dart';
import '../main_navigation/main_navigation_screen.dart';

class RideCompletedScreen extends StatefulWidget {
  final String driverName;
  final String vehicleInfo;
  final String pickupLocation;
  final String destinationLocation;
  final double rideFare;
  final String? rideId;

  const RideCompletedScreen({
    super.key,
    required this.driverName,
    required this.vehicleInfo,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.rideFare,
    this.rideId,
  });

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> {
  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeader(themeState),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Driver Information Card
                  _buildDriverCard(themeState),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                  
                  // Rating Card
                  _buildRatingCard(themeState),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Fare Breakdown
                  _buildFareBreakdown(themeState),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Complete Button
                  _buildCompleteButton(themeState),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Ride Completed!',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.gold,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 32),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
        Text(
          'Thank you for riding with QGlide.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: themeState.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDriverCard(ThemeState themeState) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        children: [
          // Driver Profile Picture
          Container(
            width: ResponsiveHelper.getResponsiveSpacing(context, 80),
            height: ResponsiveHelper.getResponsiveSpacing(context, 80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
              color: themeState.fieldBg,
            ),
            child: Icon(
              Icons.person,
              size: ResponsiveHelper.getResponsiveIconSize(context, 40),
              color: AppColors.gold,
            ),
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Driver Name
          Text(
            widget.driverName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          
          // Vehicle Info
          Text(
            widget.vehicleInfo,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(ThemeState themeState) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How was your ride?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                  child: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    color: AppColors.gold,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 32),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }


  Widget _buildFareBreakdown(ThemeState themeState) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Fare Items
          _buildFareItem('Ride Fare', widget.rideFare, themeState),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Divider
          Container(
            height: 1,
            color: themeState.fieldBorder,
          ),
          
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'QAR ${widget.rideFare.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.gold,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareItem(String label, double amount, ThemeState themeState) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            ),
          ),
          Text(
            '${amount >= 0 ? '' : '-'}QAR ${amount.abs().toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: amount < 0 ? Colors.green : themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(ThemeState themeState) {
    return Container(
      width: double.infinity,
      height: ResponsiveHelper.getResponsiveSpacing(context, 56),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 30)),
      ),
      child: TextButton(
        onPressed: _isSubmitting ? null : () async {
          // Submit rating if selected
          if (_selectedRating > 0 && widget.rideId != null) {
            setState(() {
              _isSubmitting = true;
            });
            
            try {
              final response = await ApiService.rateDriver(
                rideId: widget.rideId!,
                rating: _selectedRating,
              );
              
              if (mounted) {
                if (response['success']) {
                  // Rating submitted successfully
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you for your rating!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Rating submission failed, but continue
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Rating could not be submitted'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error submitting rating'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isSubmitting = false;
                });
              }
            }
          }
          
          // Navigate to main navigation regardless of rating
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigationScreen(),
              ),
              (route) => false, // Remove all previous routes
            );
          }
        },
        child: _isSubmitting
            ? SizedBox(
                width: ResponsiveHelper.getResponsiveSpacing(context, 24),
                height: ResponsiveHelper.getResponsiveSpacing(context, 24),
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Complete',
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
