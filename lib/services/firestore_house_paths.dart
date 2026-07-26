import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/services/firestore_schema.dart';

/// Chemins `maisons/{houseId}` — données IoT par maison (ESP32 : `houseId` connu).
///
/// Sous-collections : `appareils`, `alerts`, `pieces`.
/// État en ligne : `maisons/{userId}/isonline/isonline` → `{ isonline: bool }`.
class FirestoreHousePaths {
  FirestoreHousePaths._();

  static CollectionReference<Map<String, dynamic>> houses(FirebaseFirestore db) =>
      db.collection(FirestoreSchema.maisonsCollection);

  static DocumentReference<Map<String, dynamic>> houseDoc(
    FirebaseFirestore db,
    String houseId,
  ) =>
      houses(db).doc(houseId.trim());

  static CollectionReference<Map<String, dynamic>> appareils(
    FirebaseFirestore db,
    String houseId,
  ) =>
      houseDoc(db, houseId)
          .collection(FirestoreSchema.houseAppareilsSubcollection);

  static CollectionReference<Map<String, dynamic>> pieces(
    FirebaseFirestore db,
    String houseId,
  ) =>
      houseDoc(db, houseId).collection(FirestoreSchema.housePiecesSubcollection);

  static CollectionReference<Map<String, dynamic>> alerts(
    FirebaseFirestore db,
    String houseId,
  ) =>
      houseDoc(db, houseId).collection(FirestoreSchema.houseAlertsSubcollection);

  static CollectionReference<Map<String, dynamic>> invites(
    FirebaseFirestore db,
    String houseId,
  ) =>
      houseDoc(db, houseId).collection(FirestoreSchema.houseInvitesSubcollection);

  static DocumentReference<Map<String, dynamic>> isonlineDoc(
    FirebaseFirestore db,
    String houseId,
  ) =>
      houseDoc(db, houseId)
          .collection(FirestoreSchema.houseIsonlineSubcollection)
          .doc(FirestoreSchema.houseIsonlineDocId);

  /// Crée une maison admin sans propriétaire.
  static Future<String> createHouseWithoutOwner({
    required FirebaseFirestore db,
    required String name,
  }) async {
    final houseId = 'house_${DateTime.now().millisecondsSinceEpoch}';
    final root = houseDoc(db, houseId);
    await root.set({
      FirestoreSchema.fieldHouseId: houseId,
      FirestoreSchema.fieldHouseName: name.trim(),
      FirestoreSchema.fieldUserId: houseId,
      FirestoreSchema.fieldOwnerUserId: null,
      FirestoreSchema.fieldMemberUserIds: <String>[],
      FirestoreSchema.fieldCreatedByAdmin: true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await isonlineDoc(db, houseId).set({
      FirestoreSchema.fieldIsonline: false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return houseId;
  }

  /// Crée la racine maison + doc `isonline` si absents (legacy propriétaire).
  static Future<void> ensureInitialized(
    FirebaseFirestore db,
    String houseId, {
    String? ownerUserId,
    String? name,
  }) async {
    final id = houseId.trim();
    if (id.isEmpty) return;

    final root = houseDoc(db, id);
    final rootSnap = await root.get();
    if (!rootSnap.exists) {
      await root.set({
        FirestoreSchema.fieldHouseId: id,
        FirestoreSchema.fieldUserId: id,
        if (name != null && name.trim().isNotEmpty)
          FirestoreSchema.fieldHouseName: name.trim(),
        if (ownerUserId != null && ownerUserId.trim().isNotEmpty)
          FirestoreSchema.fieldOwnerUserId: ownerUserId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final onlineRef = isonlineDoc(db, id);
    final onlineSnap = await onlineRef.get();
    if (!onlineSnap.exists) {
      await onlineRef.set({
        FirestoreSchema.fieldIsonline: false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
