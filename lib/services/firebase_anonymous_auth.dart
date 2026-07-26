import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Auth Firebase anonyme — une seule tentative à la fois (évite les blocages Web).
class FirebaseAnonymousAuth {
  FirebaseAnonymousAuth._();

  static Future<void>? _inFlight;

  static Duration get _timeout =>
      kIsWeb ? const Duration(seconds: 8) : const Duration(seconds: 12);

  /// Tente la connexion anonyme ; n’interrompt jamais l’app si désactivée.
  static Future<void> trySignIn({int maxAttempts = 2}) {
    if (Firebase.apps.isEmpty) return Future.value();
    if (FirebaseAuth.instance.currentUser != null) return Future.value();
    return _inFlight ??= _signInLoop(maxAttempts).whenComplete(() {
      _inFlight = null;
    });
  }

  static Future<void> _signInLoop(int maxAttempts) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        await FirebaseAuth.instance.signInAnonymously().timeout(
          _timeout,
          onTimeout: () => throw TimeoutException('auth anonyme'),
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
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
    }
  }
}
