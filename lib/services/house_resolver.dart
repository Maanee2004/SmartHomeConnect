import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/firestore_house_paths.dart';
import 'package:smart_home/services/firestore_schema.dart';

/// Résout l’ID document Firestore `maisons/{houseId}` pour un utilisateur.
class HouseResolver {
  HouseResolver._();

  static Future<String> resolveHouseIdForUser(
    AppUser user,
    FirebaseFirestore db,
  ) async {
    final memberHouse = user.memberHouseId?.trim();
    if (memberHouse != null && memberHouse.isNotEmpty) return memberHouse;

    final linkedOwner = user.houseOwnerUserId?.trim();
    if (linkedOwner != null && linkedOwner.isNotEmpty) {
      return resolveHouseIdForOwner(linkedOwner, db);
    }

    if (UserRole.isOwner(user.role)) {
      final owned = user.ownedHouseId?.trim();
      if (owned != null && owned.isNotEmpty) return owned;
      return user.userId;
    }

    return user.userId;
  }

  static Future<String> resolveHouseIdForOwner(
    String ownerUserId,
    FirebaseFirestore db,
  ) async {
    final id = ownerUserId.trim();
    if (id.isEmpty) return id;
    final snap = await db.collection(FirestoreSchema.usersCollection).doc(id).get();
    if (snap.exists) {
      final owned =
          (snap.data()?[FirestoreSchema.fieldOwnedHouseId] as String?)?.trim();
      if (owned != null && owned.isNotEmpty) return owned;
    }
    return id;
  }

  static Future<String?> ownerUserIdForHouse(
    String houseId,
    FirebaseFirestore db,
  ) async {
    final id = houseId.trim();
    if (id.isEmpty) return null;
    final snap = await FirestoreHousePaths.houseDoc(db, id).get();
    if (!snap.exists) return null;
    final data = snap.data() ?? {};
    final explicit =
        (data[FirestoreSchema.fieldOwnerUserId] as String?)?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final userSnap =
        await db.collection(FirestoreSchema.usersCollection).doc(id).get();
    if (userSnap.exists &&
        UserRole.isOwner(userSnap.data()?['role'] as String?)) {
      return id;
    }
    return null;
  }

  static List<String> memberIdsFromHouseData(Map<String, dynamic>? data) {
    if (data == null) return const [];
    final raw = data[FirestoreSchema.fieldMemberUserIds];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}
