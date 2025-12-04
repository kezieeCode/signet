import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../main_navigation/main_navigation_screen.dart';
import '../../utils/responsive_helper.dart';
import '../../cubits/theme_cubit.dart';
import '../../services/api_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/call_service.dart';

class VerificationScreen extends StatefulWidget {
  final String contactInfo; // Can be phone number or email
  
  const VerificationScreen({
    super.key,
    required this.contactInfo,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  bool _canResend = true;
  int _resendCountdown = 0;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
        return _resendCountdown > 0;
      }
      return false;
    }).then((_) {
      if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {}); // Trigger rebuild to update button state
  }

  bool _isCodeComplete() {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((controller) => controller.text).join();
    if (code.length == 4) {
      setState(() {
        _isVerifying = true;
      });
      
      try {
        // Call the API for OTP verification
        final response = await ApiService.verifyOtp(
          email: widget.contactInfo,
          otp: code,
        );
        
        if (response['success']) {
          // Extract and store access token (user type already stored during signup)
          final data = response['data'];
          if (data != null && data['access_token'] != null) {
            await ApiService.setAccessToken(data['access_token'], userType: 'rider');
          }
          
          // Register FCM token after successful verification/login
          await PushNotificationService.sendCurrentTokenToBackend();
          
          // Register Zego Cloud after auth so incoming calls can reach this device
          // CRITICAL: Don't block verification if Zego initialization fails - it can be retried later
          try {
            await CallService.initialize().timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                print('⚠️ CallService initialization timed out during verification - will retry later');
                // Show warning but don't block verification
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Call service initialization timed out. Calls will work when you try to make one.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            );
          } catch (e) {
            // Log error and show warning - calls can be initialized when needed
            print('⚠️ CallService initialization failed during verification: $e');
            print('   This is non-critical - calls will be initialized when needed');
            
            // Show error details to user so they can see what went wrong
            if (mounted) {
              final errorMsg = e.toString();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    errorMsg.length > 150 
                      ? 'Call init failed: ${errorMsg.substring(0, 150)}...' 
                      : 'Call init failed: $errorMsg'
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            }
          }
          
          // Show success message from API
          final successMessage = response['data']?['message'] ?? response['message'] ?? 'OTP verified successfully!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to main navigation screen (home with bottom navigation)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        } else {
          // Extract error message from API response
          String errorMessage = 'OTP verification failed. Please try again.';
          
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
                            error['otp'] ?? 
                            error['email'] ?? 
                            'OTP verification failed. Please try again.';
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
          setState(() {
            _isVerifying = false;
          });
        }
      }
    }
  }

  Future<void> _resendCode() async {
    if (_canResend) {
      try {
        // Call the API for resending OTP
        final response = await ApiService.resendOtp(
          email: widget.contactInfo,
        );
        
        if (response['success']) {
          // Start countdown
          _startResendCountdown();
          
          // Show success message from API
          final successMessage = response['data']?['message'] ?? response['message'] ?? 'Verification code resent successfully!';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Extract error message from API response
          String errorMessage = 'Failed to resend verification code. Please try again.';
          
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
                            'Failed to resend verification code. Please try again.';
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = ResponsiveHelper.getBaseScale(context);
    
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Scaffold(
          backgroundColor: themeState.isDarkTheme ? const Color(0xFF0D182E) : Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            width: 40 * base,
            height: 40 * base,
            decoration: BoxDecoration(
              color: themeState.isDarkTheme ? const Color(0xFF223149) : Colors.white,
              borderRadius: BorderRadius.circular(20 * base),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.amber,
              size: 20 * base,
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
              // Title
              Text(
                'Verification Code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              // Description
              Text(
                'We have sent a 4-digit verification code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Text(
                'to ${widget.contactInfo}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 48)),
              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) {
                  return Container(
                    width: ResponsiveHelper.getResponsiveSpacing(context, 60),
                    height: ResponsiveHelper.getResponsiveSpacing(context, 60),
                    decoration: BoxDecoration(
                      color: themeState.isDarkTheme ? const Color(0xFF223149) : Colors.white,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
                      border: Border.all(
                        color: _focusNodes[index].hasFocus 
                            ? Colors.amber 
                            : (themeState.isDarkTheme ? const Color(0xFF223149) : Colors.grey.shade300),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: themeState.textPrimary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (value) => _onDigitChanged(value, index),
                    ),
                  );
                }),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
              // Resend section
              Text(
                "Didn't receive the code?",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              GestureDetector(
                onTap: _canResend ? () async => await _resendCode() : null,
                child: Text(
                  _canResend ? 'Resend Code' : 'Resend Code (${_resendCountdown}s)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _canResend ? Colors.amber : themeState.textSecondary,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 100)), // Fixed spacing instead of Spacer
              // Verify button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : () async {
                    final code = _controllers.map((controller) => controller.text).join();
                    if (code.length == 4) {
                      await _verifyCode();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCodeComplete() ? Colors.amber : (themeState.isDarkTheme ? const Color(0xFF223149) : Colors.grey.shade300),
                    foregroundColor: _isCodeComplete() ? Colors.black : themeState.textPrimary,
                    padding: ResponsiveHelper.getResponsiveButtonPadding(context, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying 
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isCodeComplete() ? Colors.black : themeState.textPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Verify',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                ),
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
