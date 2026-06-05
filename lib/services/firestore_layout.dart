import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/services/firestore_schema.dart';

/// Chemins Firestore — schéma académique racine uniquement.
class FirestorePaths {
  FirestorePaths._();

  static final FirestorePaths instance = FirestorePaths._();

  FirestoreFieldNames get fields =>
      FirestoreFieldNames.of(FirestoreCollectionNaming.canonical);

  static Future<FirestorePaths> detectWritable(FirebaseFirestore db) async {
    final ref =
        db.collection(FirestoreSchema.appareilsCollection).doc('_app_write_probe');
    try {
      await ref.set({
        FirestoreSchema.fieldUserId: '_app_write_probe',
        'piece': '_probe',
        'valeur': 0,
        'categorie': 'capteur',
      });
      await ref.delete();
      return instance;
    } on FirebaseException catch (e) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: e.code,
        message:
            'Collection /${FirestoreSchema.appareilsCollection} inaccessible : ${e.message}',
      );
    }
  }

  static FirestorePaths fallbackWithoutFirebase() => instance;

  CollectionReference<Map<String, dynamic>> appareilsRef(
    FirebaseFirestore db,
  ) =>
      db.collection(FirestoreSchema.appareilsCollection);

  CollectionReference<Map<String, dynamic>> devicesRef(
    FirebaseFirestore db,
  ) =>
      appareilsRef(db);

  String get debugLabel =>
      '/${FirestoreSchema.appareilsCollection} + /${FirestoreSchema.usersCollection}';

  static String get allPathsHint =>
      '/users/{userId}, /users/{userId}/preferences/settings, '
      '/users/{userId}/rfidCards, /${FirestoreSchema.appareilsCollection}, '
      '/${FirestoreSchema.accessLogsCollection}, /${FirestoreSchema.alertsCollection}';
}
