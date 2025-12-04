import 'package:flutter/material.dart';

class ResponsiveHelper {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getShortestSide(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide;
  }

  static double getLongestSide(BuildContext context) {
    return MediaQuery.of(context).size.longestSide;
  }

  // Base scaling factor (375 is iPhone 8 width)
  static double getBaseScale(BuildContext context) {
    final shortest = getShortestSide(context);
    return (shortest / 375).clamp(0.8, 1.4);
  }

  // Height scaling factor (812 is iPhone 8 height)
  static double getHeightScale(BuildContext context) {
    final height = getScreenHeight(context);
    return (height / 812).clamp(0.7, 1.2);
  }

  // Responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final base = getBaseScale(context);
    final heightScale = getHeightScale(context);
    return (baseFontSize * base * heightScale).clamp(baseFontSize * 0.8, baseFontSize * 1.3);
  }

  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final base = getBaseScale(context);
    final heightScale = getHeightScale(context);
    return (baseSpacing * base * heightScale).clamp(baseSpacing * 0.7, baseSpacing * 1.3);
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double horizontal = 24,
    double vertical = 16,
  }) {
    final base = getBaseScale(context);
    final heightScale = getHeightScale(context);
    return EdgeInsets.symmetric(
      horizontal: (horizontal * base).clamp(16, 32),
      vertical: (vertical * base * heightScale).clamp(12, 24),
    );
  }

  // Responsive logo size
  static double getResponsiveLogoSize(BuildContext context, {double multiplier = 0.32}) {
    final shortest = getShortestSide(context);
    final base = getBaseScale(context);
    return (shortest * multiplier * base).clamp(80, 200);
  }

  // Check if screen is small
  static bool isSmallScreen(BuildContext context) {
    return getShortestSide(context) < 400;
  }

  // Check if screen is very small
  static bool isVerySmallScreen(BuildContext context) {
    return getShortestSide(context) < 350;
  }

  // Check if screen is large
  static bool isLargeScreen(BuildContext context) {
    return getShortestSide(context) > 500;
  }

  // Responsive button padding
  static EdgeInsets getResponsiveButtonPadding(BuildContext context, {
    double horizontal = 24,
    double vertical = 16,
  }) {
    final base = getBaseScale(context);
    final heightScale = getHeightScale(context);
    return EdgeInsets.symmetric(
      horizontal: (horizontal * base).clamp(16, 32),
      vertical: (vertical * base * heightScale).clamp(12, 20),
    );
  }

  // Responsive border radius
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    final base = getBaseScale(context);
    return (baseRadius * base).clamp(baseRadius * 0.8, baseRadius * 1.2);
  }

  // Responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseIconSize) {
    final base = getBaseScale(context);
    return (baseIconSize * base).clamp(baseIconSize * 0.8, baseIconSize * 1.2);
  }
}
