import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/user_preferences_service.dart';

/// Session locale + rôle (`admin` / `user`) pour router l’interface.
class AuthService {
  static const String _cachedUserNameKey = 'cached_user_name';
  static const String _cachedUserIdKey = 'cached_user_id';
  static const String _cachedUserEmailKey = 'cached_user_email';
  static const String _cachedUserRoleKey = 'cached_user_role';
  static const String _cachedHouseOwnerKey = 'cached_house_owner_id';

  AuthService._();

  static final AuthService instance = AuthService._();

  /// Notifie [MaterialApp] pour basculer login ↔ shell sans empiler les routes.
  final ValueNotifier<bool> authNotifier = ValueNotifier<bool>(false);

  final StreamController<String?> _updates =
      StreamController<String?>.broadcast();

  String? _userId;
  String? _userEmail;
  String _role = UserRole.user;
  String? _houseOwnerUserId;

  String? get currentUserId => _userId;
  String? get currentUserEmail => _userEmail;
  String get currentRole => _role;
  String? get houseOwnerUserId => _houseOwnerUserId;
  bool get isLoggedIn => _userId != null && _userId!.isNotEmpty;
  bool get isAdmin => UserRole.isAdmin(_role);

  /// Ajout de pièces — tout utilisateur connecté.
  bool get canAddRooms => isLoggedIn;

  /// CRUD appareils / broches / suppression pièces — réservé aux admins.
  bool get canManageDevices => isAdmin;

  /// Alias legacy (appareils / seed démo).
  bool get canManageHome => canManageDevices;

  Stream<String?> userNameStream() async* {
    yield await _readDisplayName();
    yield* _updates.stream;
  }

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_cachedUserIdKey);
    _userEmail = prefs.getString(_cachedUserEmailKey);
    _role = UserRole.normalize(prefs.getString(_cachedUserRoleKey));
    final owner = prefs.getString(_cachedHouseOwnerKey)?.trim();
    _houseOwnerUserId =
        owner != null && owner.isNotEmpty ? owner : null;
    authNotifier.value = isLoggedIn;
    if (isLoggedIn) {
      final scopeId = _houseOwnerUserId ?? _userId!;
      await UserPreferencesService.instance.loadFromFirestore(scopeId);
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
    _role = user.role;
    _houseOwnerUserId = user.houseOwnerUserId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserIdKey, user.userId);
    await prefs.setString(_cachedUserEmailKey, user.email);
    await prefs.setString(_cachedUserRoleKey, user.role);
    if (_houseOwnerUserId != null && _houseOwnerUserId!.isNotEmpty) {
      await prefs.setString(_cachedHouseOwnerKey, _houseOwnerUserId!);
    } else {
      await prefs.remove(_cachedHouseOwnerKey);
    }
    await setCachedUserName(user.name);
    final scopeId = _houseOwnerUserId ?? user.userId;
    await UserPreferencesService.instance.loadFromFirestore(scopeId);
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
    _role = UserRole.user;
    _houseOwnerUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserIdKey);
    await prefs.remove(_cachedUserEmailKey);
    await prefs.remove(_cachedUserNameKey);
    await prefs.remove(_cachedUserRoleKey);
    await prefs.remove(_cachedHouseOwnerKey);
    if (!_updates.isClosed) _updates.add(null);
    _notifyAuthChanged();
  }
}
