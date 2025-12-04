import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import 'booking_summary_screen.dart';

class SelfDriveRequirementScreen extends StatefulWidget {
  final Map<String, dynamic> car;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;

  const SelfDriveRequirementScreen({
    super.key,
    required this.car,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
  });

  @override
  State<SelfDriveRequirementScreen> createState() => _SelfDriveRequirementScreenState();
}

class _SelfDriveRequirementScreenState extends State<SelfDriveRequirementScreen> {
  String? _selectedIdType;
  File? _uploadedIdFile;
  final List<String> _idTypes = [
    'National ID',
    'Passport',
    'Driving License',
    'Residence Permit',
  ];

  Future<void> _pickDocument() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (file != null) {
        setState(() {
          _uploadedIdFile = File(file.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.isDarkTheme ? themeState.backgroundColor : Colors.white,
          appBar: AppBar(
            backgroundColor: themeState.isDarkTheme ? themeState.backgroundColor : Colors.white,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 8)),
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
                    : const Color(0xFF0D182E),
                  size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            title: Text(
              'Self-Drive Requirement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: themeState.isDarkTheme 
                  ? themeState.textPrimary 
                  : const Color(0xFF0D182E),
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: themeState.isDarkTheme 
                  ? themeState.textPrimary 
                  : const Color(0xFF0D182E),
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                Text(
                  'Upload your document',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: themeState.isDarkTheme 
                      ? themeState.textPrimary 
                      : const Color(0xFF0D182E),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                
                // Instructional text
                Text(
                  'Please upload the following documents to verify your eligibility for self-drive services. Ensure all documents are clear and legible.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeState.isDarkTheme 
                      ? themeState.textSecondary 
                      : const Color(0xFF4A5568),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    height: 1.5,
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Divider
                Divider(
                  color: themeState.fieldBorder,
                  thickness: 1,
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // ID Type Section
                Text(
                  'ID type',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeState.isDarkTheme 
                      ? themeState.textPrimary 
                      : const Color(0xFF0D182E),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                
                // ID Type Dropdown
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: themeState.isDarkTheme 
                        ? themeState.panelBg 
                        : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                          topRight: Radius.circular(
                            ResponsiveHelper.getResponsiveBorderRadius(context, 20),
                          ),
                        ),
                      ),
                      builder: (context) {
                        return Container(
                          padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: ResponsiveHelper.getResponsiveSpacing(context, 40),
                                height: ResponsiveHelper.getResponsiveSpacing(context, 4),
                                margin: EdgeInsets.only(
                                  bottom: ResponsiveHelper.getResponsiveSpacing(context, 16),
                                ),
                                decoration: BoxDecoration(
                                  color: themeState.fieldBorder,
                                  borderRadius: BorderRadius.circular(
                                    ResponsiveHelper.getResponsiveBorderRadius(context, 2),
                                  ),
                                ),
                              ),
                              ..._idTypes.map((idType) {
                                return ListTile(
                                  title: Text(
                                    idType,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: themeState.textPrimary,
                                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedIdType = idType;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme ? themeState.fieldBg : Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                      ),
                      border: Border.all(
                        color: themeState.isDarkTheme 
                          ? themeState.fieldBorder 
                          : const Color(0xFF0D182E).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          color: themeState.isDarkTheme 
                            ? themeState.textSecondary 
                            : const Color(0xFF4A5568),
                          size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                        ),
                        SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                        Expanded(
                          child: Text(
                            _selectedIdType ?? 'Select ID',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _selectedIdType != null
                                  ? (themeState.isDarkTheme 
                                      ? themeState.textPrimary 
                                      : const Color(0xFF0D182E))
                                  : (themeState.isDarkTheme 
                                      ? themeState.textSecondary 
                                      : const Color(0xFF4A5568)),
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: themeState.isDarkTheme 
                            ? themeState.textSecondary 
                            : const Color(0xFF4A5568),
                          size: ResponsiveHelper.getResponsiveIconSize(context, 24),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                
                // Upload ID Section
                Text(
                  'Upload ID',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: themeState.isDarkTheme 
                      ? themeState.textPrimary 
                      : const Color(0xFF0D182E),
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                
                // Upload Button
                GestureDetector(
                  onTap: _pickDocument,
                  child: Container(
                    padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 24)),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme ? themeState.fieldBg : Colors.white,
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getResponsiveBorderRadius(context, 12),
                      ),
                      border: Border.all(
                        color: themeState.isDarkTheme 
                          ? themeState.fieldBorder 
                          : const Color(0xFF0D182E).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.upload,
                          color: themeState.isDarkTheme 
                            ? themeState.textSecondary 
                            : const Color(0xFF4A5568),
                          size: ResponsiveHelper.getResponsiveIconSize(context, 48),
                        ),
                        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                        Text(
                          _uploadedIdFile != null 
                            ? _uploadedIdFile!.path.split('/').last 
                            : 'Tap to upload',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeState.isDarkTheme 
                              ? themeState.textPrimary 
                              : const Color(0xFF0D182E),
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                
                // Info text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(
                        top: ResponsiveHelper.getResponsiveSpacing(context, 2),
                      ),
                      width: ResponsiveHelper.getResponsiveSpacing(context, 16),
                      height: ResponsiveHelper.getResponsiveSpacing(context, 16),
                      decoration: BoxDecoration(
                        color: themeState.isDarkTheme 
                          ? themeState.textPrimary 
                          : const Color(0xFF0D182E),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info,
                        color: themeState.isDarkTheme 
                          ? themeState.backgroundColor 
                          : Colors.white,
                        size: ResponsiveHelper.getResponsiveIconSize(context, 12),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    Expanded(
                      child: Text(
                        'Acceptable formats (JPG, PNG, PDF) and file size 123mb.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: themeState.isDarkTheme 
                            ? themeState.textSecondary 
                            : const Color(0xFF4A5568),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
              ],
            ),
          ),
          bottomNavigationBar: Container(
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Validate and continue
                    if (_selectedIdType == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select an ID type'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (_uploadedIdFile == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please upload your ID document'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    // Navigate to booking summary
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BookingSummaryScreen(
                          car: widget.car,
                          pickupDate: widget.pickupDate,
                          pickupTime: widget.pickupTime,
                          returnDate: widget.returnDate,
                          returnTime: widget.returnTime,
                          rentType: 'Self Drive',
                        ),
                      ),
                    );
                  },
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
                  child: Text(
                    'Continue',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

