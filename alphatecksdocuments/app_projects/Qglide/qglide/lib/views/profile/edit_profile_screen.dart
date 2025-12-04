// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Function(Widget)? onNavigateToSubScreen;
  
  const EditProfileScreen({super.key, this.onNavigateToSubScreen});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  
  // Profile image
  File? _selectedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      print('🔍 FETCHING USER PROFILE...');
      final response = await ApiService.getUserProfile();
      
      print('📦 GET PROFILE RESPONSE: ${response['success']}');
      print('📦 GET PROFILE FULL RESPONSE: $response');
      
      if (response['success'] == true && response['data'] != null) {
        // Handle double nesting: response['data']['data']['profile']
        final outerData = response['data'];
        final innerData = outerData['data'] ?? outerData;
        final profile = innerData['profile'] ?? innerData;
        
        print('👤 PROFILE DATA: $profile');
        
        final photoUrl = profile['avatar_url']?.toString();
        print('📸 PROFILE PHOTO URL: $photoUrl');
        
        if (mounted) {
          setState(() {
            _fullNameController.text = profile['full_name']?.toString() ?? '';
            _phoneController.text = profile['phone']?.toString() ?? '';
            _emailController.text = profile['email']?.toString() ?? '';
            _dateOfBirthController.text = profile['date_of_birth']?.toString() ?? '';
            _profileImageUrl = photoUrl;
            _isLoadingProfile = false;
          });
        }
      } else {
        print('❌ GET PROFILE FAILED');
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    } catch (e) {
      print('❌ GET PROFILE ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirthController.text.isNotEmpty
          ? DateTime.tryParse(_dateOfBirthController.text) ?? DateTime(2000, 1, 1)
          : DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: context.read<ThemeCubit>().state.panelBg,
              onSurface: context.read<ThemeCubit>().state.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return Container(
              decoration: BoxDecoration(
                color: themeState.panelBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                  topRight: Radius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
                ),
              ),
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select Photo Source',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: themeState.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: AppColors.gold),
                    title: Text(
                      'Camera',
                      style: TextStyle(color: themeState.textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.photo_library, color: AppColors.gold),
                    title: Text(
                      'Gallery',
                      style: TextStyle(color: themeState.textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  if (_selectedImage != null || _profileImageUrl != null)
                    ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text(
                        'Remove Photo',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedImage = null;
                          _profileImageUrl = null;
                        });
                      },
                    ),
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 10)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo selected. Save changes to upload.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveProfile() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterFullName)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Upload avatar if image is selected
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final photoBase64 = base64Encode(bytes);
        
        print('📸 UPLOADING AVATAR - Size: ${bytes.length} bytes');
        
        final avatarResponse = await ApiService.uploadAvatar(
          base64Image: photoBase64,
        );
        
        print('📸 AVATAR UPLOAD RESPONSE: ${avatarResponse['success']}');
        print('📸 AVATAR UPLOAD FULL RESPONSE: $avatarResponse');
        
        if (!avatarResponse['success']) {
          final error = avatarResponse['error'];
          String errorMessage = 'Failed to upload avatar';
          
          if (error != null && error['message'] != null) {
            errorMessage = error['message'];
          }
          
          print('❌ AVATAR UPLOAD FAILED: $errorMessage');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
        
        // Check if avatar URL is returned (nested: data -> data -> avatar_url)
        final avatarData = avatarResponse['data'];
        final innerAvatarData = avatarData?['data'] ?? avatarData;
        final uploadedPhotoUrl = innerAvatarData?['avatar_url']?.toString();
        print('✅ AVATAR UPLOADED SUCCESSFULLY - URL: $uploadedPhotoUrl');
      }

      // Step 2: Update profile information
      final response = await ApiService.editProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim(),
      );
      
      print('📝 EDIT PROFILE RESPONSE: ${response['success']}');
      
      if (response['success']) {
        final l10n = AppLocalizations.of(context)!;
        
        // Update stored first name in ApiService
        final fullName = _fullNameController.text.trim();
        if (fullName.isNotEmpty) {
          final firstName = fullName.split(' ').first;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('first_name', firstName);
        }
        
        // Clear selected image after successful save
        setState(() {
          _selectedImage = null;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdatedSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Wait a bit for backend to process, then refresh profile data
        await Future.delayed(const Duration(milliseconds: 500));
        await _fetchUserProfile();
        
        print('🔄 PROFILE REFRESHED');
      } else {
        final l10n = AppLocalizations.of(context)!;
        // Handle API error
        final error = response['error'];
        String errorMessage = l10n.failedToUpdateProfile;
        
        if (error != null) {
          if (error['message'] != null) {
            errorMessage = error['message'];
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              l10n.editProfile,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: _isLoadingProfile
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                        
                        // Profile Picture Section
                        _buildProfilePicture(themeState),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
                  
                  // Input Fields
                  _buildInputField(
                    label: l10n.fullName,
                    icon: Icons.person,
                    controller: _fullNameController,
                    themeState: themeState,
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  _buildInputField(
                    label: l10n.phoneNumber,
                    icon: Icons.phone,
                    controller: _phoneController,
                    themeState: themeState,
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  _buildInputField(
                    label: l10n.emailAddress,
                    icon: Icons.email,
                    controller: _emailController,
                    themeState: themeState,
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  
                  _buildDateInputField(
                    label: l10n.dateOfBirth,
                    icon: Icons.calendar_today,
                    controller: _dateOfBirthController,
                    themeState: themeState,
                  ),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
                  
                  // Save Changes Button
                  _buildSaveButton(themeState),
                  
                  SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 60)),
                  
                  // Account Management Section
                  _buildAccountManagementSection(themeState),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePicture(ThemeState themeState) {
    return Stack(
      children: [
        Container(
          width: ResponsiveHelper.getResponsiveSpacing(context, 120),
          height: ResponsiveHelper.getResponsiveSpacing(context, 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.gold,
              width: 3,
            ),
          ),
          child: ClipOval(
            child: _selectedImage != null
                ? Image.file(
                    _selectedImage!,
                    width: ResponsiveHelper.getResponsiveSpacing(context, 120),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 120),
                    fit: BoxFit.cover,
                  )
                : _profileImageUrl != null
                    ? Image.network(
                        _profileImageUrl!,
                        width: ResponsiveHelper.getResponsiveSpacing(context, 120),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 120),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(themeState);
                        },
                      )
                    : Image.asset(
                        'assets/images/user.png',
                        width: ResponsiveHelper.getResponsiveSpacing(context, 120),
                        height: ResponsiveHelper.getResponsiveSpacing(context, 120),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAvatar(themeState);
                        },
                      ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              width: ResponsiveHelper.getResponsiveSpacing(context, 36),
              height: ResponsiveHelper.getResponsiveSpacing(context, 36),
              decoration: BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeState.backgroundColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.black,
                size: ResponsiveHelper.getResponsiveIconSize(context, 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(ThemeState themeState) {
    return Container(
      width: ResponsiveHelper.getResponsiveSpacing(context, 120),
      height: ResponsiveHelper.getResponsiveSpacing(context, 120),
      decoration: BoxDecoration(
        color: themeState.fieldBg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: ResponsiveHelper.getResponsiveIconSize(context, 60),
        color: themeState.textSecondary,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required ThemeState themeState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
        Container(
          decoration: BoxDecoration(
            color: themeState.fieldBg,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            border: Border.all(color: themeState.fieldBorder),
          ),
          child: TextField(
            controller: controller,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeState.textPrimary,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: themeState.textSecondary,
                size: ResponsiveHelper.getResponsiveIconSize(context, 20),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required ThemeState themeState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
        GestureDetector(
          onTap: _selectDateOfBirth,
          child: Container(
            decoration: BoxDecoration(
              color: themeState.fieldBg,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
              border: Border.all(color: themeState.fieldBorder),
            ),
            child: TextField(
              controller: controller,
              enabled: false,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeState.textPrimary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  icon,
                  color: themeState.textSecondary,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeState themeState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
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
        child: _isLoading 
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Text(
              AppLocalizations.of(context)!.saveChanges,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.black,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w700,
              ),
            ),
      ),
    );
  }

  Widget _buildAccountManagementSection(ThemeState themeState) {
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountManagement,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
        
        // Change Password Button
        _buildAccountButton(
          label: l10n.changePassword,
          textColor: themeState.textPrimary,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.changePasswordComingSoon)),
            );
          },
          themeState: themeState,
        ),
        
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
        
        // Delete Account Button
        _buildAccountButton(
          label: l10n.deleteAccount,
          textColor: Colors.red,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.deleteAccountComingSoon)),
            );
          },
          themeState: themeState,
        ),
      ],
    );
  }

  Widget _buildAccountButton({
    required String label,
    required Color textColor,
    required VoidCallback onTap,
    required ThemeState themeState,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsiveSpacing(context, 16),
          vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
        ),
        decoration: BoxDecoration(
          color: themeState.fieldBg,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          border: Border.all(color: themeState.fieldBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w500,
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
}

