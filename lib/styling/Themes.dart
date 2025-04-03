import 'package:flutter/material.dart';

class AppTheme {
  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      primary: Colors.blue.shade700,
      secondary: Colors.purple.shade600,
      tertiary: Colors.teal.shade500,
      surface: Colors.white,
      background: Colors.grey.shade50,
      onBackground: Colors.grey.shade900,
      onSurface: Colors.grey.shade800,
    ),
    scaffoldBackgroundColor: Colors.grey.shade50,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue.shade700,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade900,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade900,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade900,
      ),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      primary: Colors.blue.shade300,
      secondary: Colors.purple.shade300,
      tertiary: Colors.teal.shade300,
      surface: Colors.grey.shade900,
      background: Colors.black87,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.black87,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade900,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  static ThemeData trueTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF3700B3),
      onPrimary: Colors.white,
      secondary: Color(0xFF03DAC6),
      onSecondary: Colors.black,
      error: Color(0xFFB00020),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Color(0xFF121212),
      tertiary: Color(0xFF03DAC6),
      onTertiary: Colors.black,
      outline: Color(0xFFDCDCDC),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF121212),
      ),
      headlineMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFF121212),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFF121212),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF6B6B6B),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF3700B3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF3700B3),
        side: const BorderSide(color: Color(0xFF3700B3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFF3700B3),
        backgroundColor: Colors.transparent,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDCDCDC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3700B3), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        fontSize: 14,
        color: Color(0xFF6B6B6B),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFDCDCDC),
      thickness: 1,
    ),
  );
}
