import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ManageVehicleScreen extends StatefulWidget {
  final String email;
  final String password;
  
  const ManageVehicleScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<ManageVehicleScreen> createState() => _ManageVehicleScreenState();
}

class _ManageVehicleScreenState extends State<ManageVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Form controllers
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  
  // Vehicle image
  File? _vehicleImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _vehicleImage = File(image.path);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle image selected successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _submitVehicleInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate vehicle image is uploaded
    if (_vehicleImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a vehicle photo'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('📤 Submitting vehicle information...');
      print('   Email from widget: "${widget.email}"');
      print('   Password from widget: "${widget.password.isNotEmpty ? "EXISTS (${widget.password.length} chars)" : "EMPTY"}"');
      print('   Vehicle image path: ${_vehicleImage!.path}');
      print('   Vehicle name: ${_makeController.text.trim()}');
      print('   Vehicle model: ${_modelController.text.trim()}');
      print('   Vehicle year: ${_yearController.text.trim()}');
      print('   Vehicle color: ${_colorController.text.trim()}');
      print('   License plate: ${_licensePlateController.text.trim()}');
      
      // Validate email and password
      if (widget.email.isEmpty || widget.password.isEmpty) {
        throw Exception('Email or password is empty. Please log in again.');
      }
      
      // Call API to save vehicle information
      final response = await ApiService.manageVehicle(
        email: widget.email,
        password: widget.password,
        vehicleImage: _vehicleImage!.path,
        vehicleName: _makeController.text.trim(),
        vehicleModel: _modelController.text.trim(),
        vehicleYear: int.parse(_yearController.text.trim()),
        vehicleColor: _colorController.text.trim(),
        licensePlate: _licensePlateController.text.trim(),
      );
      
      print('📥 Manage Vehicle Response: $response');
      
      if (mounted) {
        if (response['success'] == true) {
          // Show awaiting approval dialog
          _showAwaitingApprovalDialog();
        } else {
          // Extract error message
          String errorMessage = 'Failed to save vehicle information';
          if (response['error'] != null) {
            if (response['error'] is String) {
              errorMessage = response['error'];
            } else if (response['error'] is Map && response['error']['message'] != null) {
              errorMessage = response['error']['message'];
            } else if (response['error'] is Map && response['error']['error'] != null) {
              errorMessage = response['error']['error'];
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error submitting vehicle info: $e');
      print('Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving vehicle info: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  void _showAwaitingApprovalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveBorderRadius(context, 16),
                ),
              ),
              backgroundColor: themeState.backgroundColor,
              child: Padding(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success Icon
                    Container(
                      width: ResponsiveHelper.getResponsiveSpacing(context, 80),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 80),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.schedule_rounded,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 48),
                        color: AppColors.gold,
                      ),
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    
                    // Title
                    Text(
                      'Awaiting Approval',
                      style: TextStyle(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    
                    // Message
                    Text(
                      'Your vehicle information has been submitted. We\'ll review it and notify you once approved.',
                      style: TextStyle(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                    
                    // OK Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Got it',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeState.isDarkTheme 
                ? const Color(0xFF1A202C) 
                : AppColors.lightBackground,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: themeState.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Manage Vehicle',
              style: TextStyle(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vehicle Image Section
                    _buildVehicleImageSection(themeState),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                    
                    // Form Fields
                    _buildFormFields(themeState),
                    
                    SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
                    
                    // Submit Button
                    _buildSubmitButton(themeState),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicleImageSection(ThemeState themeState) {
    return Container(
      height: ResponsiveHelper.getResponsiveSpacing(context, 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getResponsiveBorderRadius(context, 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Vehicle Image or Placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getResponsiveBorderRadius(context, 12),
            ),
            child: _vehicleImage != null
                ? Image.file(
                    _vehicleImage!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: ResponsiveHelper.getResponsiveSpacing(context, 80),
                          color: const Color(0xFFE2E8F0),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Text(
                          'Add Vehicle Photo',
                          style: TextStyle(
                            color: const Color(0xFFA0AEC0),
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Camera Button
          Positioned(
            bottom: ResponsiveHelper.getResponsiveSpacing(context, 12),
            right: ResponsiveHelper.getResponsiveSpacing(context, 12),
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: ResponsiveHelper.getResponsiveSpacing(context, 48),
                height: ResponsiveHelper.getResponsiveSpacing(context, 48),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A5568),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: ResponsiveHelper.getResponsiveSpacing(context, 24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(ThemeState themeState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Make
        _buildTextField(
          controller: _makeController,
          label: 'Make',
          hint: 'e.g., Toyota',
          themeState: themeState,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter vehicle make';
            }
            return null;
          },
        ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        
        // Model
        _buildTextField(
          controller: _modelController,
          label: 'Model',
          hint: 'e.g., Camry',
          themeState: themeState,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter vehicle model';
            }
            return null;
          },
        ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        
        // Year and Color (Side by side)
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _yearController,
                label: 'Year',
                hint: 'e.g., 2022',
                themeState: themeState,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final year = int.tryParse(value);
                  if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                    return 'Invalid year';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            Expanded(
              child: _buildTextField(
                controller: _colorController,
                label: 'Color',
                hint: 'e.g., Silver',
                themeState: themeState,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        
        // License Plate
        _buildTextField(
          controller: _licensePlateController,
          label: 'License Plate',
          hint: 'e.g., QA 12345',
          themeState: themeState,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter license plate number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required ThemeState themeState,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: themeState.isDarkTheme 
                ? const Color(0xFFA0AEC0) 
                : const Color(0xFF718096),
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: themeState.textSecondary.withOpacity(0.5),
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            ),
            filled: true,
            fillColor: themeState.isDarkTheme 
                ? const Color(0xFF2D3748) 
                : const Color(0xFFEDF2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: BorderSide(
                color: AppColors.gold,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveHelper.getResponsiveBorderRadius(context, 8),
              ),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
              vertical: ResponsiveHelper.getResponsiveSpacing(context, 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeState themeState) {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitVehicleInfo,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.gold.withOpacity(0.5),
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getResponsiveBorderRadius(context, 12),
          ),
        ),
        elevation: 0,
      ),
      child: _isSubmitting
          ? SizedBox(
              height: ResponsiveHelper.getResponsiveSpacing(context, 20),
              width: ResponsiveHelper.getResponsiveSpacing(context, 20),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Save & Continue',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

