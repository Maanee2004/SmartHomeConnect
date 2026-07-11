import 'package:flutter/material.dart';

/// Identité visuelle de l'application.
class AppBranding {
  AppBranding._();

  static const appName = 'SMART HOME CONNECT';
  static const tagline = 'Maison connectée';

  /// Propositions de logo (assets générés). Mettre l'un de ces chemins
  /// dans [selectedLogoAsset] pour l'utiliser dans toute l'app.
  static const logoOptionA = 'assets/branding/logo_option_a.png';
  static const logoOptionB = 'assets/branding/logo_option_b.png';
  static const logoOptionBTransparent =
      'assets/branding/logo_option_b_transparent.png';
  static const logoSmartHomeTransparent =
      'assets/branding/logo_smart_home_transparent.png';
  static const logoOptionC = 'assets/branding/logo_option_c.png';

  /// `null` = icône Wi‑Fi + maison intégrée (défaut).
  static const String? selectedLogoAsset = logoOptionB;

  /// Mode clair : logo standard. Mode sombre : variante transparente (même visuel).
  static String? resolveLogoAsset(Brightness brightness, {String? override}) {
    final base = override ?? selectedLogoAsset;
    if (base == null) return null;
    if (brightness == Brightness.dark && base == logoOptionB) {
      return logoOptionBTransparent;
    }
    return base;
  }
}
