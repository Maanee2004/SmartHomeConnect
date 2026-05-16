import 'package:cloud_firestore/cloud_firestore.dart';

/// Schéma Firestore pour pièces / appareils (reprise des tests : racine plate ou sous `maison`).
enum FirestoreRoomsDevicesLayout {
  nestedUnderHome,
  flatRoot,
}

/// Résolution des chemins : d’abord `/{homeId}/_data/rooms`, sinon `/rooms` à la racine.
class FirestorePaths {
  FirestorePaths._({
    required this.homeCollectionId,
    required this.layout,
  });

  final String homeCollectionId;
  final FirestoreRoomsDevicesLayout layout;

  static const String dataDocumentId = '_data';

  static const bool kForceFlatRoot = bool.fromEnvironment(
    'FIRESTORE_USE_FLAT_COLLECTIONS',
    defaultValue: false,
  );

  /// Aligné bridge LED / MQTT (`FIRESTORE_HOME_ID`, défaut `maison`).
  static const String kDefaultHomeId = String.fromEnvironment(
    'FIRESTORE_HOME_ID',
    defaultValue: 'maison',
  );

  static Future<FirestorePaths> detect(FirebaseFirestore db) async {
    if (kForceFlatRoot) {
      return FirestorePaths._(
        homeCollectionId: kDefaultHomeId,
        layout: FirestoreRoomsDevicesLayout.flatRoot,
      );
    }
    final nestedSnap = await db
        .collection(kDefaultHomeId)
        .doc(dataDocumentId)
        .collection('rooms')
        .limit(1)
        .get();
    if (nestedSnap.docs.isNotEmpty) {
      return FirestorePaths._(
        homeCollectionId: kDefaultHomeId,
        layout: FirestoreRoomsDevicesLayout.nestedUnderHome,
      );
    }
    final flatSnap = await db.collection('rooms').limit(1).get();
    if (flatSnap.docs.isNotEmpty) {
      return FirestorePaths._(
        homeCollectionId: kDefaultHomeId,
        layout: FirestoreRoomsDevicesLayout.flatRoot,
      );
    }
    return FirestorePaths._(
      homeCollectionId: kDefaultHomeId,
      layout: FirestoreRoomsDevicesLayout.nestedUnderHome,
    );
  }

  static FirestorePaths fallbackWithoutFirebase() {
    return FirestorePaths._(
      homeCollectionId: kDefaultHomeId,
      layout: FirestoreRoomsDevicesLayout.nestedUnderHome,
    );
  }

  CollectionReference<Map<String, dynamic>> roomsRef(FirebaseFirestore db) {
    switch (layout) {
      case FirestoreRoomsDevicesLayout.flatRoot:
        return db.collection('rooms');
      case FirestoreRoomsDevicesLayout.nestedUnderHome:
        return db
            .collection(homeCollectionId)
            .doc(dataDocumentId)
            .collection('rooms');
    }
  }

  CollectionReference<Map<String, dynamic>> devicesRef(FirebaseFirestore db) {
    switch (layout) {
      case FirestoreRoomsDevicesLayout.flatRoot:
        return db.collection('devices');
      case FirestoreRoomsDevicesLayout.nestedUnderHome:
        return db
            .collection(homeCollectionId)
            .doc(dataDocumentId)
            .collection('devices');
    }
  }

  String get debugLabel => switch (layout) {
        FirestoreRoomsDevicesLayout.flatRoot => 'flat:/rooms,/devices',
        FirestoreRoomsDevicesLayout.nestedUnderHome =>
          'nested:/$homeCollectionId/$dataDocumentId/{{rooms|devices}}',
      };
}
