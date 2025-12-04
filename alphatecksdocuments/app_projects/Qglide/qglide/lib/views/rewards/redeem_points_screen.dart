import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';

class RedeemPointsScreen extends StatefulWidget {
  final Function(Widget)? onNavigateToSubScreen;
  final VoidCallback? onPopSubScreen;
  
  const RedeemPointsScreen({super.key, this.onNavigateToSubScreen, this.onPopSubScreen});

  @override
  State<RedeemPointsScreen> createState() => _RedeemPointsScreenState();
}

class _RedeemPointsScreenState extends State<RedeemPointsScreen> {
  int _selectedQuantity = 1;
  final int _pointsPerRide = 30;
  final int _availablePoints = 82;
  final int _availableRides = 4;

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
                color: themeState.textPrimary,
              ),
              onPressed: () {
                if (widget.onPopSubScreen != null) {
                  widget.onPopSubScreen!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              'Redeem Points',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Available Balance Card
                _buildBalanceCard(themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Redeem for Free Rides Section
                _buildRedeemSection(themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Quantity Selector
                _buildQuantitySelector(themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Total Cost
                _buildTotalCost(themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                
                // Redeem Button
                _buildRedeemButton(themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // View History Link
                _buildHistoryLink(themeState),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(ThemeState themeState) {
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        children: [
          Text(
            'Your Available Balance',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: AppColors.gold,
                size: ResponsiveHelper.getResponsiveIconSize(context, 32),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Text(
                '$_availablePoints',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 48),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          Text(
            'Q-Points',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemSection(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Redeem for Free Rides',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        Container(
          width: double.infinity,
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            border: Border.all(color: themeState.fieldBorder),
          ),
          child: Row(
            children: [
              // Car Icon
              Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 48),
                height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                decoration: BoxDecoration(
                  color: themeState.fieldBg,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: AppColors.gold,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              // Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Free Ride Voucher',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                    Text(
                      '$_pointsPerRide points = 1 Free Ride',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gold,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ],
                ),
              ),
              // Available Rides
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'You have',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    ),
                  ),
                  Text(
                    '$_availableRides',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rides',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantitySelector(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How many rides to redeem?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minus Button
              GestureDetector(
                onTap: () {
                  if (_selectedQuantity > 1) {
                    setState(() {
                      _selectedQuantity--;
                    });
                  }
                },
                child: Container(
                  width: ResponsiveHelper.getResponsiveSpacing(context, 48),
                  height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                  decoration: BoxDecoration(
                    color: themeState.panelBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: themeState.fieldBorder),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: themeState.textPrimary,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 24)),
              // Quantity Display
              Text(
                '$_selectedQuantity',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 36),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 24)),
              // Plus Button
              GestureDetector(
                onTap: () {
                  final maxRides = _availablePoints ~/ _pointsPerRide;
                  if (_selectedQuantity < maxRides) {
                    setState(() {
                      _selectedQuantity++;
                    });
                  }
                },
                child: Container(
                  width: ResponsiveHelper.getResponsiveSpacing(context, 48),
                  height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                  decoration: BoxDecoration(
                    color: themeState.panelBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: themeState.fieldBorder),
                  ),
                  child: Icon(
                    Icons.add,
                    color: themeState.textPrimary,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCost(ThemeState themeState) {
    final totalCost = _selectedQuantity * _pointsPerRide;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Total Cost: ',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$totalCost Q-Points',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.gold,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRedeemButton(ThemeState themeState) {
    final totalCost = _selectedQuantity * _pointsPerRide;
    final canRedeem = totalCost <= _availablePoints;
    
    return Container(
      width: double.infinity,
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 16),
      decoration: BoxDecoration(
        gradient: canRedeem 
          ? LinearGradient(
              colors: [AppColors.gold, Color(0xFFFFD700)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : null,
        color: canRedeem ? null : themeState.fieldBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
      ),
      child: Text(
        'Redeem Now',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: canRedeem ? Colors.black : themeState.textSecondary,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHistoryLink(ThemeState themeState) {
    return Center(
      child: GestureDetector(
        onTap: () {
          // Handle view history
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Redemption history coming soon')),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View Redemption History',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.gold,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 4)),
            Icon(
              Icons.arrow_forward,
              color: AppColors.gold,
              size: ResponsiveHelper.getResponsiveIconSize(context, 16),
            ),
          ],
        ),
      ),
    );
  }
}
