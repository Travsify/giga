import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Command Dashboard Colors (High-Tech Dark + UK Union Jack)
  static const Color primaryBlue = Color(0xFF00247D); // UK Royal Blue (Deep)
  static const Color primaryRed = Color(0xFFCF142B);  // UK Red (Rich)
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
        background: Colors.white,
        error: primaryRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1E293B), // Slate 800
        onBackground: Color(0xFF1E293B),
      ),
      
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: const Color(0xFF1E293B),
        displayColor: const Color(0xFF0F172A), // Slate 900
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlue),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC), // Slate 50
        labelStyle: const TextStyle(color: Color(0xFF64748B)), // Slate 500
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)), // Slate 400
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFF1F5F9), width: 1), // Slate 100
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme; // Placeholder for now

  static const Color slateBlue = Color(0xFF475569);
  static const Color cardBg = surfaceColor;
  static const Color primaryOrange = Color(0xFFF59E0B);

  static InputDecoration inputDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFF0F1219),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderBlue),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}
