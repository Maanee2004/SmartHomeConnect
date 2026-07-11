import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/services/firestore_schema.dart';

/// Chemins `maisons/{userId}` — une maison par utilisateur (ESP32 : `userId` connu).
///
/// Sous-collections : `appareils`, `alerts`, `pieces`.
/// État en ligne : `maisons/{userId}/isonline/isonline` → `{ isonline: bool }`.
class FirestoreHousePaths {
  FirestoreHousePaths._();

  static CollectionReference<Map<String, dynamic>> houses(FirebaseFirestore db) =>
      db.collection(FirestoreSchema.maisonsCollection);

  static DocumentReference<Map<String, dynamic>> houseDoc(
    FirebaseFirestore db,
    String userId,
  ) =>
      houses(db).doc(userId.trim());

  static CollectionReference<Map<String, dynamic>> appareils(
    FirebaseFirestore db,
    String userId,
  ) =>
      houseDoc(db, userId).collection(FirestoreSchema.houseAppareilsSubcollection);

  static CollectionReference<Map<String, dynamic>> pieces(
    FirebaseFirestore db,
    String userId,
  ) =>
      houseDoc(db, userId).collection(FirestoreSchema.housePiecesSubcollection);

  static CollectionReference<Map<String, dynamic>> alerts(
    FirebaseFirestore db,
    String userId,
  ) =>
      houseDoc(db, userId).collection(FirestoreSchema.houseAlertsSubcollection);

  static CollectionReference<Map<String, dynamic>> invites(
    FirebaseFirestore db,
    String userId,
  ) =>
      houseDoc(db, userId).collection(FirestoreSchema.houseInvitesSubcollection);

  static DocumentReference<Map<String, dynamic>> isonlineDoc(
    FirebaseFirestore db,
    String userId,
  ) =>
      houseDoc(db, userId)
          .collection(FirestoreSchema.houseIsonlineSubcollection)
          .doc(FirestoreSchema.houseIsonlineDocId);

  /// Crée la racine maison + doc `isonline` si absents.
  static Future<void> ensureInitialized(
    FirebaseFirestore db,
    String userId,
  ) async {
    final id = userId.trim();
    if (id.isEmpty) return;

    final root = houseDoc(db, id);
    final rootSnap = await root.get();
    if (!rootSnap.exists) {
      await root.set({
        FirestoreSchema.fieldUserId: id,
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
