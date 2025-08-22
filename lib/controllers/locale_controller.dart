import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends GetxController {
  static const String _localeKey = 'selected_locale';

  final Rx<Locale> _locale = const Locale('en', 'US').obs;
  Locale get locale => _locale.value;

  // Current language code for dropdown
  String get currentLanguage => _locale.value.languageCode;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLocale();
  }

  void _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);

    if (localeCode != null) {
      if (localeCode == 'vi_VN') {
        _locale.value = const Locale('vi', 'VN');
      } else {
        _locale.value = const Locale('en', 'US');
      }
      Get.updateLocale(_locale.value);
    }
  }

  void changeLocale(Locale newLocale) async {
    _locale.value = newLocale;
    Get.updateLocale(newLocale);

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localeKey,
      '${newLocale.languageCode}_${newLocale.countryCode}',
    );
  }

  // Change locale from language code string
  void changeLocaleFromString(String languageCode) {
    if (languageCode == 'vi') {
      changeLocale(const Locale('vi', 'VN'));
    } else {
      changeLocale(const Locale('en', 'US'));
    }
  }

  void toggleLocale() {
    if (_locale.value.languageCode == 'en') {
      changeLocale(const Locale('vi', 'VN'));
    } else {
      changeLocale(const Locale('en', 'US'));
    }
  }

  bool get isVietnamese => _locale.value.languageCode == 'vi';
  bool get isEnglish => _locale.value.languageCode == 'en';
}
