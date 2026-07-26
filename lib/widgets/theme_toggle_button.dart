import 'package:flutter/material.dart';
import 'package:smart_home/l10n/app_localizations.dart';
import 'package:smart_home/services/user_preferences_service.dart';

/// Petit bouton soleil / lune pour basculer entre thème clair et sombre.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.85,
        );

    return IconButton(
      tooltip: isDark ? context.l10n.themeTooltipLight : context.l10n.themeTooltipDark,
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        size: size,
        color: iconColor,
      ),
      onPressed: UserPreferencesService.instance.toggleTheme,
    );
  }
}
