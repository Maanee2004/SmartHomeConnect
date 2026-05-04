import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Nom affiché (prénom + nom) : [SharedPreferences] puis fallback [FirebaseAuth].
class AuthService {
  static const String _cachedUserNameKey = 'cached_user_name';

  AuthService._();

  static final AuthService instance = AuthService._();

  final StreamController<String?> _updates =
      StreamController<String?>.broadcast();

  /// Stream : d’abord la valeur persistée, puis les mises à jour ([setCachedUserName]).
  Stream<String?> userNameStream() async* {
    yield await _readDisplayName();
    yield* _updates.stream;
  }

  Future<String?> _readDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cachedUserNameKey)?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    final firebase = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (firebase != null && firebase.isNotEmpty) return firebase;
    return null;
  }

  /// Enregistre le nom après login ou inscription (prefs + notification du stream).
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
}
