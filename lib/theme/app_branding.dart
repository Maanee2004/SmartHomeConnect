import 'package:flutter/material.dart';

/// Identité visuelle de l'application.
class AppBranding {
  AppBranding._();

  static const appName = 'SMART HOME CONNECT';
  static const tagline = 'Maison connectée';

  /// Icône carré arrondi (navy + vert sauge) — clair et sombre.
  static const logoIconDark = 'assets/branding/logo_connect_dark.png';

  static const selectedLogoAsset = logoIconDark;

  static String resolveLogoAsset({
    String? override,
    bool compact = false,
    required Brightness brightness,
  }) {
    if (override != null) return override;
    // Même icône navy + vert sauge en clair et sombre (lisible sur fond clair).
    return logoIconDark;
  }
}
