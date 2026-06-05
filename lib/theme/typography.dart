import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

class CustomTypography {
  static TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) _fontBuilder(String family) {
    switch (family) {
      case 'roboto':
        return GoogleFonts.roboto;
      case 'open_sans':
        return GoogleFonts.openSans;
      case 'lato':
        return GoogleFonts.lato;
      case 'poppins':
        return GoogleFonts.poppins;
      case 'montserrat':
      default:
        return GoogleFonts.montserrat;
    }
  }

  static TextTheme textThemeFor(SmartHomeColors c, {String fontFamily = 'montserrat'}) {
    final font = _fontBuilder(fontFamily);
    return TextTheme(
      displayLarge: font(
        fontSize: 96,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      displayMedium: font(
        fontSize: 60,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
      ),
      displaySmall: font(
        fontSize: 48,
        fontWeight: FontWeight.w500,
        color: c.textPrimary,
      ),
      headlineMedium: font(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      headlineSmall: font(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      titleLarge: font(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      titleMedium: font(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      titleSmall: font(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: c.textPrimary,
      ),
      bodyLarge: font(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: c.textPrimary,
      ),
      bodyMedium: font(
        fontSize: 15,
        color: c.textSecondary,
      ),
      labelLarge: font(
        fontSize: 20,
        color: c.textPrimary,
      ),
      bodySmall: font(
        fontSize: 14,
        color: c.textSecondary,
      ),
      labelSmall: font(
        fontSize: 10,
        color: c.textSecondary,
      ),
    );
  }
}
