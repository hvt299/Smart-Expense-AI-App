import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00B4D8);

  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      );

  static final FilledButtonThemeData _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(),
      scaffoldBackgroundColor: Colors.grey.shade50,
      inputDecorationTheme: _inputDecorationTheme.copyWith(
        fillColor: Colors.grey.shade100,
      ),
      filledButtonTheme: _filledButtonTheme,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF1E1E1E),
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      inputDecorationTheme: _inputDecorationTheme.copyWith(
        fillColor: const Color(0xFF2C2C2C),
      ),
      filledButtonTheme: _filledButtonTheme,
    );
  }
}
