import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'theme_mode';

  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;
  ThemeMode get themeMode => _themeMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'light';

    switch (themeString) {
      case 'dark':
        _themeMode.value = ThemeMode.dark;
        break;
      case 'light':
      default:
        _themeMode.value = ThemeMode.light;
        break;
    }

    Get.changeThemeMode(_themeMode.value);
  }

  Future<void> changeTheme(ThemeMode themeMode) async {
    _themeMode.value = themeMode;
    Get.changeThemeMode(themeMode);

    final prefs = await SharedPreferences.getInstance();
    String themeString = themeMode == ThemeMode.dark ? 'dark' : 'light';
    await prefs.setString(_themeKey, themeString);
  }

  bool get isLightTheme => _themeMode.value == ThemeMode.light;
  bool get isDarkTheme => _themeMode.value == ThemeMode.dark;
}
