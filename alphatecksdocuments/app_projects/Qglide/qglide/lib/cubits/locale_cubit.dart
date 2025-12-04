import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Locale State
class LocaleState {
  final Locale locale;

  LocaleState(this.locale);

  bool get isArabic => locale.languageCode == 'ar';
  bool get isEnglish => locale.languageCode == 'en';
}

// Locale Cubit
class LocaleCubit extends Cubit<LocaleState> {
  static const String _localeKey = 'app_locale';

  LocaleCubit() : super(LocaleState(const Locale('en'))) {
    _loadSavedLocale();
  }

  // Load saved locale from SharedPreferences
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);      
      if (savedLocale != null) {
        if (savedLocale == 'ar') {
          emit(LocaleState(const Locale('ar')));
        } else {
          emit(LocaleState(const Locale('en')));
        }
      }
    } catch (e) {
      // Silent error handling
    }
  }

  // Set locale to English
  Future<void> setEnglish() async {
    await setLocale('en');
  }

  // Set locale to Arabic
  Future<void> setArabic() async {
    await setLocale('ar');
  }

  // Set locale with language code
  Future<void> setLocale(String languageCode) async {
    try {      
      final newLocale = Locale(languageCode);
      emit(LocaleState(newLocale));
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, languageCode);
    } catch (e) {
      // Silent error handling
    }
  }

  // Toggle between English and Arabic
  Future<void> toggleLocale() async {
    if (state.isEnglish) {
      await setArabic();
    } else {
      await setEnglish();
    }
  }
}

