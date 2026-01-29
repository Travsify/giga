import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Command Dashboard Colors (High-Tech Dark)
  static const Color primaryBlue = Color(0xFF3B82F6); // Tech Blue
  static const Color primaryRed = Color(0xFFEF4444);  // Tech Red
  static const Color backgroundColor = Color(0xFF0B0E14); // Deep Space Dark
  static const Color surfaceColor = Color(0xFF141820); // Card Dark
  
  // Text Colors
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF94A3B8);
  
  // Legacy Aliases & Utility Colors
  static const Color primaryColor = primaryBlue;
  static const Color errorRed = primaryRed;
  static const Color successGreen = Color(0xFF10B981); // Tech Green
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color borderBlue = Color(0x333B82F6); // 20% opacity Tech Blue
  static const Color slateBlue = textSecondary;
  static const Color cardBg = surfaceColor;
  static const Color primaryBlueDark = Color(0xFF1D4ED8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: primaryRed,
        surface: Colors.white,
        error: primaryRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1E293B), // Slate 900
      ),
      
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: const Color(0xFF334155), // Slate 700
        displayColor: const Color(0xFF0F172A), // Slate 900
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        shape: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate 200
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryBlue.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100
        labelStyle: const TextStyle(color: Color(0xFF64748B)), // Slate 500
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)), // Slate 400
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // Slate 200
        ),
      ),
    );
  }

  // Legacy alias mapping darkTheme to the new lightTheme
  static ThemeData get darkTheme => lightTheme;
}
