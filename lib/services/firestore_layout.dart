import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/services/firestore_house_paths.dart';
import 'package:smart_home/services/firestore_schema.dart';

/// Détection d’accès Firestore — schéma `maisons/{userId}/appareils`.
class FirestorePaths {
  FirestorePaths._();

  static final FirestorePaths instance = FirestorePaths._();

  FirestoreFieldNames get fields =>
      FirestoreFieldNames.of(FirestoreCollectionNaming.canonical);

  static Future<FirestorePaths> detectWritable(FirebaseFirestore db) async {
    const probeUserId = '_app_write_probe';
    await FirestoreHousePaths.ensureInitialized(db, probeUserId);
    final ref = FirestoreHousePaths.appareils(db, probeUserId).doc('_probe');
    try {
      await ref
          .set({
            FirestoreSchema.fieldUserId: probeUserId,
            'piece': '_probe',
            'valeur': '0',
            'categorie': 'capteur',
          })
          .timeout(const Duration(seconds: 12));
      await ref.delete().timeout(const Duration(seconds: 12));
      return instance;
    } on TimeoutException {
      return fallbackWithoutFirebase();
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: e.code,
        message:
            'Collection /${FirestoreSchema.maisonsCollection}/$probeUserId/${FirestoreSchema.houseAppareilsSubcollection} inaccessible : ${e.message}',
      );
    }
  }

  static FirestorePaths fallbackWithoutFirebase() => instance;

  CollectionReference<Map<String, dynamic>> appareilsRef(
    FirebaseFirestore db,
    String userId,
  ) =>
      FirestoreHousePaths.appareils(db, userId);

  CollectionReference<Map<String, dynamic>> devicesRef(
    FirebaseFirestore db,
    String userId,
  ) =>
      appareilsRef(db, userId);

  String get debugLabel =>
      '/${FirestoreSchema.maisonsCollection}/{userId} + /${FirestoreSchema.usersCollection}';

  static String get allPathsHint =>
      '/users/{userId}, /users/{userId}/preferences/settings, '
      '/users/{userId}/rfidCards, '
      '/${FirestoreSchema.maisonsCollection}/{userId}/appareils, '
      '/${FirestoreSchema.maisonsCollection}/{userId}/pieces, '
      '/${FirestoreSchema.maisonsCollection}/{userId}/alerts, '
      '/${FirestoreSchema.maisonsCollection}/{userId}/isonline/isonline, '
      '/${FirestoreSchema.accessLogsCollection}';
}
