import 'package:flutter/material.dart';

/// Fournit le [ValueNotifier] du mode thème à toute l’app (toggle clair / sombre).
class AppThemeModeScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const AppThemeModeScope({
    super.key,
    required ValueNotifier<ThemeMode> super.notifier,
    required super.child,
  });

  static ValueNotifier<ThemeMode> of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppThemeModeScope>();
    assert(scope != null, 'AppThemeModeScope manquant au-dessus de MaterialApp');
    return scope!.notifier!;
  }
}
