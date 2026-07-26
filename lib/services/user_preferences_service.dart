import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/models/user_app_preferences.dart';
import 'package:smart_home/models/sensor_threshold_config.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_schema.dart';

/// Charge / sauvegarde les préférences profil (local + Firestore).
class UserPreferencesService {
  UserPreferencesService._();

  static final UserPreferencesService instance = UserPreferencesService._();

  static const _kTheme = 'pref_theme';
  static const _kLanguage = 'pref_language';
  static const _kFont = 'pref_font_family';
  static const _kFontScale = 'pref_font_scale';
  static const _kShowDateTime = 'pref_show_datetime';
  static const _kUse24h = 'pref_use_24h';
  static const _kDatePattern = 'pref_date_pattern';
  static const _kNotifications = 'pref_notifications';
  static const _kPirAlerts = 'pref_pir_alerts';

  final ValueNotifier<UserAppPreferences> notifier =
      ValueNotifier(UserAppPreferences.defaults);

  UserAppPreferences get prefs => notifier.value;

  ValueNotifier<ThemeMode> get themeModeNotifier {
    _themeBridge ??= ValueNotifier(prefs.themeMode);
    if (_themeBridge!.value != prefs.themeMode) {
      _themeBridge!.value = prefs.themeMode;
    }
    return _themeBridge!;
  }

  ValueNotifier<ThemeMode>? _themeBridge;

  Future<void> init() async {
    await _loadFromLocal();
  }

  DocumentReference<Map<String, dynamic>>? _settingsRef(String userId) {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection(FirestoreSchema.usersCollection)
        .doc(userId)
        .collection(FirestoreSchema.preferencesSubcollection)
        .doc(FirestoreSchema.preferencesDocId);
  }

  Future<void> loadFromFirestore(String userId) async {
    final ref = _settingsRef(userId);
    if (ref == null) return;
    try {
      final snap = await ref.get();
      if (!snap.exists) return;
      final remote = UserAppPreferences.fromFirestore(snap.data());
      // Le thème choisi sur l’appareil prime sur Firestore (souvent « dark » par défaut).
      final sp = await SharedPreferences.getInstance();
      final localTheme =
          UserAppPreferences.themeModeFromString(sp.getString(_kTheme));
      final localLang =
          sp.getString(_kLanguage) ?? UserAppPreferences.defaults.languageCode;
      final merged = remote.copyWith(
        themeMode: localTheme,
        languageCode: localLang,
      );
      notifier.value = merged;
      _themeBridge?.value = merged.themeMode;
      await _saveToLocal(merged);
    } catch (e) {
      // ignore: avoid_print
      print('[Preferences] load Firestore: $e');
    }
  }

  Future<void> _loadFromLocal() async {
    final sp = await SharedPreferences.getInstance();
    final theme = UserAppPreferences.themeModeFromString(sp.getString(_kTheme));
    notifier.value = UserAppPreferences(
      themeMode: theme,
      languageCode:
          sp.getString(_kLanguage) ?? UserAppPreferences.defaults.languageCode,
      fontFamily:
          sp.getString(_kFont) ?? UserAppPreferences.defaults.fontFamily,
      fontScale:
          UserAppPreferences.normalizeFontScale(sp.getDouble(_kFontScale)),
      showDateTime: sp.getBool(_kShowDateTime) ??
          UserAppPreferences.defaults.showDateTime,
      use24HourTime:
          sp.getBool(_kUse24h) ?? UserAppPreferences.defaults.use24HourTime,
      datePattern: sp.getString(_kDatePattern) ??
          UserAppPreferences.defaults.datePattern,
      notificationsEnabled: sp.getBool(_kNotifications) ??
          UserAppPreferences.defaults.notificationsEnabled,
      pirAlertsEnabled:
          sp.getBool(_kPirAlerts) ?? UserAppPreferences.defaults.pirAlertsEnabled,
      sensorThresholds: UserAppPreferences.defaults.sensorThresholds,
    );
    _themeBridge?.value = notifier.value.themeMode;
  }

  Future<void> _saveToLocal(UserAppPreferences p) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kTheme, p.themeFirestoreValue);
    await sp.setString(_kLanguage, p.languageCode);
    await sp.setString(_kFont, p.fontFamily);
    await sp.setDouble(_kFontScale, p.fontScale);
    await sp.setBool(_kShowDateTime, p.showDateTime);
    await sp.setBool(_kUse24h, p.use24HourTime);
    await sp.setString(_kDatePattern, p.datePattern);
    await sp.setBool(_kNotifications, p.notificationsEnabled);
    await sp.setBool(_kPirAlerts, p.pirAlertsEnabled);
  }

  void _apply(UserAppPreferences next) {
    notifier.value = next;
    _themeBridge?.value = next.themeMode;
  }

  Future<void> _persistFirestore(UserAppPreferences next) async {
    final userId = AuthService.instance.currentUserId;
    final ref = userId == null ? null : _settingsRef(userId);
    if (ref == null) return;
    try {
      await ref.set(
        {
          FirestoreSchema.fieldUserId: userId,
          ...next.toFirestorePatch(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[Preferences] save Firestore: $e');
    }
  }

  Future<void> _persist(UserAppPreferences next) async {
    _apply(next);
    await _saveToLocal(next);
    await _persistFirestore(next);
  }

  /// Mise à jour immédiate à l’écran ; sauvegarde locale + Firestore en arrière-plan.
  void _persistFast(UserAppPreferences next) {
    _apply(next);
    unawaited(_saveToLocal(next));
    unawaited(_persistFirestore(next));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _persistFast(prefs.copyWith(themeMode: mode));
  }

  void toggleTheme() {
    final mode =
        prefs.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persistFast(prefs.copyWith(themeMode: mode));
  }

  Future<void> setLanguage(String code) =>
      _persist(prefs.copyWith(languageCode: code));

  Future<void> setFontFamily(String family) =>
      _persist(prefs.copyWith(fontFamily: family));

  Future<void> setFontScale(double scale) => _persist(
        prefs.copyWith(
          fontScale: UserAppPreferences.normalizeFontScale(scale),
        ),
      );

  Future<void> setShowDateTime(bool value) =>
      _persist(prefs.copyWith(showDateTime: value));

  Future<void> setUse24HourTime(bool value) =>
      _persist(prefs.copyWith(use24HourTime: value));

  Future<void> setDatePattern(String pattern) =>
      _persist(prefs.copyWith(datePattern: pattern));

  Future<void> setNotificationsEnabled(bool value) =>
      _persist(prefs.copyWith(notificationsEnabled: value));

  Future<void> setPirAlertsEnabled(bool value) =>
      _persist(prefs.copyWith(pirAlertsEnabled: value));

  Future<void> setSensorThreshold(
    String type,
    SensorThresholdConfig config,
  ) {
    final key = type.trim().toUpperCase();
    final next = Map<String, SensorThresholdConfig>.from(prefs.sensorThresholds)
      ..[key] = config;
    return _persist(prefs.copyWith(sensorThresholds: next));
  }
}
