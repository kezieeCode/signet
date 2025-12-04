import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../utils/responsive_helper.dart';
import '../../cubits/theme_cubit.dart';
import '../../services/api_service.dart';
import '../../utils/crash_logger.dart';
import '../onboarding/onboarding_screen.dart';
import '../main_navigation/main_navigation_screen.dart';
import '../driver/driver_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _trackController;
  late AnimationController _logoController;
  late AnimationController _glowController;
  
  late Animation<double> _trackAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Track animation controller
    _trackController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    
    // Glow animation controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Track rollout animation
    _trackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _trackController,
      curve: Curves.easeInOut,
    ));

    // Logo drive animation
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Logo scale animation (bounce effect)
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Logo rotation animation (disabled - keeping logo straight)
    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Glow animation
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    // Start track animation
    _trackController.forward();
    
    // Start logo animation after a short delay
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();
    
    // Start glow animation when logo reaches the end
    await Future.delayed(const Duration(milliseconds: 2000));
    _glowController.forward();
    
    // Navigate based on authentication status after animation completes
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      try {
        await CrashLogger.logInfo('Splash screen: Checking authentication status');
        
        // Check if user is authenticated
        final isAuthenticated = ApiService.isAuthenticated;
        await CrashLogger.logInfo('Splash screen: isAuthenticated = $isAuthenticated');
        
        if (isAuthenticated) {
          final userType = ApiService.userType;
          await CrashLogger.logInfo('Splash screen: userType = $userType');
          
          // Navigate to appropriate home page based on user type
          if (userType == 'driver') {
            await CrashLogger.logInfo('Splash screen: Navigating to DriverHomeScreen');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DriverHomeScreen()),
            );
          } else {
            await CrashLogger.logInfo('Splash screen: Navigating to MainNavigationScreen');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            );
          }
        } else {
          await CrashLogger.logInfo('Splash screen: Navigating to OnboardingScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      } catch (e, stackTrace) {
        await CrashLogger.logError('Splash screen navigation error', e, stackTrace);
        
        // Fallback: navigate to onboarding on error
        if (mounted) {
          try {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          } catch (navError) {
            await CrashLogger.logError('Splash screen: Failed to navigate to fallback screen', navError, null);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _trackController.dispose();
    _logoController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final logoSize = ResponsiveHelper.getResponsiveLogoSize(context, multiplier: 0.6);
        final screenWidth = MediaQuery.of(context).size.width;
        final trackLength = screenWidth;

        return Scaffold(
          backgroundColor: themeState.backgroundColor,
          body: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Railway Track
                AnimatedBuilder(
                  animation: _trackAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(trackLength, 100),
                      painter: RailwayTrackPainter(
                        progress: _trackAnimation.value,
                        isDarkTheme: themeState.isDarkTheme,
                      ),
                    );
                  },
                ),
                
                // Logo with drive animation
                AnimatedBuilder(
                  animation: _logoAnimation,
                  builder: (context, child) {
                    // Logo stops before reaching the end (80% of track length)
                    final logoMaxPosition = trackLength * 0.8;
                    final logoPosition = _logoAnimation.value * (logoMaxPosition - logoSize);
                    final logoScale = _logoScaleAnimation.value;
                    final logoRotation = _logoRotationAnimation.value;
                    
                    return Transform.translate(
                      offset: Offset(logoPosition - trackLength / 2 + logoSize / 2, -80), // Move logo higher above track
                      child: Transform.scale(
                        scale: logoScale,
                        child: Transform.rotate(
                          angle: logoRotation,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: _glowAnimation.value > 0 ? [
                                BoxShadow(
                                  color: AppColors.gold.withOpacity(0.3 * _glowAnimation.value),
                                  blurRadius: 20 * _glowAnimation.value,
                                  spreadRadius: 5 * _glowAnimation.value,
                                ),
                              ] : null,
                            ),
                            child: Image.asset(
                              themeState.isDarkTheme ? 'assets/images/QGlide Logo w.png' : 'assets/images/logo.webp',
                              width: logoSize,
                              height: logoSize,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RailwayTrackPainter extends CustomPainter {
  final double progress;
  final bool isDarkTheme;

  RailwayTrackPainter({
    required this.progress,
    required this.isDarkTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Track color based on theme
    final trackColor = isDarkTheme ? AppColors.gold : Colors.black;

    // Calculate track length based on progress
    final trackLength = size.width * progress;
    final centerY = size.height / 2;

    // Draw thick line
    final paint = Paint()
      ..strokeWidth = 80.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..color = trackColor;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(trackLength, centerY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is RailwayTrackPainter && oldDelegate.progress != progress;
  }
}
