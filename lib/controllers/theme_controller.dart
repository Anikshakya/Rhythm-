import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  /// Reactive theme mode
  Rx<ThemeMode> themeMode = ThemeMode.dark.obs;

  /// Switch to Light Theme
  void setLightMode() => themeMode.value = ThemeMode.light;

  /// Switch to Dark Theme
  void setDarkMode() => themeMode.value = ThemeMode.dark;

  /// Follow System Theme
  void setSystemMode() => themeMode.value = ThemeMode.system;

  /// Toggle between Light & Dark (for simple button)
  void toggleTheme() {
    if (themeMode.value == ThemeMode.light) {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
  }
}