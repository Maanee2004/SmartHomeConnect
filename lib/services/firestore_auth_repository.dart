import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/firestore_schema.dart';
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
      role: UserRole.user,
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

  /// Création d’utilisateur par un admin (rôle `user` par défaut).
  Future<AppUser> createUserByAdmin({
    required String name,
    required String email,
    required String phone,
    required String plainPassword,
    String? houseOwnerUserId,
  }) async {
    final mail = email.trim().toLowerCase();
    final tel = phone.trim();
    if (mail.isEmpty || tel.isEmpty) {
      throw AuthFailure('Email et téléphone sont obligatoires.');
    }
    await _assertEmailFree(mail);
    await _assertPhoneFree(tel);

    final owner = houseOwnerUserId?.trim();
    if (owner != null && owner.isNotEmpty) {
      final ownerSnap = await _users.doc(owner).get();
      if (!ownerSnap.exists) {
        throw AuthFailure('Propriétaire de maison introuvable ($owner).');
      }
    }

    final userId = await _allocateUserId(mail);
    final user = AppUser(
      userId: userId,
      name: name.trim(),
      email: mail,
      phone: tel,
      passwordHash: PasswordHasher.hash(plainPassword),
      role: UserRole.user,
      houseOwnerUserId: owner,
    );

    final batch = FirebaseFirestore.instance.batch();
    final userRef = _users.doc(userId);
    batch.set(userRef, user.toCreatePayload(passwordHash: user.passwordHash));
    batch.set(
      userRef.collection(FirestoreSchema.preferencesSubcollection).doc(
            FirestoreSchema.preferencesDocId,
          ),
      {
        FirestoreSchema.fieldUserId: userId,
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

    if (owner != null && owner.isNotEmpty) {
      await _addMemberToHouse(ownerUserId: owner, memberUserId: userId);
    }
    return user;
  }

  /// Lie un utilisateur à la maison d’un propriétaire (lecture + commandes).
  Future<void> assignUserToHouse({
    required String ownerUserId,
    required String memberUserId,
  }) async {
    final owner = ownerUserId.trim();
    final member = memberUserId.trim();
    if (owner.isEmpty || member.isEmpty) {
      throw AuthFailure('Identifiants invalides.');
    }
    if (owner == member) {
      throw AuthFailure('Un utilisateur ne peut pas être membre de sa propre maison.');
    }
    final ownerSnap = await _users.doc(owner).get();
    final memberSnap = await _users.doc(member).get();
    if (!ownerSnap.exists || !memberSnap.exists) {
      throw AuthFailure('Utilisateur introuvable.');
    }
    await _users.doc(member).set(
      {'houseOwnerUserId': owner},
      SetOptions(merge: true),
    );
    await _addMemberToHouse(ownerUserId: owner, memberUserId: member);
  }

  Future<void> _addMemberToHouse({
    required String ownerUserId,
    required String memberUserId,
  }) async {
    final prefRef = _users
        .doc(ownerUserId)
        .collection(FirestoreSchema.preferencesSubcollection)
        .doc(FirestoreSchema.preferencesDocId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(prefRef);
      final data = snap.data() ?? {};
      final raw = data['memberUserIds'];
      final members = <String>{
        if (raw is List)
          for (final item in raw)
            if (item is String && item.trim().isNotEmpty) item.trim(),
      };
      members.add(memberUserId);
      tx.set(
        prefRef,
        {
          FirestoreSchema.fieldUserId: ownerUserId,
          'memberUserIds': members.toList()..sort(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Stream<List<AppUser>> watchAllUsers() {
    return _users.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((d) => AppUser.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<List<AppUser>> fetchAllUsers() async {
    final snap = await _users.orderBy('name').get();
    return snap.docs
        .map((d) => AppUser.fromFirestore(d.id, d.data()))
        .toList();
  }
}
