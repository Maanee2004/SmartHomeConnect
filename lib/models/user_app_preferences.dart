import 'package:flutter/material.dart';

/// Préférences utilisateur (profil) — thème, langue, police, date/heure.
class UserAppPreferences {
  const UserAppPreferences({
    required this.themeMode,
    required this.languageCode,
    required this.fontFamily,
    required this.fontScale,
    required this.showDateTime,
    required this.use24HourTime,
    required this.datePattern,
  });

  final ThemeMode themeMode;
  final String languageCode;
  final String fontFamily;
  final double fontScale;
  final bool showDateTime;
  final bool use24HourTime;
  final String datePattern;

  static const double defaultFontScale = 1.0;
  static const double minFontScale = 0.9;
  static const double maxFontScale = 1.35;

  static const defaults = UserAppPreferences(
    themeMode: ThemeMode.dark,
    languageCode: 'fr',
    fontFamily: 'montserrat',
    fontScale: defaultFontScale,
    showDateTime: false,
    use24HourTime: true,
    datePattern: 'dd/MM/yyyy',
  );

  static const supportedFontScales = <String, String>{
    'small': 'Petite',
    'normal': 'Normale',
    'large': 'Grande',
    'xlarge': 'Très grande',
  };

  static const _fontScaleValues = <String, double>{
    'small': 0.9,
    'normal': 1.0,
    'large': 1.15,
    'xlarge': 1.3,
  };

  Locale get locale => Locale(languageCode);

  UserAppPreferences copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    String? fontFamily,
    double? fontScale,
    bool? showDateTime,
    bool? use24HourTime,
    String? datePattern,
  }) {
    return UserAppPreferences(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: fontScale ?? this.fontScale,
      showDateTime: showDateTime ?? this.showDateTime,
      use24HourTime: use24HourTime ?? this.use24HourTime,
      datePattern: datePattern ?? this.datePattern,
    );
  }

  static double normalizeFontScale(num? raw) {
    if (raw == null) return defaultFontScale;
    final value = raw.toDouble().clamp(minFontScale, maxFontScale);
    var nearest = defaultFontScale;
    var minDistance = double.infinity;
    for (final scale in _fontScaleValues.values) {
      final distance = (scale - value).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = scale;
      }
    }
    return nearest;
  }

  String get fontScaleKey {
    for (final entry in _fontScaleValues.entries) {
      if (entry.value == fontScale) return entry.key;
    }
    return 'normal';
  }

  String get fontScaleLabel =>
      supportedFontScales[fontScaleKey] ?? '${(fontScale * 100).round()} %';

  static double fontScaleFromKey(String key) =>
      _fontScaleValues[key] ?? defaultFontScale;

  static ThemeMode themeModeFromString(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'light':
      case 'clair':
        return ThemeMode.light;
      default:
        return ThemeMode.dark;
    }
  }

  String get themeFirestoreValue =>
      themeMode == ThemeMode.light ? 'light' : 'dark';

  Map<String, dynamic> toFirestorePatch() => {
        'theme': themeFirestoreValue,
        'language': languageCode,
        'fontFamily': fontFamily,
        'fontScale': fontScale,
        'showDateTime': showDateTime,
        'use24HourTime': use24HourTime,
        'datePattern': datePattern,
      };

  factory UserAppPreferences.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return defaults;
    return UserAppPreferences(
      themeMode: themeModeFromString(data['theme'] as String?),
      languageCode: (data['language'] as String?)?.trim().isNotEmpty == true
          ? (data['language'] as String).trim()
          : defaults.languageCode,
      fontFamily: (data['fontFamily'] as String?)?.trim().isNotEmpty == true
          ? (data['fontFamily'] as String).trim()
          : defaults.fontFamily,
      fontScale: normalizeFontScale(data['fontScale'] as num?),
      showDateTime: data['showDateTime'] as bool? ?? defaults.showDateTime,
      use24HourTime: data['use24HourTime'] as bool? ?? defaults.use24HourTime,
      datePattern: (data['datePattern'] as String?)?.trim().isNotEmpty == true
          ? (data['datePattern'] as String).trim()
          : defaults.datePattern,
    );
  }

  static const supportedLanguages = <String, String>{
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
  };

  static const supportedFonts = <String, String>{
    'montserrat': 'Montserrat',
    'roboto': 'Roboto',
    'open_sans': 'Open Sans',
    'lato': 'Lato',
    'poppins': 'Poppins',
  };

  static const supportedDatePatterns = <String, String>{
    'dd/MM/yyyy': '31/12/2026',
    'MM/dd/yyyy': '12/31/2026',
    'yyyy-MM-dd': '2026-12-31',
  };
}
