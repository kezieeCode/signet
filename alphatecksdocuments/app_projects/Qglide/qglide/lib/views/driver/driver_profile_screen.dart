import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../cubits/driver_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/call_service.dart';
import 'driver_earnings_screen.dart';
import 'driver_support_center_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  String _userName = 'Ahmed Al-Sayed';
  String _memberSince = '2024';

  final List<Map<String, dynamic>> _bottomNavItems = [
    {'label': 'Home', 'icon': Icons.home},
    {'label': 'Earnings', 'icon': Icons.pie_chart},
    {'label': 'Profile', 'icon': Icons.person},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDriverProfile();
  }

  Future<void> _fetchDriverProfile() async {
    try {
      final response = await ApiService.getDriverEarnings();

      if (response['success'] == true && response['data'] != null) {
        // Handle potential double nesting
        final outerData = response['data'];
        final data = outerData['data'] ?? outerData;

        final driverInfo = data['driver_info'] ?? {};

        if (mounted) {
          setState(() {
            _userName = driverInfo['name'] ?? 'Ahmed Al-Sayed';
            _memberSince = '2024'; // Default or extract from registration date
          });
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.isDarkTheme ? const Color(0xFF0F1B2B) : Colors.grey.shade50,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
                    vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                        
                        // Profile Section
                        _buildProfileSection(themeState),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                        
                        // Settings Section
                        _buildSection(
                          title: 'SETTINGS',
                          children: [
                            _buildSettingsItem(
                              icon: Icons.person_outline,
                              label: 'Personal Information',
                              onTap: () {
                                // Navigate to personal information
                              },
                              themeState: themeState,
                            ),
                            _buildSettingsItem(
                              icon: Icons.directions_car,
                              label: 'Manage Vehicle',
                              onTap: () {
                                // Navigate to vehicle management
                              },
                              themeState: themeState,
                            ),
                            _buildSettingsItem(
                              icon: Icons.language,
                              label: 'Language',
                              onTap: () {
                                // Show language selection
                              },
                              themeState: themeState,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'English',
                                    style: TextStyle(
                                      color: themeState.textSecondary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                                  Icon(
                                    Icons.chevron_right,
                                    color: themeState.textSecondary,
                                    size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                                  ),
                                ],
                              ),
                            ),
                            _buildSettingsItem(
                              icon: Icons.dark_mode_outlined,
                              label: 'Dark Mode',
                              onTap: () {
                                // Toggle theme
                              },
                              themeState: themeState,
                              trailing: Switch(
                                value: themeState.isDarkTheme,
                                onChanged: (value) {
                                  context.read<ThemeCubit>().toggleTheme();
                                },
                                activeColor: Colors.amber,
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: themeState.isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade300,
                              ),
                            ),
                          ],
                          themeState: themeState,
                        ),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                        
                        // Support Section
                        _buildSection(
                          title: 'SUPPORT',
                          children: [
                            _buildSettingsItem(
                              icon: Icons.help_outline,
                              label: 'Help Center',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DriverSupportCenterScreen()),
                                );
                              },
                              themeState: themeState,
                            ),
                            _buildSettingsItem(
                              icon: Icons.chat_bubble_outline,
                              label: 'Live Chat',
                              onTap: () {
                                // Navigate to live chat
                              },
                              themeState: themeState,
                            ),
                          ],
                          themeState: themeState,
                        ),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
                        
                        // Logout Button
                        _buildLogoutButton(themeState),
                        
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(themeState),
        );
      },
    );
  }

  Widget _buildProfileSection(ThemeState themeState) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20)),
      child: Row(
        children: [
          // Profile Avatar
          Stack(
            children: [
              Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 80),
                height: ResponsiveHelper.getResponsiveSpacing(context, 80),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.grey.shade300,
                  border: Border.all(
                    color: themeState.fieldBorder,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: themeState.textPrimary,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 40),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: ResponsiveHelper.getResponsiveSpacing(context, 24),
                  height: ResponsiveHelper.getResponsiveSpacing(context, 24),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 12),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                Text(
                  'Member since $_memberSince',
                  style: TextStyle(
                    color: themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required ThemeState themeState,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: themeState.textSecondary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Container(
            decoration: BoxDecoration(
              color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeState themeState,
    Widget? trailing,
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
              color: themeState.isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: themeState.isDarkTheme ? Colors.white : Colors.black,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else
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

  Widget _buildBottomNavigationBar(ThemeState themeState) {
    return BlocBuilder<DriverCubit, DriverState>(
      builder: (context, driverState) {
        return Container(
          decoration: BoxDecoration(
            color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
            border: Border(
              top: BorderSide(
                color: themeState.isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade300,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 8),
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _bottomNavItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> item = entry.value;
                  bool isSelected = index == 2; // Profile is always selected on this screen

                  return GestureDetector(
                    onTap: () {
                      if (index == 0) {
                        // Navigate to Home
                        context.read<DriverCubit>().setBottomNavIndex(0);
                        Navigator.pop(context);
                      } else if (index == 1) {
                        // Navigate to Earnings
                        context.read<DriverCubit>().setBottomNavIndex(1);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const DriverEarningsScreen()),
                        );
                      }
                      // index == 2 (Profile) - already on this screen, do nothing
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
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(ThemeState themeState) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 20)),
      child: GestureDetector(
        onTap: () async {
          final bool? confirm = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
                title: Text(
                  'Log Out',
                  style: TextStyle(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'Are you sure you want to log out?',
                  style: TextStyle(
                    color: themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          );

          if (confirm == true) {
            try {
              // Before logging out, mark driver as offline/unavailable
              // This ensures the driver disappears from riders' maps immediately
              final driverCubit = context.read<DriverCubit>();
              if (driverCubit.state.isOnline) {
                // Send final location update with isAvailable=false
                try {
                  // Get current location if available
                  final location = await LocationService.getCurrentPosition();
                  if (location != null) {
                    await ApiService.updateDriverLocation(
                      latitude: location.latitude,
                      longitude: location.longitude,
                      isAvailable: false, // Mark as unavailable before logout
                    );
                  }
                } catch (e) {
                  // If location update fails, continue with logout anyway
                  if (kDebugMode) {
                    print('⚠️ Could not update location before logout: $e');
                  }
                }
                
                // Mark driver as offline in local state
                driverCubit.goOffline();
              }
              
              // CRITICAL: Reset CallService to clean up Zego state before logout
              CallService.reset();
              
              final response = await ApiService.logout();
              
              if (response['success'] == true) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logout successful!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  // Navigate to onboarding screen
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/onboarding',
                    (Route<dynamic> route) => false,
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response['error'] ?? 'Logout failed. Please try again.'),
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
            }
          }
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
            horizontal: ResponsiveHelper.getResponsiveSpacing(context, 24),
          ),
          decoration: BoxDecoration(
            color: themeState.isDarkTheme ? const Color(0xFF1A2B47) : Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            border: Border.all(
              color: themeState.isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          child: Text(
            'Log Out',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: themeState.isDarkTheme ? const Color(0xFFFF6B6B) : const Color(0xFF2A3A5C),
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
