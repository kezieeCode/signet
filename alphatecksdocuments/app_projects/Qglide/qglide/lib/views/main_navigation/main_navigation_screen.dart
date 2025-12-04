import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../home/home_screen.dart';
import '../activity/activity_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../settings/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTabIndex;
  final Map<String, dynamic>? prefilledBooking;
  
  const MainNavigationScreen({
    super.key,
    this.initialTabIndex = 0,
    this.prefilledBooking,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentBottomNavIndex; // 0: Home, 1: Activity, 2: Wallet, 3: Profile, 4: Settings

  @override
  void initState() {
    super.initState();
    _currentBottomNavIndex = widget.initialTabIndex;
  }

  List<Widget> get _screens => [
    HomeScreen(prefilledBooking: widget.prefilledBooking),
    const ActivityScreen(),
    const WalletScreen(),
    const EditProfileScreen(),
    const SettingsScreen(),
  ];


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          body: IndexedStack(
            index: _currentBottomNavIndex,
            children: _screens,
          ),
          bottomNavigationBar: _buildBottomNavigationBar(themeState),
        );
      },
    );
  }


  // Commented out - keeping for future use
  /*
  Widget _buildBottomNavigationBar(ThemeState themeState) {
    return Container(
      decoration: BoxDecoration(
        color: themeState.panelBg,
        border: Border(
          top: BorderSide(color: themeState.fieldBorder, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _bottomNavItem('Home', Icons.home, 0, themeState),
              _bottomNavItem('Activity', Icons.list_alt, 1, themeState, 'assets/icons/activity.png'),
              _bottomNavItem('Wallet', Icons.account_balance_wallet, 2, themeState, 'assets/icons/svg.png'),
              _bottomNavItem('Profile', Icons.person, 3, themeState),
              _bottomNavItem('Settings', Icons.settings, 4, themeState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem(String label, IconData icon, int index, ThemeState themeState, [String? assetPath]) {
    final isSelected = _currentBottomNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentBottomNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            assetPath != null 
              ? Image.asset(
                  assetPath,
                  width: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  height: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  color: isSelected ? AppColors.gold : themeState.textSecondary,
                )
              : Icon(
              icon,
              color: isSelected ? AppColors.gold : themeState.textSecondary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.gold : themeState.textSecondary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  */

  // Using bottom navigation from support_tickets_screen.dart
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
    final isSelected = _currentBottomNavIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        // Immediate feedback
      },
      onTap: () {
        setState(() {
          _currentBottomNavIndex = index;
        });
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
              color: isSelected ? AppColors.gold : themeState.textSecondary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.gold : themeState.textSecondary,
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

// Placeholder screen for Activity
class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Text(
              '$title Screen\nComing Soon',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: themeState.textSecondary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              ),
            ),
          ),
        );
      },
    );
  }
}
