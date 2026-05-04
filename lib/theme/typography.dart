import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

class CustomTypography {
  static TextTheme textThemeFor(SmartHomeColors c) {
    return TextTheme(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 96,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 60,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 48,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 15,
        color: c.textSecondary,
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: 20,
        color: c.textPrimary,
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 14,
        color: c.textSecondary,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 10,
        color: c.textSecondary,
      ),
    );
  }
}
