import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../main_navigation/main_navigation_screen.dart';
import '../driver/driver_home_screen.dart';
import '../../utils/responsive_helper.dart';
import '../../cubits/theme_cubit.dart';
import '../../services/api_service.dart';
import '../../services/push_notification_service.dart';
import '../../services/call_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {

  late TabController _tabController;
  int _segmentedIndex = 0; // 0: Rider, 1: Driver, 2: Courier (all use email)
  bool _obscure = true;
  
  // Form controllers
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  
  // Focus nodes for keyboard navigation
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  
  // Loading state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {
        // Navigate to Signup when Sign Up tab selected
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        ).then((_) {
          // Return to Login tab when coming back
          if (mounted) _tabController.index = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
  
  // Signin method
  Future<void> _signin() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Call the appropriate API based on user type
      final response = _segmentedIndex == 0
        ? await ApiService.riderLogin(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          )
        : _segmentedIndex == 1
        ? await ApiService.driverLogin(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          )
        : await ApiService.driverLogin( // Courier uses driver login API
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      
      if (response['success']) {
        // Extract and store access token and user type
        final data = response['data'];
        
        // The actual API response is nested inside data
        final apiData = data?['data'] ?? data;
        
        // Extract user info from nested structure
        final user = apiData?['user'];
        final userMetadata = user?['user_metadata'];
        final firstName = userMetadata?['firstname'] ?? userMetadata?['first_name'];
        
        // Extract access token from session
        final session = apiData?['session'];
        final accessToken = session?['access_token'] ?? apiData?['access_token'] ?? user?['access_token'];
        
        if (accessToken != null) {
          final userType = _segmentedIndex == 0 
            ? 'rider' 
            : _segmentedIndex == 1 
            ? 'driver' 
            : 'courier';
          await ApiService.setAccessToken(
            accessToken, 
            userType: userType,
            firstName: firstName,
          );
        } else {
          // Store user type and firstname even without token
          final userType = _segmentedIndex == 0 
            ? 'rider' 
            : _segmentedIndex == 1 
            ? 'driver' 
            : 'courier';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_type', userType);
          if (firstName != null) {
            await prefs.setString('first_name', firstName);
          }
        }
        
        // Register FCM token after successful login
        await PushNotificationService.sendCurrentTokenToBackend();
        
        // Register Zego Cloud after auth (ensures token endpoint auth works)
        // CRITICAL: Don't block login if Zego initialization fails - it can be retried later
        try {
          await CallService.initialize().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⚠️ CallService initialization timed out during login - will retry later');
              // Show warning but don't block login
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
          print('⚠️ CallService initialization failed during login: $e');
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
        final successMessage = response['data']?['message'] ?? response['message'] ?? 'Login successful!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to appropriate screen based on user type
        if (_segmentedIndex == 0) {
          // Rider login - go to main navigation
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        } else {
          // Driver or Courier login - go to driver home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
          );
        }
      } else {
        // Extract error message from API response
        String errorMessage = 'Login failed. Please try again.';
        
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
                          error['password'] ?? 
                          'Login failed. Please try again.';
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
          _isLoading = false;
        });
      }
    }
  }
  
  bool _validateForm() {
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return false;
    }
    
    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }
    
    if (_passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your password')),
      );
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final base = ResponsiveHelper.getBaseScale(context);
        final logoSize = ResponsiveHelper.getResponsiveLogoSize(context, multiplier: 0.5);

        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: ResponsiveHelper.getResponsiveSpacing(context, 24),
                    right: ResponsiveHelper.getResponsiveSpacing(context, 24),
                    top: ResponsiveHelper.getResponsiveSpacing(context, 16),
                    bottom: MediaQuery.of(context).viewInsets.bottom + ResponsiveHelper.getResponsiveSpacing(context, 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                    // Centered QGlide logo (responsive)
                    Transform.translate(
                      offset: Offset(0, -ResponsiveHelper.getResponsiveSpacing(context, 24)),
                      child: Center(
                        child: Image.asset(
                          themeState.isDarkTheme ? 'assets/images/QGlide Logo w.png' : 'assets/images/logo.webp',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Negative margin to remove space
                    Transform.translate(
                      offset: Offset(0, -ResponsiveHelper.getResponsiveSpacing(context, 72)),
                      child: Text(
                        "Let's Get Started",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: themeState.textPrimary, 
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 30), 
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    // Remove space between texts
                    Transform.translate(
                      offset: Offset(0, -ResponsiveHelper.getResponsiveSpacing(context, 48)),
                      child: Text(
                        'Your reliable ride in Qatar.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeState.textSecondary, 
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                        ),
                      ),
                    ),
              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: AppColors.gold,
                unselectedLabelColor: themeState.textSecondary,
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColors.gold, width: 3),
                  insets: EdgeInsets.zero,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3 * base,
                labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18), 
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [Tab(text: 'Login'), Tab(text: 'Sign Up')],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              // Segmented control
              Container(
                decoration: BoxDecoration(
                  color: themeState.fieldBg,
                  borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
                ),
                padding: EdgeInsets.all(ResponsiveHelper.getResponsiveSpacing(context, 6)),
                child: Row(
                  children: [
                    _segmentButton('Rider', 0, base),
                    _segmentButton('Driver', 1, base),
                    _segmentButton('Courier', 2, base),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              // Fields
              _textField(
                base: base,
                hint: 'Enter your email',
                icon: Icons.mail_outlined,
                keyboardType: TextInputType.emailAddress,
                controller: _emailCtrl,
                focusNode: _emailFocusNode,
                onSubmitted: (_) {
                  // Move focus to password field when user presses next/done
                  _passwordFocusNode.requestFocus();
                },
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
              _passwordField(
                base: base, 
                controller: _passwordCtrl,
                focusNode: _passwordFocusNode,
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Forgot Password?', 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gold, 
                      fontWeight: FontWeight.w700, 
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    ),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 20)),
              // CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: ResponsiveHelper.getResponsiveButtonPadding(context, vertical: 16),
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
                          'Login', 
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18), 
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
              // Divider text
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: themeState.fieldBorder)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                    child: Text(
                      'or continue with', 
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeState.textSecondary, 
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: themeState.fieldBorder)),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              // Social buttons
              Row(
                children: [
                  Expanded(
                    child: _socialButton(
                      base: base,
                      icon: FontAwesomeIcons.google,
                      label: 'Google',
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                  Expanded(
                    child: _socialButton(
                      base: base,
                      icon: FontAwesomeIcons.apple,
                      label: 'Apple',
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 8)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _segmentButton(String label, int index, double base) {
    final isActive = _segmentedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segmentedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: ResponsiveHelper.getResponsiveButtonPadding(context, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 20)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive ? Colors.black : context.read<ThemeCubit>().state.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required double base, 
    required String hint, 
    required IconData icon, 
    TextInputType? keyboardType, 
    TextEditingController? controller,
    FocusNode? focusNode,
    ValueChanged<String>? onSubmitted,
  }) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Container(
          decoration: BoxDecoration(
            color: themeState.fieldBg,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            border: Border.all(color: themeState.fieldBorder),
          ),
          padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          child: Row(
            children: [
              Icon(icon, color: themeState.textSecondary, size: ResponsiveHelper.getResponsiveIconSize(context, 20)),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textInputAction: keyboardType == TextInputType.emailAddress ? TextInputAction.next : TextInputAction.done,
              onSubmitted: onSubmitted,
              autofillHints: keyboardType == TextInputType.emailAddress ? [AutofillHints.email] : null,
              autocorrect: keyboardType == TextInputType.emailAddress ? false : true,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeState.textPrimary, 
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              ),
              decoration: InputDecoration(
                hintText: hint,
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
    );
      },
    );
  }

  Widget _passwordField({
    required double base, 
    TextEditingController? controller,
    FocusNode? focusNode,
  }) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return Container(
          decoration: BoxDecoration(
            color: themeState.fieldBg,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            border: Border.all(color: themeState.fieldBorder),
          ),
          padding: EdgeInsets.symmetric(horizontal: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: themeState.textSecondary, size: ResponsiveHelper.getResponsiveIconSize(context, 20)),
          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                // Dismiss keyboard when done
                focusNode?.unfocus();
              },
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: themeState.textPrimary, 
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              ),
              decoration: const InputDecoration(
                hintText: 'Password',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility, 
              color: themeState.textSecondary, 
              size: ResponsiveHelper.getResponsiveIconSize(context, 20),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _socialButton({required double base, required IconData icon, required String label}) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        return OutlinedButton.icon(
          onPressed: () {},
          icon: FaIcon(icon, color: themeState.textPrimary, size: ResponsiveHelper.getResponsiveIconSize(context, 20)),
          label: Text(
            label, 
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeState.textPrimary, 
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16), 
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: themeState.fieldBorder),
            backgroundColor: themeState.fieldBg,
            padding: ResponsiveHelper.getResponsiveButtonPadding(context, vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 12)),
            ),
          ),
        );
      },
    );
  }
}
