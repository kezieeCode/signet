import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/places_service.dart';
import '../../services/location_service.dart';
import 'package:google_places_flutter/model/prediction.dart';

class DeliveryOrderScreen extends StatefulWidget {
  const DeliveryOrderScreen({super.key});

  @override
  State<DeliveryOrderScreen> createState() => _DeliveryOrderScreenState();
}

class _DeliveryOrderScreenState extends State<DeliveryOrderScreen> {
  // Controllers
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _floorUnitController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _specialInstructionsController = TextEditingController();

  // State
  String _selectedPackageSize = 'Medium'; // Small, Medium, Large
  String _selectedDeliveryType = 'Standard';
  String _pickupAddress = '';
  String _dropoffAddress = '';
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  bool _isSubmitting = false;
  String _userCountry = 'QA'; // Default to Qatar, will be detected from location

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Use getCurrentLocationWithAddress to get position, address, and country
      final locationData = await LocationService.getCurrentLocationWithAddress();
      if (mounted && locationData != null) {
        final position = locationData['position'];
        final address = locationData['address'];
        final country = locationData['country'] ?? 'QA';
        
        setState(() {
          _pickupLatLng = LatLng(position.latitude, position.longitude);
          _pickupAddress = address;
          _pickupController.text = address;
          _userCountry = country; // Store detected country for drop-off autocomplete
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _onPickupPlaceSelected(Prediction prediction) {
    if (prediction.lat != null && prediction.lng != null) {
      setState(() {
        _pickupAddress = prediction.description ?? '';
        _pickupController.text = _pickupAddress;
        _pickupLatLng = LatLng(
          double.parse(prediction.lat!),
          double.parse(prediction.lng!),
        );
      });
    }
  }

  void _onDropoffPlaceSelected(Prediction prediction) {
    if (prediction.lat != null && prediction.lng != null) {
      setState(() {
        _dropoffAddress = prediction.description ?? '';
        _dropoffController.text = _dropoffAddress;
        _dropoffLatLng = LatLng(
          double.parse(prediction.lat!),
          double.parse(prediction.lng!),
        );
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    await _getCurrentLocation();
  }

  Future<void> _confirmDeliveryOrder() async {
    if (_pickupAddress.isEmpty || _dropoffAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // TODO: Implement API call to create delivery order
    // For now, simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      // Navigate back with result to trigger connecting to driver panel
      Navigator.of(context).pop({
        'success': true,
        'pickupAddress': _pickupAddress,
        'dropoffAddress': _dropoffAddress,
        'packageSize': _selectedPackageSize,
        'weight': _weightController.text,
        'deliveryType': _selectedDeliveryType,
        'floorUnit': _floorUnitController.text,
        'building': _buildingController.text,
        'specialInstructions': _specialInstructionsController.text,
      });
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _floorUnitController.dispose();
    _buildingController.dispose();
    _weightController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
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
            leading: Container(
              margin: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 8)),
              decoration: BoxDecoration(
                color: themeState.fieldBg,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.gold,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: Text(
              'Place Delivery Order',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 8)),
                decoration: BoxDecoration(
                  color: themeState.fieldBg,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: themeState.textPrimary,
                    size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                  ),
                  onPressed: () {
                    // Menu action
                  },
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pickup Location Section
                _buildSectionCard(
                  themeState: themeState,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                            height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                          Text(
                            'Pickup Location',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: themeState.textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      PlacesService.buildAutocompleteTextField(
                        onPlaceSelected: _onPickupPlaceSelected,
                        hintText: 'Enter pickup address',
                        themeState: themeState,
                        context: context,
                        controller: _pickupController,
                        countryCode: 'QA',
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      InkWell(
                        onTap: _useCurrentLocation,
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.gold,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                            ),
                            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                            Text(
                              'Use current location',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.gold,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                // Drop-off Location Section
                _buildSectionCard(
                  themeState: themeState,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: ResponsiveHelper.getResponsiveSpacing(context, 8),
                            height: ResponsiveHelper.getResponsiveSpacing(context, 8),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                          Text(
                            'Drop-off Location',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: themeState.textPrimary,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      PlacesService.buildAutocompleteTextField(
                        onPlaceSelected: _onDropoffPlaceSelected,
                        hintText: 'Enter delivery address',
                        themeState: themeState,
                        context: context,
                        controller: _dropoffController,
                        countryCode: _userCountry, // Use detected country for location-based suggestions
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _floorUnitController,
                              hintText: 'Floor/Unit',
                              themeState: themeState,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Expanded(
                            child: _buildTextField(
                              controller: _buildingController,
                              hintText: 'Building',
                              themeState: themeState,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

                // Package Details Section
                _buildSectionCard(
                  themeState: themeState,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Package Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      // Package Size Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildPackageSizeButton(
                              size: 'Small',
                              icon: Icons.inventory_2,
                              themeState: themeState,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Expanded(
                            child: _buildPackageSizeButton(
                              size: 'Medium',
                              icon: Icons.inventory_2,
                              themeState: themeState,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Expanded(
                            child: _buildPackageSizeButton(
                              size: 'Large',
                              icon: Icons.inventory_2,
                              themeState: themeState,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      // Weight and Delivery Type
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _weightController,
                              hintText: 'Weight (kg)',
                              themeState: themeState,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Expanded(
                            child: _buildDeliveryTypeDropdown(themeState),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                      // Special Instructions
                      _buildTextField(
                        controller: _specialInstructionsController,
                        hintText: 'Special instructions (optional)',
                        themeState: themeState,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                // Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _confirmDeliveryOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                        ),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                            width: ResponsiveHelper.getResponsiveSpacing(context, 20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            'Confirm Delivery Order',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.black,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                // Estimated Delivery Time
                Center(
                  child: Text(
                    'Estimated delivery: 45-60 mins',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required ThemeState themeState,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.panelBg,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 12),
        ),
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required ThemeState themeState,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: themeState.textPrimary,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: themeState.textSecondary,
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        ),
        filled: true,
        fillColor: themeState.fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 12),
          ),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 14),
        ),
      ),
    );
  }

  Widget _buildPackageSizeButton({
    required String size,
    required IconData icon,
    required ThemeState themeState,
  }) {
    final isSelected = _selectedPackageSize == size;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPackageSize = size;
        });
      },
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 12),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : themeState.fieldBg,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 12),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : themeState.textPrimary,
              size: ResponsiveHelper.getResponsiveIconSize(context, 24),
            ),
            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 4)),
            Text(
              size,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.black : themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTypeDropdown(ThemeState themeState) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
      ),
      decoration: BoxDecoration(
        color: themeState.fieldBg,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 12),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDeliveryType,
          isExpanded: true,
          icon: Icon(
            Icons.expand_more,
            color: themeState.textPrimary,
            size: ResponsiveHelper.getResponsiveIconSize(context, 20),
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
          ),
          items: ['Standard', 'Express', 'Same Day'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedDeliveryType = newValue;
              });
            }
          },
        ),
      ),
    );
  }
}

