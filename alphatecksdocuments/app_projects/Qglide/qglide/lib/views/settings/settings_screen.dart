import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/locale_cubit.dart';
import '../../cubits/ride_cubit.dart';
import '../../cubits/driver_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';
import '../../services/call_service.dart';
import '../support/support_center_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'saved_locations_screen.dart';
import 'log_viewer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkModeEnabled = false;
  bool _generalNotificationsEnabled = true;
  bool _promotionsEnabled = false;
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, localeState) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              l10n.settings,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  // Account Section
                  _buildSection(
                    title: l10n.account,
                    children: [
                      _buildSettingsItem(
                        icon: Icons.security,
                        label: l10n.security,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Security settings coming soon')),
                          );
                        },
                        themeState: themeState,
                      ),
                      _buildSettingsItem(
                        icon: Icons.privacy_tip,
                        label: l10n.privacyPolicy,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Privacy policy coming soon')),
                          );
                        },
                        themeState: themeState,
                      ),
                      _buildSettingsItem(
                        icon: Icons.support_agent,
                        label: l10n.supportCenter,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SupportCenterScreen(),
                            ),
                          );
                        },
                        themeState: themeState,
                      ),
                      _buildSettingsItem(
                        icon: Icons.location_on,
                        label: l10n.savedLocations,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SavedLocationsScreen(),
                            ),
                          );
                        },
                        themeState: themeState,
                      ),
                      _buildSettingsItem(
                        icon: Icons.bug_report,
                        label: 'View App Logs',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LogViewerScreen(),
                            ),
                          );
                        },
                        themeState: themeState,
                      ),
                    ],
                    themeState: themeState,
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Appearance Section
                  _buildSection(
                    title: l10n.appearance,
                    children: [
                      _buildToggleItem(
                        icon: Icons.dark_mode,
                        label: l10n.darkMode,
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });
                          // Toggle theme
                          context.read<ThemeCubit>().toggleTheme();
                        },
                        themeState: themeState,
                      ),
                      _buildLanguageSelector(themeState, localeState, l10n),
                    ],
                    themeState: themeState,
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                  
                  // Notifications Section
                  _buildSection(
                    title: l10n.notifications,
                    children: [
                      _buildToggleItem(
                        icon: Icons.notifications,
                        label: l10n.generalNotifications,
                        value: _generalNotificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _generalNotificationsEnabled = value;
                          });
                        },
                        themeState: themeState,
                      ),
                      _buildToggleItem(
                        icon: Icons.local_offer,
                        label: l10n.promotionsOffers,
                        value: _promotionsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _promotionsEnabled = value;
                          });
                        },
                        themeState: themeState,
                      ),
                    ],
                    themeState: themeState,
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
                  
                  // Log Out Button
                  _buildLogOutButton(themeState, l10n),
                ],
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required ThemeState themeState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: themeState.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        Container(
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            border: Border.all(color: themeState.fieldBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeState themeState,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: themeState.fieldBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.gold,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeState themeState,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: themeState.fieldBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.gold,
            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.gold,
            activeTrackColor: AppColors.gold.withOpacity(0.3),
            inactiveThumbColor: themeState.textSecondary,
            inactiveTrackColor: themeState.fieldBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(ThemeState themeState, LocaleState localeState, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                color: AppColors.gold,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Text(
                l10n.language,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Row(
            children: [
              Expanded(
                child: _buildLanguageButton(
                  label: l10n.english,
                  isSelected: localeState.isEnglish,
                  onTap: () {
                    context.read<LocaleCubit>().setEnglish();
                  },
                  themeState: themeState,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Expanded(
                child: _buildLanguageButton(
                  label: l10n.arabic,
                  isSelected: localeState.isArabic,
                  onTap: () {
                    context.read<LocaleCubit>().setArabic();
                  },
                  themeState: themeState,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeState themeState,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : themeState.fieldBg,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
          border: Border.all(
            color: isSelected ? AppColors.gold : themeState.fieldBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected ? Colors.black : themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLogOutButton(ThemeState themeState, AppLocalizations l10n) {
    return Center(
      child: GestureDetector(
        onTap: _isLoggingOut ? null : () => _showLogoutConfirmationDialog(l10n, themeState),
        child: Container(
          width: ResponsiveHelper.getResponsiveSpacing(context, 280),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 24),
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
          ),
          decoration: BoxDecoration(
            color: themeState.panelBg,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            border: Border.all(color: themeState.fieldBorder),
          ),
          child: _isLoggingOut
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Text(
                      l10n.logOut,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(AppLocalizations l10n, ThemeState themeState) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: themeState.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
          ),
          title: Text(
            l10n.logOut,
            style: TextStyle(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            l10n.logOutConfirm,
            style: TextStyle(
              color: themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.cancel,
                style: TextStyle(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performLogout();
              },
              child: Text(
                l10n.yes,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      print('🔐 LOGOUT - Starting logout process...');
      
      // CRITICAL: Reset CallService to clean up Zego state before logout
      print('🔐 LOGOUT - Resetting CallService...');
      CallService.reset();
      
      final response = await ApiService.logout();
      
      print('🔐 LOGOUT - API Response: ${response['success']}');

      if (response['success'] == true) {
        // Clear all persisted state
        print('🔐 LOGOUT - Clearing RideCubit state...');
        context.read<RideCubit>().rideCompleted();
        
        print('🔐 LOGOUT - Clearing DriverCubit state...');
        context.read<DriverCubit>().completeTrip();
        
        print('🔐 LOGOUT - Navigating to onboarding...');
        
        // Navigate to onboarding screen and clear navigation stack
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            (route) => false,
          );
        }
        
        print('✅ LOGOUT - Completed successfully');
      } else {
        print('❌ LOGOUT - API returned failure');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoggingOut = false);
        }
      }
    } catch (e) {
      print('❌ LOGOUT - Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoggingOut = false);
      }
    }
  }
}

