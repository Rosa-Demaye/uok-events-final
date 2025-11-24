import 'package:flutter/material.dart';

class AppTheme {
  // --- COLORS ---
  static const Color primaryBlue = Color(0xFF1E40AF);
  static const Color lightGrey = Color(0xFFF2F2F2); // A light grey that's almost white
  static const Color accentYellow = Color(0xFFFFC107); // A standard bright yellow
  static const Color accentRed = Color(0xFFB71C1C); // A professional dark red
  static const Color darkText = Color(0xFF212121); // A dark grey for text, softer than pure black
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // --- THEME DATA ---
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: lightGrey,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: accentYellow,
      onPrimary: white,
      onSecondary: black,
      error: accentRed,
      background: lightGrey,
      surface: white,
      onSurface: darkText,
    ),
    appBarTheme: const AppBarTheme(
      color: primaryBlue,
      elevation: 0,
      iconTheme: IconThemeData(color: white),
      titleTextStyle: TextStyle(
        color: white,
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins', // We can add custom fonts later
      ),
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: darkText),
      titleLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600, color: darkText),
      bodyLarge: TextStyle(fontSize: 16.0, color: darkText),
      bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black54),
      labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryBlue, width: 2.0),
      ),
      hintStyle: const TextStyle(color: Colors.black38),
    ),
  );
}
