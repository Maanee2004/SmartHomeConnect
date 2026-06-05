/// Identité visuelle de l'application.
class AppBranding {
  AppBranding._();

  static const appName = 'SMART HOME CONNECT';
  static const tagline = 'Maison connectée';

  /// Propositions de logo (assets générés). Mettre l'un de ces chemins
  /// dans [selectedLogoAsset] pour l'utiliser dans toute l'app.
  static const logoOptionA = 'assets/branding/logo_option_a.png';
  static const logoOptionB = 'assets/branding/logo_option_b.png';
  static const logoOptionC = 'assets/branding/logo_option_c.png';

  /// `null` = icône Wi‑Fi + maison intégrée (défaut).
  static const String? selectedLogoAsset = logoOptionB;
}
