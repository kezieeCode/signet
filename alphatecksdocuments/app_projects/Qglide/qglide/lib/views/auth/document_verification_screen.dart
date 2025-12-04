import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../cubits/theme_cubit.dart';
import '../../cubits/document_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';
import '../driver/manage_vehicle_screen.dart';

class DocumentVerificationScreen extends StatefulWidget {
  final String email;
  final String password;
  
  const DocumentVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<DocumentCubit, DocumentState>(
          builder: (context, documentState) {
        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          appBar: AppBar(
            backgroundColor: themeState.backgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: themeState.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Verification',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Upload Your Documents',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: themeState.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                Text(
                  'Please provide clear photos of your documents to get your account approved.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),

                // Driver's License Section
                _buildSectionHeader("Driver's License", themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildDocumentCard(
                  title: 'Driving License',
                  subtitle: 'Front & Back Required',
                  status: documentState.licenseFront != null && documentState.licenseBack != null ? 'Pending' : 'Upload Required',
                  isVerified: false,
                  icon: Icons.drive_eta_outlined,
                  frontImage: documentState.licenseFront,
                  backImage: documentState.licenseBack,
                  onFrontTap: () => _pickImage('license_front'),
                  onBackTap: () => _pickImage('license_back'),
                  themeState: themeState,
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                // Vehicle Photos Section
                _buildSectionHeader('Vehicle Photos', themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildSingleImageCard(
                  title: 'Vehicle Front Photo',
                  subtitle: 'Clear photo from the front',
                  icon: Icons.directions_car_outlined,
                  image: documentState.vehicleFront,
                  onTap: () => _pickImage('vehicle_front'),
                  themeState: themeState,
                  documentState: documentState,
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildSingleImageCard(
                  title: 'Vehicle Back Photo',
                  subtitle: 'Clear photo from the back',
                  icon: Icons.directions_car_outlined,
                  image: documentState.vehicleBack,
                  onTap: () => _pickImage('vehicle_back'),
                  themeState: themeState,
                  documentState: documentState,
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildSingleImageCard(
                  title: 'Vehicle Side Photo',
                  subtitle: 'Clear photo from the side',
                  icon: Icons.directions_car_outlined,
                  image: documentState.vehicleSide,
                  onTap: () => _pickImage('vehicle_side'),
                  themeState: themeState,
                  documentState: documentState,
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                // Insurance Section
                _buildSectionHeader('Insurance Document', themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildSingleImageCard(
                  title: 'Vehicle Insurance',
                  subtitle: 'Valid insurance certificate',
                  icon: Icons.verified_user_outlined,
                  image: documentState.insurance,
                  onTap: () => _pickImage('insurance'),
                  themeState: themeState,
                  documentState: documentState,
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

                // Vehicle Registration Section
                _buildSectionHeader('Vehicle Registration', themeState),
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
                _buildSingleImageCard(
                  title: 'Vehicle Registration',
                  subtitle: 'Also called \'Istimara\'',
                  icon: Icons.description_outlined,
                  image: documentState.vehicleRegistration,
                  onTap: () => _pickImage('vehicle_registration'),
                  themeState: themeState,
                  documentState: documentState,
                ),

                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
            decoration: BoxDecoration(
              color: themeState.backgroundColor,
              border: Border(
                top: BorderSide(color: themeState.fieldBorder, width: 1),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit(documentState) ? _submitForReview : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit(documentState) ? AppColors.gold : themeState.fieldBorder,
                    foregroundColor: _canSubmit(documentState) ? Colors.black : themeState.textSecondary,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveHelper.getResponsiveSpacing(context, 16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 32)),
                    ),
                    elevation: 0,
                  ),
                  child: documentState.isSubmitting
                      ? SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                          width: ResponsiveHelper.getResponsiveSpacing(context, 20),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _canSubmit(documentState) ? Colors.black : themeState.textSecondary,
                            ),
                          ),
                        )
                      : Text(
                          'Submit for Review',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, ThemeState themeState) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: AppColors.gold,
        fontWeight: FontWeight.w700,
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required String status,
    required bool isVerified,
    required IconData icon,
    required File? frontImage,
    required File? backImage,
    required VoidCallback onFrontTap,
    required VoidCallback onBackTap,
    required ThemeState themeState,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.fieldBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 8)),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                ),
                child: Icon(
                  icon,
                  color: AppColors.gold,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusTextColor(status),
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Upload sections
          Row(
            children: [
              Expanded(
                child: _buildUploadBox(
                  label: 'Upload Front',
                  image: frontImage,
                  onTap: onFrontTap,
                  themeState: themeState,
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Expanded(
                child: _buildUploadBox(
                  label: 'Upload Back',
                  image: backImage,
                  onTap: onBackTap,
                  themeState: themeState,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox({
    required String label,
    required File? image,
    required VoidCallback onTap,
    required ThemeState themeState,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: ResponsiveHelper.getResponsiveSpacing(context, 120),
        decoration: BoxDecoration(
          color: themeState.backgroundColor,
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
          border: Border.all(
            color: themeState.fieldBorder,
            width: 2,
            style: BorderStyle.none,
          ),
        ),
        child: CustomPaint(
          painter: DottedBorderPainter(
            color: themeState.fieldBorder,
            strokeWidth: 2,
            gap: 4,
          ),
          child: image != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 10)),
                      child: Image.file(
                        image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildUploadPlaceholder(label, themeState);
                        },
                      ),
                    ),
                    // Retake overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 10)),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : _buildUploadPlaceholder(label, themeState),
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder(String label, ThemeState themeState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          color: themeState.textSecondary,
          size: ResponsiveHelper.getResponsiveIconSize(context, 32),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: themeState.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return AppColors.gold;
      case 'upload required':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.gold;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return Colors.white;
      case 'pending':
        return Colors.black;
      case 'upload required':
        return Colors.white;
      case 'rejected':
        return Colors.white;
      default:
        return Colors.black;
    }
  }

  Widget _buildSingleImageCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required File? image,
    required VoidCallback onTap,
    required ThemeState themeState,
    required DocumentState documentState,
  }) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
      decoration: BoxDecoration(
        color: themeState.fieldBg,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
        border: Border.all(color: themeState.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 8)),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 8)),
                ),
                child: Icon(
                  icon,
                  color: AppColors.gold,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
              ),
              SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12),
                  vertical: ResponsiveHelper.getResponsiveSpacing(context, 6),
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(image != null ? 'Pending' : 'Upload Required'),
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 16)),
                ),
                child: Text(
                  image != null ? 'Pending' : 'Upload Required',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getStatusTextColor(image != null ? 'Pending' : 'Upload Required'),
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
          
          // Upload section (shows when no image is uploaded)
          if (image == null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
              decoration: BoxDecoration(
                color: themeState.backgroundColor,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                border: Border.all(
                  color: themeState.fieldBorder,
                  width: 2,
                  style: BorderStyle.none,
                ),
              ),
              child: CustomPaint(
                painter: DottedBorderPainter(
                  color: themeState.fieldBorder,
                  strokeWidth: 2,
                  gap: 4,
                ),
                child: Container(
                  padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: themeState.textSecondary,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 48),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      Text(
                        'Upload $title',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: themeState.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: themeState.textSecondary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Display uploaded image section (shows when image is uploaded)
          if (image != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: ResponsiveHelper.getResponsiveSpacing(context, 200),
              decoration: BoxDecoration(
                color: themeState.backgroundColor,
                borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 10)),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: ResponsiveHelper.getResponsiveIconSize(context, 48),
                          ),
                        );
                      },
                    ),
                  ),
                  // Retake overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 10)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: ResponsiveHelper.getResponsiveIconSize(context, 32),
                            ),
                            SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                            Text(
                              'Tap to retake',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                              ),
                            ),
                          ],
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
    );
  }

  Future<void> _pickImage(String type) async {
    // Show source selection dialog
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
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
        // Update document cubit
        switch (type) {
          case 'license_front':
            context.read<DocumentCubit>().setLicenseFront(File(image.path));
            break;
          case 'license_back':
            context.read<DocumentCubit>().setLicenseBack(File(image.path));
            break;
          case 'vehicle_front':
            context.read<DocumentCubit>().setVehicleFront(File(image.path));
            break;
          case 'vehicle_back':
            context.read<DocumentCubit>().setVehicleBack(File(image.path));
            break;
          case 'vehicle_side':
            context.read<DocumentCubit>().setVehicleSide(File(image.path));
            break;
          case 'insurance':
            context.read<DocumentCubit>().setInsurance(File(image.path));
            break;
          case 'vehicle_registration':
            context.read<DocumentCubit>().setVehicleRegistration(File(image.path));
            break;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  bool _canSubmit(DocumentState documentState) {
    // Check if all required documents are uploaded
    return documentState.canSubmit;
  }

  Future<void> _submitForReview() async {
    final documentState = context.read<DocumentCubit>().state;
    if (!_canSubmit(documentState)) return;

    context.read<DocumentCubit>().setSubmitting(true);

    try {
      print('📄 DOCUMENT UPLOAD - Starting document submission process');
      
      // List of documents to upload
      final documents = [
        {'file': documentState.licenseFront, 'type': 'license_front'},
        {'file': documentState.licenseBack, 'type': 'license_back'},
        {'file': documentState.vehicleFront, 'type': 'vehicle_front'},
        {'file': documentState.vehicleBack, 'type': 'vehicle_back'},
        {'file': documentState.vehicleSide, 'type': 'vehicle_side'},
        {'file': documentState.insurance, 'type': 'insurance'},
        {'file': documentState.vehicleRegistration, 'type': 'registration'},
      ];

      int successCount = 0;
      int totalCount = documents.where((doc) => doc['file'] != null).length;
      
      print('📄 DOCUMENT UPLOAD - Total documents to upload: $totalCount');
      
      // Upload each document
      for (final doc in documents) {
        final file = doc['file'] as File?;
        final documentType = doc['type'] as String;
        
        if (file != null) {
          print('📄 DOCUMENT UPLOAD - Processing: $documentType');
          print('   File path: ${file.path}');
          
          try {
            // Get mime type
            final mimeType = ApiService.getMimeTypeFromExtension(file.path);
            print('   MIME type: $mimeType');
            
            // Read file and convert to base64
            final bytes = await file.readAsBytes();
            final base64String = base64Encode(bytes);
            final fileBase64 = 'data:$mimeType;base64,$base64String';
            print('   File base64 length: ${fileBase64.length} characters');
            
            print('   Calling uploadDocument API...');
            
            // Call API
            final response = await ApiService.uploadDocument(
              email: widget.email,
              password: widget.password,
              documentType: documentType,
              fileBase64: fileBase64,
              mimeType: mimeType,
            );
            
            print('📄 DOCUMENT UPLOAD RESPONSE - $documentType:');
            print('   Full response: $response');
            print('   Success: ${response['success']}');
            if (response['data'] != null) {
              print('   Data: ${response['data']}');
            }
            if (response['error'] != null) {
              print('   ❌ Error: ${response['error']}');
            }
            if (response['message'] != null) {
              print('   Message: ${response['message']}');
            }
            
            if (response['success']) {
              successCount++;
              print('   ✅ Upload successful! Success count: $successCount');
            } else {
              print('   ❌ Upload failed for $documentType');
              
              // Extract error message
              String errorMessage = 'Failed to upload $documentType';
              if (response['error'] != null) {
                if (response['error'] is String) {
                  errorMessage = response['error'];
                } else if (response['error'] is Map && response['error']['error'] != null) {
                  errorMessage = response['error']['error'];
                } else if (response['error'] is Map && response['error']['message'] != null) {
                  errorMessage = response['error']['message'];
                }
              }
              
              // Show error in SnackBar
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$documentType: $errorMessage'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            }
          } catch (e, stackTrace) {
            print('❌ DOCUMENT UPLOAD ERROR - $documentType:');
            print('   Exception: $e');
            print('   Stack trace: $stackTrace');
            
            // Show exception in SnackBar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$documentType: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }
      
      print('📄 DOCUMENT UPLOAD - Final Results:');
      print('   Successful uploads: $successCount');
      print('   Total documents: $totalCount');
      
      if (mounted) {
        if (successCount == totalCount) {
          print('✅ DOCUMENT UPLOAD - All documents uploaded successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All documents submitted successfully! We\'ll review them within 24 hours.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to manage vehicle screen
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ManageVehicleScreen(
                email: widget.email,
                password: widget.password,
              ),
            ),
            (route) => false, // Remove all previous routes
          );
        } else {
          print('⚠️ DOCUMENT UPLOAD - Some documents failed: ${totalCount - successCount} failed out of $totalCount');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Some documents failed to upload. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ DOCUMENT UPLOAD - Fatal error during submission:');
      print('   Exception: $e');
      print('   Stack trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting documents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        context.read<DocumentCubit>().setSubmitting(false);
      }
    }
  }
}

class DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    
    // Top border
    _drawDottedLine(canvas, paint, Offset(0, 0), Offset(size.width, 0));
    // Right border
    _drawDottedLine(canvas, paint, Offset(size.width, 0), Offset(size.width, size.height));
    // Bottom border
    _drawDottedLine(canvas, paint, Offset(size.width, size.height), Offset(0, size.height));
    // Left border
    _drawDottedLine(canvas, paint, Offset(0, size.height), Offset(0, 0));
  }

  void _drawDottedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final distance = (end - start).distance;
    final dashLength = strokeWidth * 2;
    final dashCount = (distance / (dashLength + gap)).floor();
    
    for (int i = 0; i < dashCount; i++) {
      final startRatio = i * (dashLength + gap) / distance;
      final endRatio = (i * (dashLength + gap) + dashLength) / distance;
      
      final dashStart = Offset.lerp(start, end, startRatio)!;
      final dashEnd = Offset.lerp(start, end, endRatio)!;
      
      canvas.drawLine(dashStart, dashEnd, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
