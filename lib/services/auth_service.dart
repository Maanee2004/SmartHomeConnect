import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/services/user_preferences_service.dart';

/// Session locale + nom affiché (collection Firestore `users`).
class AuthService {
  static const String _cachedUserNameKey = 'cached_user_name';
  static const String _cachedUserIdKey = 'cached_user_id';
  static const String _cachedUserEmailKey = 'cached_user_email';

  AuthService._();

  static final AuthService instance = AuthService._();

  /// Notifie [MaterialApp] pour basculer login ↔ dashboard sans empiler les routes.
  final ValueNotifier<bool> authNotifier = ValueNotifier<bool>(false);

  final StreamController<String?> _updates =
      StreamController<String?>.broadcast();

  String? _userId;
  String? _userEmail;

  String? get currentUserId => _userId;
  String? get currentUserEmail => _userEmail;
  bool get isLoggedIn => _userId != null && _userId!.isNotEmpty;

  Stream<String?> userNameStream() async* {
    yield await _readDisplayName();
    yield* _updates.stream;
  }

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_cachedUserIdKey);
    _userEmail = prefs.getString(_cachedUserEmailKey);
    authNotifier.value = isLoggedIn;
    if (isLoggedIn) {
      await UserPreferencesService.instance.loadFromFirestore(_userId!);
    }
  }

  void _notifyAuthChanged() {
    authNotifier.value = isLoggedIn;
  }

  Future<String?> _readDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cachedUserNameKey)?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  Future<void> saveSession(AppUser user) async {
    _userId = user.userId;
    _userEmail = user.email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserIdKey, user.userId);
    await prefs.setString(_cachedUserEmailKey, user.email);
    await setCachedUserName(user.name);
    await UserPreferencesService.instance.loadFromFirestore(user.userId);
    _notifyAuthChanged();
  }

  Future<void> setCachedUserName(String name) async {
    final t = name.trim();
    final prefs = await SharedPreferences.getInstance();
    if (t.isEmpty) {
      await prefs.remove(_cachedUserNameKey);
      if (!_updates.isClosed) _updates.add(null);
      return;
    }
    await prefs.setString(_cachedUserNameKey, t);
    if (!_updates.isClosed) _updates.add(t);
  }

  Future<void> clearSession() async {
    _userId = null;
    _userEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserIdKey);
    await prefs.remove(_cachedUserEmailKey);
    await prefs.remove(_cachedUserNameKey);
    if (!_updates.isClosed) _updates.add(null);
    _notifyAuthChanged();
  }
}
