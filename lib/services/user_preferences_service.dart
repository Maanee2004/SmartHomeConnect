import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/models/user_app_preferences.dart';
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
    final userId = AuthService.instance.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      await loadFromFirestore(userId);
    }
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
      notifier.value = remote;
      _themeBridge?.value = remote.themeMode;
      await _saveToLocal(remote);
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
      languageCode: sp.getString(_kLanguage) ?? UserAppPreferences.defaults.languageCode,
      fontFamily: sp.getString(_kFont) ?? UserAppPreferences.defaults.fontFamily,
      fontScale: UserAppPreferences.normalizeFontScale(sp.getDouble(_kFontScale)),
      showDateTime: sp.getBool(_kShowDateTime) ?? UserAppPreferences.defaults.showDateTime,
      use24HourTime: sp.getBool(_kUse24h) ?? UserAppPreferences.defaults.use24HourTime,
      datePattern: sp.getString(_kDatePattern) ?? UserAppPreferences.defaults.datePattern,
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
  }

  Future<void> _persist(UserAppPreferences next) async {
    notifier.value = next;
    _themeBridge?.value = next.themeMode;
    await _saveToLocal(next);

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

  Future<void> setThemeMode(ThemeMode mode) =>
      _persist(prefs.copyWith(themeMode: mode));

  Future<void> toggleTheme() => setThemeMode(
        prefs.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
      );

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
}
