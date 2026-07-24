import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Signature Apple Music Red / Pink Accent
  static const Color appleRed = Color(0xFFFA2D48);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkCard = Color(0xFF1C1C1E);
  static const Color lightBackground = Color(0xFFF2F2F7);

  // 🌑 Apple Music Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: appleRed,
    colorScheme: const ColorScheme.dark(
      primary: appleRed,
      secondary: appleRed,
      surface: darkCard,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: appleRed,
      foregroundColor: Colors.white,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF121212),
      selectedItemColor: appleRed,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: appleRed,
      thumbColor: appleRed,
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // ☀️ Apple Music Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: appleRed,

    colorScheme: const ColorScheme.light(
      primary: appleRed,
      secondary: appleRed,
      surface: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: appleRed,
      foregroundColor: Colors.white,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: appleRed,
      unselectedItemColor: Colors.black45,
      type: BottomNavigationBarType.fixed,
    ),

    sliderTheme: const SliderThemeData(
      activeTrackColor: appleRed,
      thumbColor: appleRed,
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}