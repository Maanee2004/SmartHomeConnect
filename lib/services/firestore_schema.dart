/// Schéma Firestore académique (UML).
///
/// Root: `users`, `appareils`, `accessLogs`, `alerts`
/// Pièces = champ `piece` sur `appareils` + liste `pieces` dans
/// `users/{userId}/preferences/settings`.
class FirestoreSchema {
  FirestoreSchema._();

  static const usersCollection = 'users';
  static const appareilsCollection = 'appareils';
  static const accessLogsCollection = 'accessLogs';
  static const alertsCollection = 'alerts';

  static const preferencesSubcollection = 'preferences';
  static const rfidCardsSubcollection = 'rfidCards';
  static const preferencesDocId = 'settings';

  static const fieldUserId = 'userId';
  static const fieldPieces = 'pieces';
}

/// Conservé pour compatibilité interne (legacy `rooms` / `devices`).
enum FirestoreCollectionNaming {
  canonical,
  legacy,
}

class FirestoreFieldNames {
  const FirestoreFieldNames._(this.naming);

  final FirestoreCollectionNaming naming;

  factory FirestoreFieldNames.of(FirestoreCollectionNaming naming) =>
      FirestoreFieldNames._(naming);

  bool get isCanonical => naming == FirestoreCollectionNaming.canonical;

  String get devicesCollection => FirestoreSchema.appareilsCollection;

  String get deviceRoomFk => 'piece';

  static const fieldUserId = FirestoreSchema.fieldUserId;
}
