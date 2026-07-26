import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/house_summary.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/firestore_house_paths.dart';
import 'package:smart_home/services/firestore_schema.dart';
import 'package:smart_home/services/house_resolver.dart';

class AdminFailure implements Exception {
  AdminFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Opérations réservées aux administrateurs (maisons / utilisateurs).
class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreSchema.usersCollection);

  DocumentReference<Map<String, dynamic>> _preferencesRef(String userId) =>
      _users
          .doc(userId)
          .collection(FirestoreSchema.preferencesSubcollection)
          .doc(FirestoreSchema.preferencesDocId);

  Future<int> _countRooms(String houseId) async {
    final snap = await FirestoreHousePaths.pieces(_db, houseId).get();
    return snap.docs.length;
  }

  Future<int> _countDevices(String houseId) async {
    final snap = await FirestoreHousePaths.appareils(_db, houseId).get();
    return snap.docs.length;
  }

  List<String> _memberIdsFromPrefs(Map<String, dynamic>? prefs) {
    if (prefs == null) return const [];
    final raw = prefs['memberUserIds'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  bool _shouldIncludeHouseDoc({
    required String houseId,
    required Map<String, dynamic> data,
    required int roomCount,
    required int deviceCount,
    String? ownerUserId,
  }) {
    if (data[FirestoreSchema.fieldCreatedByAdmin] == true) return true;
    if (data[FirestoreSchema.fieldHouseName] != null &&
        (data[FirestoreSchema.fieldHouseName] as String).trim().isNotEmpty) {
      return true;
    }
    if (ownerUserId != null && ownerUserId.isNotEmpty) return true;
    if (roomCount > 0 || deviceCount > 0) return true;
    if (houseId.startsWith('house_')) return true;
    return false;
  }

  Future<HouseSummary?> _buildSummary(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final houseId = doc.id;
    final data = doc.data() ?? {};
    final name =
        (data[FirestoreSchema.fieldHouseName] as String?)?.trim().isNotEmpty ==
                true
            ? (data[FirestoreSchema.fieldHouseName] as String).trim()
            : houseId;

    var ownerUserId =
        (data[FirestoreSchema.fieldOwnerUserId] as String?)?.trim();
    if (ownerUserId == null || ownerUserId.isEmpty) {
      ownerUserId = await HouseResolver.ownerUserIdForHouse(houseId, _db);
    }

    final roomCount = await _countRooms(houseId);
    final deviceCount = await _countDevices(houseId);

    if (!_shouldIncludeHouseDoc(
      houseId: houseId,
      data: data,
      roomCount: roomCount,
      deviceCount: deviceCount,
      ownerUserId: ownerUserId,
    )) {
      return null;
    }

    var ownerName = '';
    var ownerEmail = '';
    if (ownerUserId != null && ownerUserId.isNotEmpty) {
      final ownerSnap = await _users.doc(ownerUserId).get();
      if (ownerSnap.exists) {
        final owner = AppUser.fromFirestore(ownerSnap.id, ownerSnap.data()!);
        ownerName = owner.name.isEmpty ? owner.userId : owner.name;
        ownerEmail = owner.email;
      }
    }

    final houseMembers = HouseResolver.memberIdsFromHouseData(data);
    var memberUserIds = houseMembers;
    if (memberUserIds.isEmpty &&
        ownerUserId != null &&
        ownerUserId.isNotEmpty) {
      final prefsSnap = await _preferencesRef(ownerUserId).get();
      memberUserIds = _memberIdsFromPrefs(prefsSnap.data());
    }

    return HouseSummary(
      houseId: houseId,
      name: name,
      ownerUserId: ownerUserId,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      roomCount: roomCount,
      deviceCount: deviceCount,
      memberUserIds: memberUserIds,
    );
  }

  Future<List<HouseSummary>> fetchHouses() async {
    final snap = await FirestoreHousePaths.houses(_db).get();
    final houses = <HouseSummary>[];
    for (final doc in snap.docs) {
      final summary = await _buildSummary(doc);
      if (summary != null) houses.add(summary);
    }
    houses.sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
    return houses;
  }

  Stream<List<HouseSummary>> watchHouses() async* {
    yield await fetchHouses();
    await for (final _ in FirestoreHousePaths.houses(_db).snapshots()) {
      yield await fetchHouses();
    }
  }

  /// Crée une maison sans propriétaire (admin).
  Future<HouseSummary> createHouseWithoutOwner({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw AdminFailure('Le nom de la maison est obligatoire.');
    }
    final houseId = await FirestoreHousePaths.createHouseWithoutOwner(
      db: _db,
      name: trimmed,
    );
    final summary = await _buildSummary(
      await FirestoreHousePaths.houseDoc(_db, houseId).get(),
    );
    if (summary == null) {
      throw AdminFailure('Maison créée mais introuvable ($houseId).');
    }
    return summary;
  }

  Future<void> _addMemberToHouseDoc({
    required String houseId,
    required String memberUserId,
  }) async {
    final ref = FirestoreHousePaths.houseDoc(_db, houseId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final members = <String>{
        ...HouseResolver.memberIdsFromHouseData(data),
        memberUserId.trim(),
      };
      tx.set(
        ref,
        {
          FirestoreSchema.fieldMemberUserIds: members.toList()..sort(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> _removeMemberFromHouseDoc({
    required String houseId,
    required String memberUserId,
  }) async {
    final ref = FirestoreHousePaths.houseDoc(_db, houseId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final members = <String>{
        ...HouseResolver.memberIdsFromHouseData(data),
      }..remove(memberUserId.trim());
      tx.set(
        ref,
        {
          FirestoreSchema.fieldMemberUserIds: members.toList()..sort(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Assigne un utilisateur comme invité d’une maison.
  Future<void> assignMemberToHouse({
    required String houseId,
    required String memberUserId,
  }) async {
    final hId = houseId.trim();
    final member = memberUserId.trim();
    if (hId.isEmpty || member.isEmpty) {
      throw AdminFailure('Identifiants invalides.');
    }

    final houseSnap = await FirestoreHousePaths.houseDoc(_db, hId).get();
    if (!houseSnap.exists) throw AdminFailure('Maison introuvable.');

    final memberSnap = await _users.doc(member).get();
    if (!memberSnap.exists) throw AdminFailure('Utilisateur introuvable.');
    final memberUser = AppUser.fromFirestore(member, memberSnap.data()!);
    if (memberUser.isAdmin) {
      throw AdminFailure('Un administrateur ne peut pas être invité.');
    }
    if (UserRole.isOwner(memberUser.role)) {
      throw AdminFailure(
        'Un propriétaire ne peut pas être invité. Retirez d’abord son rôle propriétaire.',
      );
    }

    final ownerId =
        (houseSnap.data()?[FirestoreSchema.fieldOwnerUserId] as String?)?.trim();
    if (ownerId != null && ownerId == member) {
      throw AdminFailure('Le propriétaire ne peut pas être invité de sa maison.');
    }

    if (memberUser.isMemberOfAnotherHouse) {
      throw AdminFailure(
        'Cet utilisateur est déjà rattaché à une autre maison.',
      );
    }

    await _users.doc(member).set(
      {
        FirestoreSchema.fieldMemberHouseId: hId,
        'houseOwnerUserId': FieldValue.delete(),
        'role': UserRole.user,
      },
      SetOptions(merge: true),
    );
    await _addMemberToHouseDoc(houseId: hId, memberUserId: member);

    if (ownerId != null && ownerId.isNotEmpty) {
      final prefRef = _preferencesRef(ownerId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(prefRef);
        final data = snap.data() ?? {};
        final members = <String>{
          ..._memberIdsFromPrefs(data),
          member,
        };
        tx.set(
          prefRef,
          {
            FirestoreSchema.fieldUserId: ownerId,
            'memberUserIds': members.toList()..sort(),
          },
          SetOptions(merge: true),
        );
      });
    }
  }

  /// Retire un invité d’une maison.
  Future<void> removeMemberFromHouse({
    required String houseId,
    required String memberUserId,
  }) async {
    final hId = houseId.trim();
    final member = memberUserId.trim();
    await _users.doc(member).set(
      {
        FirestoreSchema.fieldMemberHouseId: FieldValue.delete(),
        'houseOwnerUserId': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
    await _removeMemberFromHouseDoc(houseId: hId, memberUserId: member);

    final ownerId = await HouseResolver.ownerUserIdForHouse(hId, _db);
    if (ownerId != null && ownerId.isNotEmpty) {
      final prefRef = _preferencesRef(ownerId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(prefRef);
        final data = snap.data() ?? {};
        final members = <String>{..._memberIdsFromPrefs(data)}..remove(member);
        tx.set(
          prefRef,
          {
            FirestoreSchema.fieldUserId: ownerId,
            'memberUserIds': members.toList()..sort(),
          },
          SetOptions(merge: true),
        );
      });
    }
  }

  /// Désigne un utilisateur comme propriétaire d’une maison.
  Future<void> assignOwnerToHouse({
    required String houseId,
    required String ownerUserId,
  }) async {
    final hId = houseId.trim();
    final owner = ownerUserId.trim();
    if (hId.isEmpty || owner.isEmpty) {
      throw AdminFailure('Identifiants invalides.');
    }

    final houseRef = FirestoreHousePaths.houseDoc(_db, hId);
    final houseSnap = await houseRef.get();
    if (!houseSnap.exists) throw AdminFailure('Maison introuvable.');

    final ownerSnap = await _users.doc(owner).get();
    if (!ownerSnap.exists) throw AdminFailure('Utilisateur introuvable.');
    final ownerUser = AppUser.fromFirestore(owner, ownerSnap.data()!);
    if (ownerUser.isAdmin) {
      throw AdminFailure('Un administrateur ne peut pas être propriétaire.');
    }
    if (ownerUser.isMemberOfAnotherHouse) {
      throw AdminFailure(
        'Retirez d’abord cet utilisateur de sa maison actuelle.',
      );
    }

    final previousOwner =
        (houseSnap.data()?[FirestoreSchema.fieldOwnerUserId] as String?)?.trim();

    if (previousOwner != null &&
        previousOwner.isNotEmpty &&
        previousOwner != owner) {
      await _users.doc(previousOwner).set(
        {
          FirestoreSchema.fieldOwnedHouseId: FieldValue.delete(),
          'role': UserRole.user,
        },
        SetOptions(merge: true),
      );
    }

    await houseRef.set(
      {
        FirestoreSchema.fieldOwnerUserId: owner,
      },
      SetOptions(merge: true),
    );

    await _users.doc(owner).set(
      {
        'role': UserRole.owner,
        FirestoreSchema.fieldOwnedHouseId: hId,
        FirestoreSchema.fieldMemberHouseId: FieldValue.delete(),
        'houseOwnerUserId': FieldValue.delete(),
      },
      SetOptions(merge: true),
    );

    await FirestoreHousePaths.ensureInitialized(_db, hId, ownerUserId: owner);
  }

  Future<List<AppUser>> fetchAssignableUsers() async {
    final snap = await _users.orderBy('name').get();
    return [
      for (final doc in snap.docs)
        if (!UserRole.isAdmin(
          AppUser.fromFirestore(doc.id, doc.data()).role,
        ))
          AppUser.fromFirestore(doc.id, doc.data()),
    ];
  }
}
