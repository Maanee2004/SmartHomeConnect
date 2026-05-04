import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'typography.dart';

class CustomTheme {
  static ThemeData darkTheme() => _build(
        brightness: Brightness.dark,
        colors: SmartHomeColors.dark,
        sliderActive: Colors.white,
        sliderInactive: Colors.white24,
      );

  static ThemeData lightTheme() => _build(
        brightness: Brightness.light,
        colors: SmartHomeColors.light,
        sliderActive: primaryColor,
        sliderInactive: const Color(0xFFCBD5E1),
      );

  static ThemeData _build({
    required Brightness brightness,
    required SmartHomeColors colors,
    required Color sliderActive,
    required Color sliderInactive,
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
      visualDensity: VisualDensity.adaptivePlatformDensity,
      sliderTheme: SliderThemeData(
        activeTrackColor: sliderActive,
        thumbColor: sliderActive,
        inactiveTrackColor: sliderInactive,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      textTheme: CustomTypography.textThemeFor(colors),
      extensions: <ThemeExtension<dynamic>>[colors],
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
