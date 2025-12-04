import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../main_navigation/main_navigation_screen.dart';
import 'book_car_screen.dart';

class CarDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> car;

  const CarDetailsScreen({
    super.key,
    required this.car,
  });

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.isDarkTheme ? themeState.backgroundColor : Colors.white,
          bottomNavigationBar: _buildBottomNavigationBar(themeState),
          body: SafeArea(
            child: Column(
              children: [
                // Header with Back Button and Title
                Padding(
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: themeState.isDarkTheme ? themeState.fieldBg : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeState.isDarkTheme 
                              ? themeState.fieldBorder 
                              : AppColors.gold.withOpacity(0.3),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue
                            size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      Expanded(
                        child: Text(
                          '${widget.car['model']} ${widget.car['year']}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue text
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Car Image
                        Container(
                          width: double.infinity,
                          height: ResponsiveHelper.getResponsiveSpacing(context, 250),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                            ),
                            border: Border.all(
                              color: themeState.isDarkTheme 
                                ? themeState.fieldBorder 
                                : const Color(0xFF0D182E).withOpacity(0.2), // Dark blue border
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                            ),
                            child: Image.asset(
                              widget.car['image'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: themeState.fieldBg,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: themeState.textSecondary,
                                    size: ResponsiveHelper.getResponsiveIconSize(context, 48),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),

                        // Car Specifications Bar
                        Container(
                          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                          decoration: BoxDecoration(
                            color: themeState.isDarkTheme 
                              ? themeState.fieldBg 
                              : AppColors.gold.withOpacity(0.1), // Light yellow background
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSpecItem(
                                icon: Icons.speed,
                                label: 'Max speed',
                                value: widget.car['maxSpeed'] ?? '180km/h',
                                themeState: themeState,
                              ),
                              Container(
                                width: 1,
                                height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                                color: themeState.isDarkTheme 
                                  ? themeState.fieldBorder 
                                  : const Color(0xFF0D182E).withOpacity(0.2),
                              ),
                              _buildSpecItem(
                                icon: Icons.engineering,
                                label: 'Engine type',
                                value: widget.car['engineType'] ?? 'V8',
                                themeState: themeState,
                              ),
                              Container(
                                width: 1,
                                height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                                color: themeState.isDarkTheme 
                                  ? themeState.fieldBorder 
                                  : const Color(0xFF0D182E).withOpacity(0.2),
                              ),
                              _buildSpecItem(
                                icon: Icons.people,
                                label: 'No. of Passengers',
                                value: widget.car['passengers'] ?? '5',
                                themeState: themeState,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                        // Car Description
                        Text(
                          'Car Description',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue text
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Text(
                          widget.car['description'] ?? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textSecondary 
                              : const Color(0xFF4A5568), // Lighter dark blue
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                            height: 1.5,
                          ),
                        ),

                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                        // Car Class
                        Text(
                          'Car Class',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue text
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Text(
                          widget.car['carClass'] ?? 'Premium',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue text
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                        // Location
                        Text(
                          'Location',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue text
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Text(
                          widget.car['location'] as String,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue text
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                        // Rent Partner
                        Text(
                          'Rent Partner',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E), // Dark blue text
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        Row(
                          children: [
                            // Profile Picture
                            Container(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 56),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 56),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.pink.shade700,
                                size: ResponsiveHelper.getResponsiveIconSize(context, 32),
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                            // Name and Owner
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.car['ownerName'] ?? 'Julia Roberts',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: themeState.isDarkTheme 
                                        ? themeState.textPrimary 
                                        : const Color(0xFF0D182E), // Dark blue text
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                                  Text(
                                    widget.car['ownerRole'] ?? 'Owner',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: themeState.isDarkTheme 
                                        ? themeState.textSecondary 
                                        : const Color(0xFF4A5568), // Lighter dark blue
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Call and Chat Icons
                            Container(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                              decoration: BoxDecoration(
                                color: themeState.isDarkTheme 
                                  ? themeState.fieldBg 
                                  : AppColors.gold.withOpacity(0.1), // Light yellow
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.phone,
                                  color: themeState.isDarkTheme 
                                    ? themeState.textPrimary 
                                    : const Color(0xFF0D182E), // Dark blue
                                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                ),
                                onPressed: () {
                                  // Call action
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                            Container(
                              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                              height: ResponsiveHelper.getResponsiveSpacing(context, 40),
                              decoration: BoxDecoration(
                                color: themeState.isDarkTheme 
                                  ? themeState.fieldBg 
                                  : AppColors.gold.withOpacity(0.1), // Light yellow
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.chat_bubble_outline,
                                  color: themeState.isDarkTheme 
                                    ? themeState.textPrimary 
                                    : const Color(0xFF0D182E), // Dark blue
                                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                ),
                                onPressed: () {
                                  // Chat action
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                      ],
                    ),
                  ),
                ),

                // Price and Book Now Button (Fixed at bottom)
                Container(
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                  decoration: BoxDecoration(
                    color: themeState.isDarkTheme ? themeState.panelBg : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: themeState.fieldBorder,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: themeState.isDarkTheme 
                                    ? themeState.textPrimary 
                                    : const Color(0xFF0D182E), // Dark blue text
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold, // Use app gold color
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getResponsiveBorderRadius(context, 8),
                                  ),
                                ),
                                child: Text(
                                  widget.car['price'] as String,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.black, // Black text on gold
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        // Book Now Button
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => BookCarScreen(car: widget.car),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeState.isDarkTheme 
                                ? themeState.textPrimary 
                                : const Color(0xFF0D182E), // Dark blue button
                              padding: EdgeInsets.symmetric(
                                vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                                ),
                              ),
                            ),
                            child: Text(
                              'Book Now',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: themeState.isDarkTheme 
                                  ? themeState.backgroundColor 
                                  : Colors.white, // White text on dark blue
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeState themeState,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: themeState.isDarkTheme 
              ? themeState.textPrimary 
              : const Color(0xFF0D182E), // Dark blue icon
            size: ResponsiveHelper.getResponsiveIconSize(context, 24),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: themeState.isDarkTheme 
                ? themeState.textSecondary 
                : const Color(0xFF4A5568), // Lighter dark blue
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeState.isDarkTheme 
                ? themeState.textPrimary 
                : const Color(0xFF0D182E), // Dark blue text
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(ThemeState themeState) {
    return Container(
      decoration: BoxDecoration(
        color: themeState.panelBg,
        border: Border(
          top: BorderSide(
            color: themeState.fieldBorder,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: ResponsiveHelper.getResponsiveSpacing(context, 80),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0, themeState),
              _buildNavItem(Icons.history, 'Activity', 1, themeState),
              _buildNavItem(Icons.account_balance_wallet_outlined, 'Wallet', 2, themeState),
              _buildNavItem(Icons.person_outline, 'Profile', 3, themeState),
              _buildNavItem(Icons.settings_outlined, 'Settings', 4, themeState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, String label, int index, ThemeState themeState) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Navigate to main navigation screen with selected tab
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainNavigationScreen(initialTabIndex: index),
          ),
          (route) => false, // Remove all previous routes
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              outlinedIcon,
              color: themeState.textSecondary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: themeState.textSecondary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 10),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

