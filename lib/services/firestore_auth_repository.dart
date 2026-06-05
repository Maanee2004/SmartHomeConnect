import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/services/password_hasher.dart';

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Auth Firestore — collection `users` (UML / mémoire).
class FirestoreAuthRepository {
  FirestoreAuthRepository._();
  static final FirestoreAuthRepository instance = FirestoreAuthRepository._();

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection('users');

  static String _slug(String raw) {
    var s = raw.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return s.isEmpty ? 'user' : s.substring(0, s.length.clamp(0, 24));
  }

  Future<String> _allocateUserId(String email) async {
    final base = 'usr_${_slug(email.split('@').first)}';
    if (!(await _users.doc(base).get()).exists) return base;
    for (var i = 2; i < 10000; i++) {
      final id = '${base}_$i';
      if (!(await _users.doc(id).get()).exists) return id;
    }
    return '${base}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _assertEmailFree(String email) async {
    final snap =
        await _users.where('email', isEqualTo: email).limit(1).get();
    if (snap.docs.isNotEmpty) {
      throw AuthFailure('Cet email est déjà utilisé.');
    }
  }

  Future<void> _assertPhoneFree(String phone) async {
    final snap =
        await _users.where('phone', isEqualTo: phone).limit(1).get();
    if (snap.docs.isNotEmpty) {
      throw AuthFailure('Ce numéro est déjà utilisé.');
    }
  }

  Future<AppUser?> _findByEmail(String email) async {
    final snap =
        await _users.where('email', isEqualTo: email).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return AppUser.fromFirestore(d.id, d.data());
  }

  Future<AppUser?> _findByPhone(String phone) async {
    final snap =
        await _users.where('phone', isEqualTo: phone).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return AppUser.fromFirestore(d.id, d.data());
  }

  /// Inscription : email **et** téléphone obligatoires, mot de passe haché.
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String plainPassword,
  }) async {
    final mail = email.trim().toLowerCase();
    final tel = phone.trim();
    if (mail.isEmpty || tel.isEmpty) {
      throw AuthFailure('Email et téléphone sont obligatoires.');
    }
    await _assertEmailFree(mail);
    await _assertPhoneFree(tel);

    final userId = await _allocateUserId(mail);
    final user = AppUser(
      userId: userId,
      name: name.trim(),
      email: mail,
      phone: tel,
      passwordHash: PasswordHasher.hash(plainPassword),
    );

    final batch = FirebaseFirestore.instance.batch();
    final userRef = _users.doc(userId);
    batch.set(userRef, user.toCreatePayload(passwordHash: user.passwordHash));
    batch.set(
      userRef.collection('preferences').doc('settings'),
      {
        'userId': userId,
        'pieces': <Map<String, String>>[],
        'theme': 'dark',
        'notifications': true,
        'language': 'fr',
        'fontFamily': 'montserrat',
        'fontScale': 1.0,
        'showDateTime': false,
        'use24HourTime': true,
        'datePattern': 'dd/MM/yyyy',
        'alertThreshold': 35.0,
      },
    );
    await batch.commit();
    return user;
  }

  /// Connexion : email **ou** téléphone + mot de passe.
  Future<AppUser> login({
    String? email,
    String? phone,
    required String plainPassword,
  }) async {
    AppUser? user;
    if (email != null && email.trim().isNotEmpty) {
      user = await _findByEmail(email.trim().toLowerCase());
    } else if (phone != null && phone.trim().isNotEmpty) {
      user = await _findByPhone(phone.trim());
    } else {
      throw AuthFailure('Indique ton email ou ton numéro.');
    }

    if (user == null) {
      throw AuthFailure('Identifiants incorrects.');
    }
    if (!PasswordHasher.verify(plainPassword, user.passwordHash)) {
      throw AuthFailure('Identifiants incorrects.');
    }
    return user;
  }
}
