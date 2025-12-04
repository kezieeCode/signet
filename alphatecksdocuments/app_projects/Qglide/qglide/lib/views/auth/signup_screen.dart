import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'verification_screen.dart';
import 'document_verification_screen.dart';
import '../../utils/responsive_helper.dart';
import '../../cubits/theme_cubit.dart';
import '../../services/api_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  int _roleIndex = 0; // 0 rider, 1 driver
  bool _obscure1 = true;
  bool _obscure2 = true;

  // Preferences
  bool _pushNotif = true;
  bool _location = true;
  bool _marketing = false;

  // Consents
  bool _agreeTos = false;
  bool _confirmAge = false;
  bool _identityVerify = false;
  
  // Loading state
  bool _isLoading = false;

  // Form controllers - Separate for rider and driver
  // Rider controllers
  final TextEditingController _riderFirstNameCtrl = TextEditingController();
  final TextEditingController _riderLastNameCtrl = TextEditingController();
  final TextEditingController _riderEmailCtrl = TextEditingController();
  final TextEditingController _riderPass1Ctrl = TextEditingController();
  final TextEditingController _riderPass2Ctrl = TextEditingController();
  final TextEditingController _riderPhoneCtrl = TextEditingController();
  final TextEditingController _riderDateOfBirthCtrl = TextEditingController();
  
  // Driver controllers
  final TextEditingController _driverFirstNameCtrl = TextEditingController();
  final TextEditingController _driverLastNameCtrl = TextEditingController();
  final TextEditingController _driverEmailCtrl = TextEditingController();
  final TextEditingController _driverPass1Ctrl = TextEditingController();
  final TextEditingController _driverPass2Ctrl = TextEditingController();
  final TextEditingController _driverPhoneCtrl = TextEditingController();
  final TextEditingController _driverDateOfBirthCtrl = TextEditingController();
  
  // Current controllers (getters for active role)
  TextEditingController get _firstNameCtrl => _roleIndex == 0 ? _riderFirstNameCtrl : _driverFirstNameCtrl;
  TextEditingController get _lastNameCtrl => _roleIndex == 0 ? _riderLastNameCtrl : _driverLastNameCtrl;
  TextEditingController get _emailCtrl => _roleIndex == 0 ? _riderEmailCtrl : _driverEmailCtrl;
  TextEditingController get _pass1Ctrl => _roleIndex == 0 ? _riderPass1Ctrl : _driverPass1Ctrl;
  TextEditingController get _pass2Ctrl => _roleIndex == 0 ? _riderPass2Ctrl : _driverPass2Ctrl;
  TextEditingController get _phoneCtrl => _roleIndex == 0 ? _riderPhoneCtrl : _driverPhoneCtrl;
  TextEditingController get _dateOfBirthCtrl => _roleIndex == 0 ? _riderDateOfBirthCtrl : _driverDateOfBirthCtrl;
  
  // Password strength state - Separate for rider and driver
  // Rider password strength
  int _riderStrengthScore = 0;
  bool _riderReqLen = false;
  bool _riderReqNum = false;
  bool _riderReqSpecial = false;
  bool _riderReqUpperLower = false;
  
  // Driver password strength
  int _driverStrengthScore = 0;
  bool _driverReqLen = false;
  bool _driverReqNum = false;
  bool _driverReqSpecial = false;
  bool _driverReqUpperLower = false;
  
  // Current password strength (getters for active role)
  int get _strengthScore => _roleIndex == 0 ? _riderStrengthScore : _driverStrengthScore;
  bool get _reqLen => _roleIndex == 0 ? _riderReqLen : _driverReqLen;
  bool get _reqNum => _roleIndex == 0 ? _riderReqNum : _driverReqNum;
  bool get _reqSpecial => _roleIndex == 0 ? _riderReqSpecial : _driverReqSpecial;
  bool get _reqUpperLower => _roleIndex == 0 ? _riderReqUpperLower : _driverReqUpperLower;
  

  @override
  void initState() {
    super.initState();
    // Add listeners to both rider and driver password controllers
    _riderPass1Ctrl.addListener(_updateStrength);
    _driverPass1Ctrl.addListener(_updateStrength);
  }

  @override
  void dispose() {
    // Dispose rider controllers
    _riderFirstNameCtrl.dispose();
    _riderLastNameCtrl.dispose();
    _riderEmailCtrl.dispose();
    _riderPass1Ctrl.dispose();
    _riderPass2Ctrl.dispose();
    _riderPhoneCtrl.dispose();
    _riderDateOfBirthCtrl.dispose();
    
    // Dispose driver controllers
    _driverFirstNameCtrl.dispose();
    _driverLastNameCtrl.dispose();
    _driverEmailCtrl.dispose();
    _driverPass1Ctrl.dispose();
    _driverPass2Ctrl.dispose();
    _driverPhoneCtrl.dispose();
    _driverDateOfBirthCtrl.dispose();
    
    super.dispose();
  }
  
  // Registration method
  Future<void> _register() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Call the appropriate API based on user type
      final response = _roleIndex == 0 
        ? await ApiService.registerUser(
            email: _emailCtrl.text.trim(),
            password: _pass1Ctrl.text,
            confirmPassword: _pass2Ctrl.text,
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            phoneNumber: _phoneCtrl.text.trim(),
            dateOfBirth: _dateOfBirthCtrl.text.trim(),
          )
        : await ApiService.driverSignup(
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phoneNumber: _phoneCtrl.text.trim(),
            dateOfBirth: _dateOfBirthCtrl.text.trim(),
            password: _pass1Ctrl.text,
            confirmPassword: _pass2Ctrl.text,
          );
      
      if (response['success']) {
        // Extract and store access token and user type if provided
        final data = response['data'];
        if (data != null && data['access_token'] != null) {
          final userType = _roleIndex == 0 ? 'rider' : 'driver';
          await ApiService.setAccessToken(data['access_token'], userType: userType);
        }
        
        // Show success message from API
        final successMessage = response['data']?['message'] ?? response['message'] ?? '${_roleIndex == 0 ? "Rider" : "Driver"} account created successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate based on user type
        if (_roleIndex == 0) {
          // Rider - navigate to email verification
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => VerificationScreen(contactInfo: _emailCtrl.text)),
          );
        } else {
          // Driver - navigate to document verification
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentVerificationScreen(
                email: _emailCtrl.text.trim(),
                password: _pass1Ctrl.text,
              ),
            ),
          );
        }
      } else {
        // Extract error message from API response
        String errorMessage = 'Registration failed. Please try again.';
        
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
                          'Registration failed. Please try again.';
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  bool _validateForm() {
    if (_firstNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name')),
      );
      return false;
    }
    
    if (_lastNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your last name')),
      );
      return false;
    }
    
    if (_emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email')),
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
    
    if (_pass1Ctrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return false;
    }
    
    if (_pass2Ctrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm your password')),
      );
      return false;
    }
    
    if (_pass1Ctrl.text != _pass2Ctrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return false;
    }
    
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return false;
    }
    
    if (_dateOfBirthCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your date of birth')),
      );
      return false;
    }
    
    if (!_agreeTos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Service')),
      );
      return false;
    }
    
    if (!_confirmAge) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm your age')),
      );
      return false;
    }
    
    return true;
  }

  void _updateStrength() {
    final text = _pass1Ctrl.text;
    final hasLen = text.length >= 8;
    final hasNum = RegExp(r'[0-9]').hasMatch(text);
    final hasSpecial = RegExp(r'[!@#\$%\^&*()_+\-=[\]{};:.,<>/?`~]').hasMatch(text);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(text);
    final hasLower = RegExp(r'[a-z]').hasMatch(text);
    final hasUpperLower = hasUpper && hasLower;
    int score = 0;
    if (hasLen) score++;
    if (hasNum) score++;
    if (hasSpecial) score++;
    if (hasUpperLower) score++;
    
    setState(() {
      if (_roleIndex == 0) {
        // Update rider password strength
        _riderReqLen = hasLen;
        _riderReqNum = hasNum;
        _riderReqSpecial = hasSpecial;
        _riderReqUpperLower = hasUpperLower;
        _riderStrengthScore = score;
      } else {
        // Update driver password strength
        _driverReqLen = hasLen;
        _driverReqNum = hasNum;
        _driverReqSpecial = hasSpecial;
        _driverReqUpperLower = hasUpperLower;
        _driverStrengthScore = score;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final base = ResponsiveHelper.getBaseScale(context);
        final logoSize = ResponsiveHelper.getResponsiveLogoSize(context, multiplier: 0.5);

        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          body: SafeArea(
            child: Padding(
              padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Static Back to Login header
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(foregroundColor: themeState.textSecondary),
                  icon: Icon(Icons.arrow_back, size: ResponsiveHelper.getResponsiveIconSize(context, 20)),
                  label: Text('Back to Login', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16))),
                ),
              ),
              SizedBox(height: 4 * base),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Centered logo
                      Center(
                        child: Image.asset(
                            themeState.isDarkTheme ? 'assets/images/QGlide Logo w.png' : 'assets/images/logo.webp',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Remove space between logo and text
                      Transform.translate(
                        offset: Offset(0, -ResponsiveHelper.getResponsiveSpacing(context, 48)),
                        child: Text('Create Account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: themeState.textPrimary, 
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 28), 
                            fontWeight: FontWeight.w800,
                          )),
                        ),
                      // Remove space between texts
                      Transform.translate(
                        offset: Offset(0, -ResponsiveHelper.getResponsiveSpacing(context, 16)),
                        child: Text(
                          "Join Qatar's most reliable ride sharing platform",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: themeState.textSecondary, 
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                        ),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                      // Role cards
                      Row(
                        children: [
                          Expanded(child: _roleCard(base, 0, Icons.person, 'Rider', 'Book rides & deliveries', themeState)),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Expanded(child: _roleCard(base, 1, Icons.directions_car, 'Driver', 'Earn with your car', themeState)),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 24)),
                      Text('Personal Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: themeState.textPrimary, 
                            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22), 
                            fontWeight: FontWeight.w800,
                          )),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      // First Name and Last Name fields
                      Row(
                        children: [
                          Expanded(child: _textField(base: base, hint: 'First Name', icon: Icons.person_outline, controller: _firstNameCtrl, themeState: themeState)),
                          SizedBox(width: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                          Expanded(child: _textField(base: base, hint: 'Last Name', icon: Icons.person_outline, controller: _lastNameCtrl, themeState: themeState)),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      // Email field
                      _textField(base: base, hint: 'Email Address', icon: Icons.email_outlined, controller: _emailCtrl, themeState: themeState),
                      SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 12)),
                      // Phone Number field
                      _textField(
                        base: base,
                        hint: 'Enter your phone number',
                        icon: Icons.phone_iphone,
                        controller: _phoneCtrl,
                        themeState: themeState,
                      ),
                      SizedBox(height: 12 * base),
                      _datePickerField(base: base, themeState: themeState),
                      SizedBox(height: 24 * base),
                      Text('Security',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: themeState.textPrimary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22), fontWeight: FontWeight.w800)),
                      SizedBox(height: 12 * base),
                      _passwordField(
                        base: base,
                        controller: _pass1Ctrl,
                        hint: 'Create a strong password',
                        obscure: _obscure1,
                        onToggle: () {
                          setState(() => _obscure1 = !_obscure1);
                        },
                        themeState: themeState,
                      ),
                      SizedBox(height: 12 * base),
                      _passwordField(
                        base: base,
                        controller: _pass2Ctrl,
                        hint: 'Confirm your password',
                        obscure: _obscure2,
                        onToggle: () {
                          setState(() => _obscure2 = !_obscure2);
                        },
                        themeState: themeState,
                      ),
                      SizedBox(height: 12 * base),
                      // Strength indicators (dynamic)
                      Row(
                        children: [
                          _strengthBar(base, active: _strengthScore >= 1, themeState: themeState),
                          _strengthBar(base, active: _strengthScore >= 2, themeState: themeState),
                          _strengthBar(base, active: _strengthScore >= 3, themeState: themeState),
                          _strengthBar(base, active: _strengthScore >= 4, themeState: themeState),
                        ],
                      ),
                      SizedBox(height: 12 * base),
                      Wrap(
                        spacing: ResponsiveHelper.getResponsiveSpacing(context, 20),
                        runSpacing: ResponsiveHelper.getResponsiveSpacing(context, 8),
                        children: [
                          _bullet(base, '8+ characters', met: _reqLen, themeState: themeState),
                          _bullet(base, 'Numbers', met: _reqNum, themeState: themeState),
                          _bullet(base, 'Special characters', met: _reqSpecial, themeState: themeState),
                          _bullet(base, 'Upper & lowercase', met: _reqUpperLower, themeState: themeState),
                        ],
                      ),
                      SizedBox(height: 24 * base),
                      // Preferences section
                      Text('Preferences',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: themeState.textPrimary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22), fontWeight: FontWeight.w800)),
                      SizedBox(height: 12 * base),
                      _preferenceRow(
                        base: base,
                        icon: Icons.notifications_active_outlined,
                        title: 'Push Notifications',
                        subtitle: 'Get updates about your rides',
                        value: _pushNotif,
                        onChanged: (v) => setState(() => _pushNotif = v),
                        themeState: themeState,
                      ),
                      SizedBox(height: 12 * base),
                      _preferenceRow(
                        base: base,
                        icon: Icons.location_on_outlined,
                        title: 'Location Services',
                        subtitle: 'Required for ride booking',
                        value: _location,
                        onChanged: (v) => setState(() => _location = v),
                        themeState: themeState,
                      ),
                      SizedBox(height: 12 * base),
                      _preferenceRow(
                        base: base,
                        icon: Icons.mail_outline,
                        title: 'Marketing Emails',
                        subtitle: 'Promotions and offers',
                        value: _marketing,
                        onChanged: (v) => setState(() => _marketing = v),
                        themeState: themeState,
                      ),
                      SizedBox(height: 20 * base),
                      // Consents
                      _checkboxRow(
                        base: base,
                        value: _agreeTos,
                        onChanged: (v) => setState(() => _agreeTos = v ?? false),
                        richText: Text.rich(
                          TextSpan(children: [
                            TextSpan(text: "I agree to QGlide's ", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: themeState.textSecondary)),
                            TextSpan(text: 'Terms of Service', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700)),
                            TextSpan(text: ' and acknowledge that I have read the ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: themeState.textSecondary)),
                            TextSpan(text: 'Privacy Policy', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                        themeState: themeState,
                      ),
                      SizedBox(height: 12 * base),
                      _checkboxRow(
                        base: base,
                        value: _confirmAge,
                        onChanged: (v) => setState(() => _confirmAge = v ?? false),
                        text:
                            'I confirm that I am at least 18 years old and legally able to enter into this agreement',
                        themeState: themeState,
                      ),
                      SizedBox(height: 12 * base),
                      _checkboxRow(
                        base: base,
                        value: _identityVerify,
                        onChanged: (v) => setState(() => _identityVerify = v ?? false),
                        text:
                            'I understand that my identity may need to be verified for safety and security purposes',
                        themeState: themeState,
                      ),
                      SizedBox(height: 24 * base),
                      // Social signup buttons
                      Row(
                        children: [
                          Expanded(
                            child: _socialButton(
                              base: base,
                              icon: FontAwesomeIcons.google,
                              label: 'Google',
                              themeState: themeState,
                            ),
                          ),
                          SizedBox(width: 12 * base),
                          Expanded(
                            child: _socialButton(
                              base: base,
                              icon: FontAwesomeIcons.apple,
                              label: 'Apple',
                              themeState: themeState,
                            ),
                          ),
                          SizedBox(width: 12 * base),
                          Expanded(
                            child: _socialButton(
                              base: base,
                              icon: FontAwesomeIcons.facebook,
                              label: 'Facebook',
                              themeState: themeState,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16 * base),
                      // Create Account CTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
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
                            : Text('Create Account',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18), 
                                  fontWeight: FontWeight.w800,
                                )),
                        ),
                      ),
                      SizedBox(height: 8 * base),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _preferenceRow({
    required double base,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeState themeState,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: themeState.textPrimary, size: 22 * base),
        SizedBox(width: 12 * base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: themeState.textPrimary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18), fontWeight: FontWeight.w700)),
              SizedBox(height: 4 * base),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: themeState.textSecondary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14))),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.black,
          activeTrackColor: AppColors.gold,
          inactiveThumbColor: themeState.fieldBorder,
          inactiveTrackColor: themeState.fieldBg,
        ),
      ],
    );
  }

  Widget _checkboxRow({
    required double base,
    required bool value,
    required ValueChanged<bool?> onChanged,
    String? text,
    Widget? richText,
    required ThemeState themeState,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24 * base,
          height: 24 * base,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.gold,
            side: BorderSide(color: themeState.fieldBorder),
          ),
        ),
        SizedBox(width: 12 * base),
        Expanded(
          child: richText ?? Text(text ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: themeState.textSecondary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15))),
        ),
      ],
    );
  }

  Widget _roleCard(double base, int index, IconData icon, String title, String subtitle, ThemeState themeState) {
    final isActive = _roleIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _roleIndex = index;
          // Clear form validation states when switching roles
          // This ensures clean state for each role
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(16 * base),
        decoration: BoxDecoration(
          color: isActive ? AppColors.gold : themeState.fieldBg,
          borderRadius: BorderRadius.circular(16 * base),
          border: Border.all(color: isActive ? AppColors.gold : themeState.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isActive ? Colors.black : themeState.textPrimary, size: 28 * base),
            SizedBox(height: 8 * base),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isActive ? Colors.black : themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                  fontWeight: FontWeight.w800,
                )),
            SizedBox(height: 6 * base),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isActive ? Colors.black87 : themeState.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                )),
          ],
        ),
      ),
    );
  }


  Widget _textField({required double base, required String hint, required IconData icon, TextEditingController? controller, required ThemeState themeState}) {
    return Container(
      decoration: BoxDecoration(
        color: themeState.fieldBg,
        borderRadius: BorderRadius.circular(12 * base),
        border: Border.all(color: themeState.fieldBorder),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12 * base),
      child: Row(
        children: [
          Icon(icon, color: themeState.textSecondary, size: 20 * base),
          SizedBox(width: 12 * base),
          Expanded(
            child: TextField(
              controller: controller,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: themeState.textPrimary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: themeState.textSecondary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required double base,
    TextEditingController? controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required ThemeState themeState,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: themeState.fieldBg,
        borderRadius: BorderRadius.circular(12 * base),
        border: Border.all(color: themeState.fieldBorder),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12 * base),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: themeState.textSecondary, size: 20 * base),
          SizedBox(width: 12 * base),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => _updateStrength(),
              obscureText: obscure,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: themeState.textPrimary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: themeState.textSecondary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16)),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: themeState.textSecondary, size: 20 * base),
          ),
        ],
      ),
    );
  }

  Widget _strengthBar(double base, {bool active = false, required ThemeState themeState}) {
    return Expanded(
      child: Container(
        height: 6 * base,
        margin: EdgeInsets.only(right: 8 * base),
        decoration: BoxDecoration(
          color: active ? AppColors.gold : themeState.fieldBorder,
          borderRadius: BorderRadius.circular(4 * base),
        ),
      ),
    );
  }

  Widget _bullet(double base, String text, {required bool met, required ThemeState themeState}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10 * base,
          height: 10 * base,
          decoration: BoxDecoration(color: met ? AppColors.gold : themeState.fieldBorder, shape: BoxShape.circle),
        ),
        SizedBox(width: 8 * base),
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: met ? themeState.textPrimary : themeState.textSecondary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14), fontWeight: met ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }

  Widget _socialButton({required double base, required IconData icon, required String label, required ThemeState themeState}) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: FaIcon(icon, color: themeState.textPrimary, size: ResponsiveHelper.getResponsiveIconSize(context, 16)),
      label: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: themeState.textPrimary, fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11), fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: themeState.fieldBorder),
        backgroundColor: themeState.fieldBg,
        padding: EdgeInsets.symmetric(vertical: 10 * base, horizontal: 8 * base),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * base)),
      ),
    );
  }

  Widget _datePickerField({required double base, required ThemeState themeState}) {
    return GestureDetector(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // Default to 18 years ago
          firstDate: DateTime(1900),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // Minimum 13 years old
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.gold,
                  onPrimary: Colors.black,
                  onSurface: themeState.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (pickedDate != null) {
          // Format date as YYYY-MM-DD for the API
          final formattedDate = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
          _dateOfBirthCtrl.text = formattedDate;
          setState(() {}); // Trigger rebuild to show selected date
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: themeState.fieldBg,
          borderRadius: BorderRadius.circular(12 * base),
          border: Border.all(color: themeState.fieldBorder),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12 * base),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: themeState.textSecondary, size: 20 * base),
            SizedBox(width: 12 * base),
            Expanded(
              child: Text(
                _dateOfBirthCtrl.text.isEmpty ? 'Select your date of birth' : _dateOfBirthCtrl.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _dateOfBirthCtrl.text.isEmpty ? themeState.textSecondary : themeState.textPrimary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: themeState.textSecondary, size: 24 * base),
          ],
        ),
      ),
    );
  }
}
