import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';

class SavedLocationsScreen extends StatefulWidget {
  final Function(Widget)? onNavigateToSubScreen;
  final VoidCallback? onPopSubScreen;
  
  const SavedLocationsScreen({super.key, this.onNavigateToSubScreen, this.onPopSubScreen});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  final List<Map<String, dynamic>> _savedLocations = [
    {
      'id': 'home',
      'name': 'Home',
      'address': 'Al Waab St, Doha, Qatar',
      'icon': Icons.home,
      'type': 'home_work',
      'hasAddress': true,
    },
    {
      'id': 'work',
      'name': 'Work',
      'address': 'Add your work address',
      'icon': Icons.work,
      'type': 'home_work',
      'hasAddress': false,
    },
    {
      'id': 'gym',
      'name': 'Gym',
      'address': 'Aspire Zone, Al Baaya St',
      'icon': Icons.fitness_center,
      'type': 'other',
      'hasAddress': true,
    },
    {
      'id': 'airport',
      'name': 'Hamad Airport',
      'address': 'Hamad International Airport',
      'icon': Icons.flight,
      'type': 'other',
      'hasAddress': true,
    },
    {
      'id': 'restaurant',
      'name': 'Favorite Restaurant',
      'address': 'The Pearl-Qatar, Doha',
      'icon': Icons.restaurant,
      'type': 'other',
      'hasAddress': true,
    },
  ];

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
              'Saved Locations',
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
              Expanded(
                child: SingleChildScrollView(
                  padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Home/Work Section
                      _buildLocationSection(
                        title: 'Home/Work',
                        locations: _savedLocations.where((loc) => loc['type'] == 'home_work').toList(),
                        themeState: themeState,
                      ),
                      
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                      
                      // Other Places Section
                      _buildLocationSection(
                        title: 'Other Places',
                        locations: _savedLocations.where((loc) => loc['type'] == 'other').toList(),
                        themeState: themeState,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Add New Location Button
              _buildAddNewLocationButton(themeState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationSection({
    required String title,
    required List<Map<String, dynamic>> locations,
    required ThemeState themeState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        ...locations.map((location) => _buildLocationCard(location, themeState)).toList(),
      ],
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location, ThemeState themeState) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getResponsiveSpacing(context, 12)),
      padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: ResponsiveHelper.getResponsiveSpacing(context, 40),
            height: ResponsiveHelper.getResponsiveSpacing(context, 40),
            decoration: BoxDecoration(
              color: themeState.fieldBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              location['icon'],
              color: AppColors.gold,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
          ),
          
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Location Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location['name'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: themeState.textPrimary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
                Text(
                  location['address'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: location['hasAddress'] ? themeState.textSecondary : themeState.textSecondary.withOpacity(0.6),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                  ),
                ),
              ],
            ),
          ),
          
          // Action Button
          GestureDetector(
            onTap: () {
              if (location['hasAddress']) {
                _showLocationMenu(location);
              } else {
                _addLocationAddress(location);
              }
            },
            child: Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 32),
              height: ResponsiveHelper.getResponsiveSpacing(context, 32),
              decoration: BoxDecoration(
                color: themeState.fieldBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                location['hasAddress'] ? Icons.more_vert : Icons.add,
                color: location['hasAddress'] ? themeState.textPrimary : AppColors.gold,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewLocationButton(ThemeState themeState) {
    return Container(
      width: double.infinity,
      margin: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Add new location coming soon')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          ),
        ),
        child: Text(
          'Add New Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showLocationMenu(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: BlocProvider.of<ThemeCubit>(context).state.panelBg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
            topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 40),
              height: ResponsiveHelper.getResponsiveSpacing(context, 4),
              decoration: BoxDecoration(
                color: BlocProvider.of<ThemeCubit>(context).state.textSecondary,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 2)),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
            _buildMenuOption('Edit Location', Icons.edit, () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit location coming soon')),
              );
            }),
            _buildMenuOption('Delete Location', Icons.delete, () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delete location coming soon')),
              );
            }),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: BlocProvider.of<ThemeCubit>(context).state.textPrimary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BlocProvider.of<ThemeCubit>(context).state.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addLocationAddress(Map<String, dynamic> location) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add ${location['name']} address coming soon')),
    );
  }
}
