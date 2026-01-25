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

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryRed,
        surface: surfaceColor,
        background: backgroundColor,
        error: primaryRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1219), // Sidebar Dark
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryBlue),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        shape: Border(
          bottom: BorderSide(color: borderBlue, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primaryBlue.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F1219),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
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
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderBlue, width: 1),
        ),
      ),
    );
  }

  // Maintaining lightTheme alias for backward compatibility but using dark colors
  static ThemeData get lightTheme => darkTheme;
}
