import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/theme_cubit.dart';
import '../../utils/responsive_helper.dart';
import '../../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call the API for forgot password
      final response = await ApiService.forgotPassword(
        email: _emailController.text.trim(),
      );
      
      if (response['success']) {
        // Show success message from API
        final successMessage = response['data']?['message'] ?? response['message'] ?? 'Reset link sent to your email!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back to login screen
        Navigator.pop(context);
      } else {
        // Extract error message from API response
        String errorMessage = 'Failed to send reset link. Please try again.';
        
        if (response['error'] != null) {
          // Check if error is a string (simple error message)
          if (response['error'] is String) {
            errorMessage = response['error'];
          }
          // Check if error is a map with various possible fields
          else if (response['error'] is Map) {
            final error = response['error'];
            errorMessage = error['message'] ?? 
                          error['error'] ?? 
                          error['email'] ?? 
                          'Failed to send reset link. Please try again.';
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
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final logoSize = ResponsiveHelper.getResponsiveLogoSize(context, multiplier: 0.28);

        return Scaffold(
          backgroundColor: themeState.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: ResponsiveHelper.getResponsiveSpacing(context, 40),
            height: ResponsiveHelper.getResponsiveSpacing(context, 40),
            decoration: BoxDecoration(
              color: themeState.panelBg,
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.gold,
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
              // Centered QGlide logo
              Center(
                child: Image.asset(
                  themeState.isDarkTheme ? 'assets/images/QGlide Logo w.png' : 'assets/images/logo.webp',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
              // Title
              Text(
                'Forgot Password?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              // Description
              Text(
                "No worries! Enter your email below and we'll send you a link to reset your password.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  height: 1.5,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 40)),
              // Email input field
              Container(
                decoration: BoxDecoration(
                  color: themeState.fieldBg,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                  border: Border.all(color: themeState.fieldBorder),
                ),
                padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline,
                      color: themeState.textSecondary,
                      size: ResponsiveHelper.getResponsiveIconSize(context, 20),
                    ),
                    SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    Expanded(
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeState.textPrimary,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your email address',
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: themeState.textSecondary,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
              // Send Reset Link button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: ResponsiveHelper.getResponsiveButtonPadding(context, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: ResponsiveHelper.getResponsiveSpacing(context, 20),
                          width: ResponsiveHelper.getResponsiveSpacing(context, 20),
                          child: const CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Send Reset Link',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 100)),
              // Remembered password link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Remembered your password? ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: themeState.textSecondary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Log In',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
}
