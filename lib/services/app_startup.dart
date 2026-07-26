import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/firebase_options.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firebase_anonymous_auth.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/services/user_preferences_service.dart';

/// Démarrage rapide : UI d’abord, Firestore / streams en arrière-plan.
class AppStartup {
  AppStartup._();

  static Future<void>? _firebaseReady;

  static Future<void> ensureFirebase() {
    if (Firebase.apps.isNotEmpty) return Future.value();
    return _firebaseReady ??= _initFirebase().whenComplete(() {
      _firebaseReady = null;
    });
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Web : vérifier flutterfire configure si échec.
    }
  }

  /// Après [runApp] — auth anonyme + données si session locale.
  static Future<void> warmUpInBackground() async {
    if (Firebase.apps.isEmpty) return;

    unawaited(FirebaseAnonymousAuth.trySignIn(maxAttempts: 1));

    if (!AuthService.instance.isLoggedIn) return;

    final userId = AuthService.instance.currentUserId;
    if (userId != null && userId.isNotEmpty) {
      unawaited(UserPreferencesService.instance.loadFromFirestore(userId));
    }
    unawaited(FirestoreHomeRepository.bootstrap());
  }
}
