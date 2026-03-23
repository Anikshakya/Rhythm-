import 'package:flutter/material.dart';

class AppTheme {
  static const Color gold = Color(0xFFD4AF37);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);

  // 🌑 Dark Theme (Luxury look)
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: gold,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: gold,
      surface: cardColor,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: cardColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: gold,
      foregroundColor: Colors.black,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardColor,
      selectedItemColor: gold,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // ☀️ Light Theme (Premium minimal look)
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: gold,

    colorScheme: const ColorScheme.light(
      primary: gold,
      secondary: gold,
      surface: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: gold,
      foregroundColor: Colors.white,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: gold,
      unselectedItemColor: Colors.black54,
      type: BottomNavigationBarType.fixed,
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