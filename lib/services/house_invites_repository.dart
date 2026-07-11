import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/house_invite.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/firebase_anonymous_auth.dart';
import 'package:smart_home/services/firestore_auth_repository.dart';
import 'package:smart_home/services/firestore_house_paths.dart';
import 'package:smart_home/services/firestore_schema.dart';

class InviteFailure implements Exception {
  InviteFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Codes d’invitation maison : `maisons/{ownerId}/invites` + index `inviteCodes/{code}`.
class HouseInvitesRepository {
  HouseInvitesRepository._();
  static final HouseInvitesRepository instance = HouseInvitesRepository._();

  static const _codeLength = 5;
  static const _maxCodeAttempts = 30;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _invites(String ownerUserId) =>
      FirestoreHousePaths.invites(_db, ownerUserId);

  DocumentReference<Map<String, dynamic>> _codeIndex(String code) =>
      _db.collection(FirestoreSchema.inviteCodesCollection).doc(code);

  Future<void> _ensureAuth() async {
    if (Firebase.apps.isEmpty) {
      throw InviteFailure('Firebase non initialisé.');
    }
    await FirebaseAnonymousAuth.trySignIn();
  }

  /// Génère un code numérique à 5 chiffres (10000–99999).
  static String generateCode() {
    final r = Random.secure();
    return (10000 + r.nextInt(90000)).toString();
  }

  Future<String> _allocateUniqueCode() async {
    for (var i = 0; i < _maxCodeAttempts; i++) {
      final code = generateCode();
      final snap = await _codeIndex(code).get();
      if (!snap.exists) return code;
    }
    throw InviteFailure('Impossible de générer un code unique. Réessayez.');
  }

  Stream<List<HouseInvite>> watchInvites(String ownerUserId) {
    return _invites(ownerUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => HouseInvite.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<List<HouseInvite>> fetchInvites(String ownerUserId) async {
    final snap = await _invites(ownerUserId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => HouseInvite.fromFirestore(d.id, d.data()))
        .toList();
  }

  /// Crée le code principal de la maison (à la promotion propriétaire).
  Future<HouseInvite> ensurePrimaryInvite(String ownerUserId) async {
    await _ensureAuth();
    final owner = ownerUserId.trim();
    if (owner.isEmpty) throw InviteFailure('Propriétaire invalide.');

    await FirestoreHousePaths.ensureInitialized(_db, owner);

    final existing = await _invites(owner)
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return HouseInvite.fromFirestore(
        existing.docs.first.id,
        existing.docs.first.data(),
      );
    }

    return createInvite(
      ownerUserId: owner,
      label: 'Code maison',
      isPrimary: true,
    );
  }

  /// Nouveau code invité (propriétaire).
  Future<HouseInvite> createInvite({
    required String ownerUserId,
    String label = 'Invitation',
    bool isPrimary = false,
    Duration? expiresIn,
  }) async {
    await _ensureAuth();
    final owner = ownerUserId.trim();
    if (owner.isEmpty) throw InviteFailure('Propriétaire invalide.');

    final code = await _allocateUniqueCode();
    final inviteRef = _invites(owner).doc();
    final expiresAt =
        expiresIn != null ? DateTime.now().add(expiresIn) : null;

    final invite = HouseInvite(
      inviteId: inviteRef.id,
      code: code,
      ownerUserId: owner,
      label: label.trim().isEmpty ? 'Invitation' : label.trim(),
      revoked: false,
      usedCount: 0,
      expiresAt: expiresAt,
      isPrimary: isPrimary,
    );

    final batch = _db.batch();
    batch.set(inviteRef, invite.toCreatePayload());
    batch.set(_codeIndex(code), {
      'code': code,
      'ownerUserId': owner,
      'inviteId': inviteRef.id,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return invite;
  }

  Future<void> revokeInvite({
    required String ownerUserId,
    required String inviteId,
  }) async {
    await _ensureAuth();
    final owner = ownerUserId.trim();
    final id = inviteId.trim();
    if (owner.isEmpty || id.isEmpty) {
      throw InviteFailure('Invitation invalide.');
    }

    final inviteRef = _invites(owner).doc(id);
    final snap = await inviteRef.get();
    if (!snap.exists) throw InviteFailure('Invitation introuvable.');

    final invite = HouseInvite.fromFirestore(id, snap.data()!);
    if (invite.isPrimary) {
      throw InviteFailure('Le code principal de la maison ne peut pas être révoqué.');
    }

    final batch = _db.batch();
    batch.set(inviteRef, {'revoked': true}, SetOptions(merge: true));
    batch.set(
      _codeIndex(invite.code),
      {'active': false},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Rejoint une maison avec un code à 5 chiffres.
  Future<AppUser> joinHouseWithCode({
    required String memberUserId,
    required String code,
  }) async {
    await _ensureAuth();
    final member = memberUserId.trim();
    final normalized = code.trim();
    if (member.isEmpty) throw InviteFailure('Session invalide.');
    if (normalized.length != _codeLength ||
        int.tryParse(normalized) == null) {
      throw InviteFailure('Le code doit contenir exactement 5 chiffres.');
    }

    final memberSnap = await _db.collection('users').doc(member).get();
    if (!memberSnap.exists) throw InviteFailure('Utilisateur introuvable.');
    final memberUser = AppUser.fromFirestore(member, memberSnap.data()!);

    if (memberUser.isAdmin) {
      throw InviteFailure('Un administrateur ne peut pas rejoindre une maison.');
    }
    if (memberUser.isOwner) {
      throw InviteFailure(
        'En tant que propriétaire, vous gérez votre propre maison.',
      );
    }
    if (memberUser.isMemberOfAnotherHouse) {
      throw InviteFailure(
        'Vous êtes déjà membre d’une maison. Quittez-la d’abord.',
      );
    }

    final indexSnap = await _codeIndex(normalized).get();
    if (!indexSnap.exists) {
      throw InviteFailure('Code invalide ou expiré.');
    }
    final index = indexSnap.data()!;
    if (index['active'] != true) {
      throw InviteFailure('Ce code n’est plus actif.');
    }

    final ownerUserId = (index['ownerUserId'] as String?)?.trim() ?? '';
    final inviteId = (index['inviteId'] as String?)?.trim() ?? '';
    if (ownerUserId.isEmpty || inviteId.isEmpty) {
      throw InviteFailure('Code invalide.');
    }
    if (ownerUserId == member) {
      throw InviteFailure('Vous ne pouvez pas rejoindre votre propre maison.');
    }

    final ownerSnap = await _db.collection('users').doc(ownerUserId).get();
    if (!ownerSnap.exists) {
      throw InviteFailure('Maison introuvable.');
    }
    final ownerUser = AppUser.fromFirestore(ownerUserId, ownerSnap.data()!);
    if (!UserRole.isOwner(ownerUser.role)) {
      throw InviteFailure('Cette maison n’accepte plus de membres.');
    }

    final inviteRef = _invites(ownerUserId).doc(inviteId);
    final inviteSnap = await inviteRef.get();
    if (!inviteSnap.exists) {
      throw InviteFailure('Invitation introuvable.');
    }
    final invite = HouseInvite.fromFirestore(inviteId, inviteSnap.data()!);
    if (!invite.isActive) {
      throw InviteFailure('Ce code a expiré ou a été révoqué.');
    }
    if (invite.usedByUserIds.contains(member)) {
      throw InviteFailure('Vous êtes déjà membre de cette maison.');
    }

    await FirestoreAuthRepository.instance.assignUserToHouse(
      ownerUserId: ownerUserId,
      memberUserId: member,
    );

    await inviteRef.set(
      {
        'usedCount': FieldValue.increment(1),
        'usedByUserIds': FieldValue.arrayUnion([member]),
      },
      SetOptions(merge: true),
    );

    final updatedSnap = await _db.collection('users').doc(member).get();
    return AppUser.fromFirestore(member, updatedSnap.data()!);
  }

  /// Retire un membre (propriétaire uniquement, côté UI).
  Future<void> removeMember({
    required String ownerUserId,
    required String memberUserId,
  }) async {
    await _ensureAuth();
    final owner = ownerUserId.trim();
    final member = memberUserId.trim();
    if (owner.isEmpty || member.isEmpty) {
      throw InviteFailure('Identifiants invalides.');
    }

    final memberSnap = await _db.collection('users').doc(member).get();
    if (!memberSnap.exists) throw InviteFailure('Membre introuvable.');
    final linked =
        (memberSnap.data()?['houseOwnerUserId'] as String?)?.trim();
    if (linked != owner) {
      throw InviteFailure('Ce membre n’appartient pas à votre maison.');
    }

    await FirestoreAuthRepository.instance.unassignUserFromHouse(member);
  }

  /// Quitte la maison actuelle (membre invité).
  Future<AppUser> leaveHouse(String memberUserId) async {
    await _ensureAuth();
    final member = memberUserId.trim();
    if (member.isEmpty) throw InviteFailure('Session invalide.');

    final memberSnap = await _db.collection('users').doc(member).get();
    if (!memberSnap.exists) throw InviteFailure('Utilisateur introuvable.');
    final user = AppUser.fromFirestore(member, memberSnap.data()!);
    if (!user.isMemberOfAnotherHouse) {
      throw InviteFailure('Vous n’êtes membre d’aucune maison.');
    }

    await FirestoreAuthRepository.instance.unassignUserFromHouse(member);
    final updatedSnap = await _db.collection('users').doc(member).get();
    return AppUser.fromFirestore(member, updatedSnap.data()!);
  }

  /// Liste des membres rattachés à une maison.
  Future<List<AppUser>> fetchMembers(String ownerUserId) async {
    final prefSnap = await _db
        .collection('users')
        .doc(ownerUserId.trim())
        .collection(FirestoreSchema.preferencesSubcollection)
        .doc(FirestoreSchema.preferencesDocId)
        .get();
    final raw = prefSnap.data()?['memberUserIds'];
    final ids = <String>{
      if (raw is List)
        for (final item in raw)
          if (item is String && item.trim().isNotEmpty) item.trim(),
    };
    if (ids.isEmpty) return [];

    final users = <AppUser>[];
    for (final id in ids) {
      final snap = await _db.collection('users').doc(id).get();
      if (snap.exists) {
        users.add(AppUser.fromFirestore(id, snap.data()!));
      }
    }
    users.sort((a, b) => a.name.compareTo(b.name));
    return users;
  }
}
