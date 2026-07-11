import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Auth Firebase anonyme — optionnelle (l’app fonctionne sans elle).
class FirebaseAnonymousAuth {
  FirebaseAnonymousAuth._();

  /// Tente la connexion anonyme ; n’interrompt jamais l’app si désactivée.
  static Future<void> trySignIn({int maxAttempts = 2}) async {
    if (Firebase.apps.isEmpty) return;
    if (FirebaseAuth.instance.currentUser != null) return;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await FirebaseAuth.instance.signInAnonymously().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw FirebaseAuthException(
            code: 'timeout',
            message: 'Connexion Firebase Auth expirée.',
          ),
        );
        return;
      } on FirebaseAuthException catch (e) {
        // ignore: avoid_print
        print('[Firebase] auth anonyme (tentative ${attempt + 1}): ${e.code}');
      } on TimeoutException {
        // ignore: avoid_print
        print('[Firebase] auth anonyme (tentative ${attempt + 1}): timeout');
      }
      if (attempt + 1 < maxAttempts) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
  }
}
