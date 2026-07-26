import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/sensor_threshold_config.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/firebase_anonymous_auth.dart';
import 'package:smart_home/services/firestore_house_paths.dart';
import 'package:smart_home/services/firestore_schema.dart';
import 'package:smart_home/services/admin_repository.dart';
import 'package:smart_home/services/house_invites_repository.dart';
import 'package:smart_home/services/house_resolver.dart';
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

  static const Duration _queryTimeout = Duration(seconds: 20);

  void _ensureFirebaseReady() {
    if (Firebase.apps.isEmpty) {
      throw AuthFailure(
        'Firebase non initialisé. Relance l’application ou vérifie la configuration.',
      );
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _queryWithTimeout(
    Future<QuerySnapshot<Map<String, dynamic>>> query,
  ) {
    return query.timeout(
      _queryTimeout,
      onTimeout: () => throw AuthFailure(
        'Délai dépassé. Vérifie ta connexion internet et réessaie.',
      ),
    );
  }

  AuthFailure _mapFirestoreError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return AuthFailure(
        'Accès Firestore refusé. Vérifie les règles de sécurité Firebase.',
      );
    }
    if (e.code == 'unavailable') {
      return AuthFailure(
        'Firestore indisponible. Vérifie ta connexion internet.',
      );
    }
    return AuthFailure('Erreur Firestore (${e.code}) : ${e.message ?? e}');
  }

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

  bool _isSameUserDoc(
    String docId,
    Map<String, dynamic> data,
    String exceptUserId,
  ) {
    if (docId == exceptUserId) return true;
    final field = (data[FirestoreSchema.fieldUserId] as String?)?.trim();
    return field != null && field.isNotEmpty && field == exceptUserId;
  }

  Future<void> _assertEmailFree(String email, {String? exceptUserId}) async {
    final snap =
        await _users.where('email', isEqualTo: email).limit(1).get();
    if (snap.docs.isEmpty) return;
    final hit = snap.docs.first;
    if (exceptUserId != null &&
        _isSameUserDoc(hit.id, hit.data(), exceptUserId)) {
      return;
    }
    throw AuthFailure('Cet email est déjà utilisé.');
  }

  Future<void> _assertPhoneFree(String phone, {String? exceptUserId}) async {
    final snap =
        await _users.where('phone', isEqualTo: phone).limit(1).get();
    if (snap.docs.isEmpty) return;
    final hit = snap.docs.first;
    if (exceptUserId != null &&
        _isSameUserDoc(hit.id, hit.data(), exceptUserId)) {
      return;
    }
    throw AuthFailure('Ce numéro est déjà utilisé.');
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _resolveUserDoc(
    String userId,
  ) async {
    final id = userId.trim();
    if (id.isEmpty) throw AuthFailure('Identifiant utilisateur invalide.');
    var snap = await _users.doc(id).get();
    if (snap.exists) return snap;
    final byField = await _users
        .where(FirestoreSchema.fieldUserId, isEqualTo: id)
        .limit(1)
        .get();
    if (byField.docs.isEmpty) {
      throw AuthFailure('Utilisateur introuvable.');
    }
    return byField.docs.first;
  }

  Future<AppUser?> _findByEmail(String email) async {
    final snap = await _queryWithTimeout(
      _users.where('email', isEqualTo: email).limit(1).get(),
    );
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return AppUser.fromFirestore(d.id, d.data());
  }

  Future<AppUser?> _findByPhone(String phone) async {
    final snap = await _queryWithTimeout(
      _users.where('phone', isEqualTo: phone).limit(1).get(),
    );
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first;
    return AppUser.fromFirestore(d.id, d.data());
  }

  Future<void> _ensureAnonymousAuth() async {
    _ensureFirebaseReady();
    await FirebaseAnonymousAuth.trySignIn();
  }

  /// Inscription : email **et** téléphone obligatoires, mot de passe haché.
  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String plainPassword,
  }) async {
    await _ensureAnonymousAuth();
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
        'theme': 'dark',
        'notifications': true,
        'language': 'fr',
        'fontFamily': 'montserrat',
        'fontScale': 1.0,
        'showDateTime': false,
        'use24HourTime': true,
        'datePattern': 'dd/MM/yyyy',
        'alertThreshold': 35.0,
        'pirAlertsEnabled': true,
        'sensorAlerts': {
          for (final e in SensorThresholdConfig.defaultsByType.entries)
            e.key: e.value.toFirestore(),
        },
      },
    );
    await batch.commit();
    await FirestoreHousePaths.ensureInitialized(
      FirebaseFirestore.instance,
      userId,
    );
    return user;
  }

  /// Connexion : email **ou** téléphone + mot de passe.
  Future<AppUser> login({
    String? email,
    String? phone,
    required String plainPassword,
  }) async {
    await _ensureAnonymousAuth();

    AppUser? user;
    try {
      if (email != null && email.trim().isNotEmpty) {
        user = await _findByEmail(email.trim().toLowerCase());
      } else if (phone != null && phone.trim().isNotEmpty) {
        user = await _findByPhone(phone.trim());
      } else {
        throw AuthFailure('Indique ton email ou ton numéro.');
      }
    } on AuthFailure {
      rethrow;
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    } on TimeoutException {
      throw AuthFailure(
        'Délai dépassé. Vérifie ta connexion internet et réessaie.',
      );
    }

    if (user == null) {
      throw AuthFailure('Identifiants incorrects.');
    }
    if (user.passwordHash.isEmpty) {
      throw AuthFailure(
        'Compte mal configuré (mot de passe absent dans Firestore). '
        'Contacte l’administrateur.',
      );
    }
    if (!PasswordHasher.verify(plainPassword, user.passwordHash)) {
      throw AuthFailure('Identifiants incorrects.');
    }
    return user;
  }

  /// Création d’utilisateur par un admin.
  Future<AppUser> createUserByAdmin({
    required String name,
    required String email,
    required String phone,
    required String plainPassword,
    String? memberHouseId,
    String? ownerOfHouseId,
    String? houseOwnerUserId,
  }) async {
    await _ensureAnonymousAuth();
    final mail = email.trim().toLowerCase();
    final tel = phone.trim();
    if (mail.isEmpty || tel.isEmpty) {
      throw AuthFailure('Email et téléphone sont obligatoires.');
    }
    await _assertEmailFree(mail);
    await _assertPhoneFree(tel);

    final guestHouse = memberHouseId?.trim();
    final ownerHouse = ownerOfHouseId?.trim();
    final legacyOwner = houseOwnerUserId?.trim();

    if (guestHouse != null &&
        guestHouse.isNotEmpty &&
        ownerHouse != null &&
        ownerHouse.isNotEmpty) {
      throw AuthFailure(
        'Choisissez soit une maison invité, soit une maison propriétaire.',
      );
    }

    if (guestHouse != null && guestHouse.isNotEmpty) {
      final houseSnap =
          await FirestoreHousePaths.houseDoc(FirebaseFirestore.instance, guestHouse).get();
      if (!houseSnap.exists) {
        throw AuthFailure('Maison introuvable ($guestHouse).');
      }
    }
    if (ownerHouse != null && ownerHouse.isNotEmpty) {
      final houseSnap =
          await FirestoreHousePaths.houseDoc(FirebaseFirestore.instance, ownerHouse).get();
      if (!houseSnap.exists) {
        throw AuthFailure('Maison introuvable ($ownerHouse).');
      }
      final existingOwner =
          (houseSnap.data()?[FirestoreSchema.fieldOwnerUserId] as String?)?.trim();
      if (existingOwner != null && existingOwner.isNotEmpty) {
        throw AuthFailure('Cette maison a déjà un propriétaire.');
      }
    }
    if (legacyOwner != null && legacyOwner.isNotEmpty) {
      final ownerSnap = await _users.doc(legacyOwner).get();
      if (!ownerSnap.exists) {
        throw AuthFailure('Propriétaire de maison introuvable ($legacyOwner).');
      }
    }

    final userId = await _allocateUserId(mail);
    final initialRole =
        ownerHouse != null && ownerHouse.isNotEmpty ? UserRole.owner : UserRole.user;

    final user = AppUser(
      userId: userId,
      name: name.trim(),
      email: mail,
      phone: tel,
      passwordHash: PasswordHasher.hash(plainPassword),
      role: initialRole,
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
        'theme': 'dark',
        'notifications': true,
        'language': 'fr',
        'fontFamily': 'montserrat',
        'fontScale': 1.0,
        'showDateTime': false,
        'use24HourTime': true,
        'datePattern': 'dd/MM/yyyy',
        'alertThreshold': 35.0,
        'pirAlertsEnabled': true,
        'sensorAlerts': {
          for (final e in SensorThresholdConfig.defaultsByType.entries)
            e.key: e.value.toFirestore(),
        },
      },
    );
    await batch.commit();

    if (guestHouse != null && guestHouse.isNotEmpty) {
      await AdminRepository.instance.assignMemberToHouse(
        houseId: guestHouse,
        memberUserId: userId,
      );
    } else if (ownerHouse != null && ownerHouse.isNotEmpty) {
      await AdminRepository.instance.assignOwnerToHouse(
        houseId: ownerHouse,
        ownerUserId: userId,
      );
    } else if (legacyOwner != null && legacyOwner.isNotEmpty) {
      final houseId = await HouseResolver.resolveHouseIdForOwner(
        legacyOwner,
        FirebaseFirestore.instance,
      );
      await AdminRepository.instance.assignMemberToHouse(
        houseId: houseId,
        memberUserId: userId,
      );
    } else {
      await FirestoreHousePaths.ensureInitialized(
        FirebaseFirestore.instance,
        userId,
        ownerUserId: initialRole == UserRole.owner ? userId : null,
      );
    }

    return await fetchUserById(userId) ?? user;
  }

  /// Lie un utilisateur à une maison en tant qu’invité.
  Future<void> assignUserToHouse({
    required String houseId,
    required String memberUserId,
  }) async {
    await AdminRepository.instance.assignMemberToHouse(
      houseId: houseId,
      memberUserId: memberUserId,
    );
  }

  /// Legacy : rattache via l’ID du propriétaire.
  Future<void> assignUserToHouseByOwner({
    required String ownerUserId,
    required String memberUserId,
  }) async {
    final houseId = await HouseResolver.resolveHouseIdForOwner(
      ownerUserId,
      FirebaseFirestore.instance,
    );
    await assignUserToHouse(houseId: houseId, memberUserId: memberUserId);
    await _users.doc(memberUserId.trim()).set(
      {'houseOwnerUserId': ownerUserId.trim()},
      SetOptions(merge: true),
    );
  }

  Future<AppUser?> fetchUserById(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return null;
    final snap = await _users.doc(id).get();
    if (!snap.exists) return null;
    return AppUser.fromFirestore(id, snap.data()!);
  }

  /// Mise à jour profil par l’admin (sans backend dédié).
  Future<void> updateUserByAdmin({
    required String userId,
    required String name,
    required String email,
    required String phone,
    String? newPlainPassword,
    String? role,
  }) async {
    await _ensureAnonymousAuth();
    final mail = email.trim().toLowerCase();
    final tel = phone.trim();
    final displayName = name.trim();
    if (mail.isEmpty || tel.isEmpty || displayName.isEmpty) {
      throw AuthFailure('Nom, email et téléphone sont obligatoires.');
    }

    final snap = await _resolveUserDoc(userId);
    final docId = snap.id;
    final existing = AppUser.fromFirestore(docId, snap.data()!);
    if (UserRole.isAdmin(existing.role)) {
      throw AuthFailure('Le rôle administrateur ne peut pas être modifié ici.');
    }

    await _assertEmailFree(mail, exceptUserId: docId);
    await _assertPhoneFree(tel, exceptUserId: docId);

    final patch = <String, dynamic>{
      FirestoreSchema.fieldUserId: docId,
      'name': displayName,
      'email': mail,
      'phone': tel,
    };
    if (newPlainPassword != null && newPlainPassword.trim().isNotEmpty) {
      patch['password'] = PasswordHasher.hash(newPlainPassword.trim());
    }

    String? normalizedRole;
    if (role != null) {
      normalizedRole = UserRole.normalize(role);
      if (UserRole.isAdmin(normalizedRole)) {
        throw AuthFailure(
          'Seuls les rôles utilisateur et propriétaire sont autorisés.',
        );
      }
      patch['role'] = normalizedRole;
      if (UserRole.isOwner(normalizedRole)) {
        final linked = existing.houseOwnerUserId?.trim();
        if (linked != null && linked.isNotEmpty) {
          await unassignUserFromHouse(docId);
        }
        patch['houseOwnerUserId'] = FieldValue.delete();
      }
    }

    try {
      await _users.doc(docId).set(patch, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw _mapFirestoreError(e);
    }

    if (normalizedRole != null && UserRole.isOwner(normalizedRole)) {
      try {
        final houseId = existing.ownedHouseId?.trim().isNotEmpty == true
            ? existing.ownedHouseId!.trim()
            : docId;
        patch[FirestoreSchema.fieldOwnedHouseId] = houseId;
        await FirestoreHousePaths.ensureInitialized(
          FirebaseFirestore.instance,
          houseId,
          ownerUserId: docId,
        );
        await FirestoreHousePaths.houseDoc(FirebaseFirestore.instance, houseId)
            .set(
          {FirestoreSchema.fieldOwnerUserId: docId},
          SetOptions(merge: true),
        );
        await HouseInvitesRepository.instance.ensurePrimaryInvite(houseId);
      } catch (e) {
        // ignore: avoid_print
        print('[Admin] invite maison ignorée pour $docId: $e');
      }
    }
  }

  /// Retire un membre de sa maison.
  Future<void> unassignUserFromHouse(String memberUserId) async {
    final member = memberUserId.trim();
    if (member.isEmpty) throw AuthFailure('Identifiant invalide.');

    final memberSnap = await _users.doc(member).get();
    if (!memberSnap.exists) throw AuthFailure('Utilisateur introuvable.');
    final memberUser = AppUser.fromFirestore(member, memberSnap.data()!);

    String? houseId = memberUser.memberHouseId?.trim();
    if (houseId == null || houseId.isEmpty) {
      final owner = memberUser.houseOwnerUserId?.trim();
      if (owner != null && owner.isNotEmpty) {
        houseId = await HouseResolver.resolveHouseIdForOwner(
          owner,
          FirebaseFirestore.instance,
        );
      }
    }
    if (houseId == null || houseId.isEmpty) {
      await _users.doc(member).set(
        {
          'houseOwnerUserId': FieldValue.delete(),
          FirestoreSchema.fieldMemberHouseId: FieldValue.delete(),
        },
        SetOptions(merge: true),
      );
      return;
    }

    await AdminRepository.instance.removeMemberFromHouse(
      houseId: houseId,
      memberUserId: member,
    );
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

  Future<void> _deleteSubcollection(
    DocumentReference<Map<String, dynamic>> parent,
    String subcollection,
  ) async {
    final col = parent.collection(subcollection);
    while (true) {
      final snap = await col.limit(200).get();
      if (snap.docs.isEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Suppression définitive d’un utilisateur standard par l’admin.
  Future<void> deleteUserByAdmin({
    required String userId,
    String? actingAdminUserId,
  }) async {
    final id = userId.trim();
    if (id.isEmpty) throw AuthFailure('Identifiant invalide.');

    final actor = actingAdminUserId?.trim();
    if (actor != null && actor.isNotEmpty && actor == id) {
      throw AuthFailure('Vous ne pouvez pas supprimer votre propre compte.');
    }

    final snap = await _users.doc(id).get();
    if (!snap.exists) throw AuthFailure('Utilisateur introuvable.');

    final user = AppUser.fromFirestore(id, snap.data()!);
    if (user.isAdmin) {
      throw AuthFailure('Impossible de supprimer un administrateur.');
    }

    final devicesSnap = await FirestoreHousePaths.appareils(
      FirebaseFirestore.instance,
      id,
    ).limit(1).get();
    if (devicesSnap.docs.isNotEmpty) {
      throw AuthFailure(
        'Cet utilisateur possède des appareils. '
        'Supprimez d’abord sa maison depuis l’interface admin.',
      );
    }

    if (user.houseOwnerUserId != null) {
      await unassignUserFromHouse(id);
    }

    final prefSnap = await _users
        .doc(id)
        .collection(FirestoreSchema.preferencesSubcollection)
        .doc(FirestoreSchema.preferencesDocId)
        .get();
    final memberIds = <String>{
      if (prefSnap.data()?['memberUserIds'] is List)
        for (final item in prefSnap.data()!['memberUserIds'] as List)
          if (item is String && item.trim().isNotEmpty) item.trim(),
    };
    for (final member in memberIds) {
      await _users.doc(member).set(
        {'houseOwnerUserId': FieldValue.delete()},
        SetOptions(merge: true),
      );
    }

    final linkedSnap =
        await _users.where('houseOwnerUserId', isEqualTo: id).get();
    for (final doc in linkedSnap.docs) {
      await _users.doc(doc.id).set(
        {'houseOwnerUserId': FieldValue.delete()},
        SetOptions(merge: true),
      );
    }

    final userRef = _users.doc(id);
    await _deleteSubcollection(userRef, FirestoreSchema.rfidCardsSubcollection);
    await _deleteSubcollection(
      userRef,
      FirestoreSchema.preferencesSubcollection,
    );
    await userRef.delete();
  }
}
