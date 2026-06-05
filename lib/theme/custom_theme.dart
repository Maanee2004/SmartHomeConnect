import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'typography.dart';

class CustomTheme {
  static ThemeData darkTheme({String fontFamily = 'montserrat'}) => _build(
        brightness: Brightness.dark,
        colors: SmartHomeColors.dark,
        sliderActive: Colors.white,
        sliderInactive: Colors.white24,
        fontFamily: fontFamily,
      );

  static ThemeData lightTheme({String fontFamily = 'montserrat'}) => _build(
        brightness: Brightness.light,
        colors: SmartHomeColors.light,
        sliderActive: primaryColor,
        sliderInactive: const Color(0xFFCBD5E1),
        fontFamily: fontFamily,
      );

  static ThemeData _build({
    required Brightness brightness,
    required SmartHomeColors colors,
    required Color sliderActive,
    required Color sliderInactive,
    String fontFamily = 'montserrat',
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: primaryColor,
            secondary: accentColor,
            surface: colors.card,
            error: errorColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: colors.textPrimary,
            onError: Colors.white,
          ).copyWith(
            surfaceContainerHighest: colors.surfaceElevated,
          )
        : ColorScheme.light(
            primary: primaryColor,
            secondary: accentColor,
            surface: colors.card,
            error: errorColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: colors.textPrimary,
            onError: Colors.white,
          ).copyWith(
            surfaceContainerHighest: colors.surfaceElevated,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      disabledColor: disabledColor,
      scaffoldBackgroundColor: colors.scaffoldBackground,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: colors.textPrimary,
        iconTheme: IconThemeData(color: colors.textSecondary),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.card,
        modalBackgroundColor: colors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.card,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        contentTextStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
      ),
      dividerTheme: DividerThemeData(
        color: colors.planBorder.withValues(alpha: 0.65),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputFill,
        labelStyle: TextStyle(color: colors.textSecondary),
        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.85)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.planBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? colors.surfaceElevated : colors.textPrimary,
        contentTextStyle: TextStyle(
          color: isDark ? colors.textPrimary : colors.card,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      sliderTheme: SliderThemeData(
        activeTrackColor: sliderActive,
        thumbColor: sliderActive,
        inactiveTrackColor: sliderInactive,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      textTheme: CustomTypography.textThemeFor(colors, fontFamily: fontFamily),
      extensions: <ThemeExtension<dynamic>>[colors],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceElevated,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black26,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(22)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return null;
        }),
        checkColor: WidgetStateProperty.all(
          isDark ? Colors.black : Colors.white,
        ),
      ),
    );
  }

  /// Rétrocompatibilité (thème sombre).
  @Deprecated('Utiliser darkTheme() ou lightTheme()')
  static ThemeData get myTheme => darkTheme();
}
