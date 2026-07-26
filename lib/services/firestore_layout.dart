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

  /// Schéma canonique fixe — pas de probe réseau au démarrage (gain ~10–25 s sur Web).
  static Future<FirestorePaths> detectWritable(FirebaseFirestore db) async {
    return instance;
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
