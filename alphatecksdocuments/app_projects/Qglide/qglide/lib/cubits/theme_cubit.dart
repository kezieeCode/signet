import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

// Theme colors
class AppColors {
  static const Color gold = Color(0xFFD4AF37);
  
  // Light theme colors (default)
  static const Color lightBackground = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0D182E); // Navy blue as text
  static const Color lightTextSecondary = Color(0xFF4A5568);
  static const Color lightPanelBg = Color(0xFFF7FAFC);
  static const Color lightFieldBg = Color(0xFFEDF2F7);
  static const Color lightFieldBorder = Color(0xFFE2E8F0);
  
  // Dark theme colors
  static const Color darkBackground = Color(0xFF0D182E);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFB7C0D1);
  static const Color darkPanelBg = Color(0xFF1A2332);
  static const Color darkFieldBg = Color(0x112A3550);
  static const Color darkFieldBorder = Color(0xFF233147);
}

// Theme state
class ThemeState {
  final bool isDarkTheme;
  
  const ThemeState({this.isDarkTheme = false});
  
  // Theme getter methods
  Color get backgroundColor => isDarkTheme ? AppColors.darkBackground : AppColors.lightBackground;
  Color get textPrimary => isDarkTheme ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary => isDarkTheme ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get panelBg => isDarkTheme ? AppColors.darkPanelBg : AppColors.lightPanelBg;
  Color get fieldBg => isDarkTheme ? AppColors.darkFieldBg : AppColors.lightFieldBg;
  Color get fieldBorder => isDarkTheme ? AppColors.darkFieldBorder : AppColors.lightFieldBorder;
  
  ThemeState copyWith({bool? isDarkTheme}) {
    return ThemeState(isDarkTheme: isDarkTheme ?? this.isDarkTheme);
  }
  
  // Serialization for persistence
  Map<String, dynamic> toJson() {
    return {
      'isDarkTheme': isDarkTheme,
    };
  }
  
  factory ThemeState.fromJson(Map<String, dynamic> json) {
    return ThemeState(
      isDarkTheme: json['isDarkTheme'] as bool? ?? false,
    );
  }
}

// Theme cubit - now with automatic persistence
class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());
  
  void toggleTheme() {
    emit(state.copyWith(isDarkTheme: !state.isDarkTheme));  }
  
  void setTheme(bool isDark) {
    emit(state.copyWith(isDarkTheme: isDark));  }
  
  @override
  ThemeState? fromJson(Map<String, dynamic> json) {
    try {
      final theme = ThemeState.fromJson(json);      return theme;
    } catch (e) {      return null;
    }
  }
  
  @override
  Map<String, dynamic>? toJson(ThemeState state) {
    try {
      return state.toJson();
    } catch (e) {      return null;
    }
  }
}
