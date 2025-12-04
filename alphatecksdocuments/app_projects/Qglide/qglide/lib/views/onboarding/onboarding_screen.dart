import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/login_screen.dart';
import '../../utils/responsive_helper.dart';
import '../../cubits/theme_cubit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardData> _pages = const [
    _OnboardData(
      imagePath: 'assets/images/destination.png',
      title: 'Your Destination,\nOur Priority',
      subtitle:
          'Book a ride in seconds. Safe, reliable, and affordable travel across Qatar with verified drivers.',
    ),
    _OnboardData(
      imagePath: 'assets/images/second.png',
      title: "Join Qatar's\nTrusted Community",
      subtitle:
          'Connect with verified drivers and trusted users. Rate, review, and build a safer mobility community together.',
    ),
  ];

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, themeState) {
        final base = ResponsiveHelper.getBaseScale(context);
        final lastIndex = _pages.length - 1;

        return Scaffold(
          backgroundColor: themeState.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, index) {
                    final data = _pages[index];
                    return _OnboardingSlide(data: data, base: base, themeState: themeState);
                  },
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) {
                  final isActive = i == _currentIndex;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4 * base),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      width: isActive ? 36 * base : 8 * base,
                      height: 8 * base,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.gold : themeState.fieldBorder,
                        borderRadius: BorderRadius.circular(8 * base),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 24 * base),
              // Bottom actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      _goToLogin(context);
                    },
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: themeState.textSecondary,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentIndex >= lastIndex) {
                        _goToLogin(context);
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    icon: Icon(Icons.arrow_right_alt_rounded, size: 24 * base),
                    label: Text(
                      _currentIndex < lastIndex ? 'Next' : 'Done',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 24 * base, vertical: 14 * base),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24 * base),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8 * base),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data, required this.base, required this.themeState});

  final _OnboardData data;
  final double base;
  final ThemeState themeState;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getResponsiveBorderRadius(context, 24)),
          child: AspectRatio(
            aspectRatio: 1.1,
            child: Image.asset(
              data.imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 32)),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: themeState.textPrimary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 34),
            height: 1.2,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: themeState.textSecondary,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            height: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OnboardData {
  final String imagePath;
  final String title;
  final String subtitle;
  const _OnboardData({required this.imagePath, required this.title, required this.subtitle});
}
