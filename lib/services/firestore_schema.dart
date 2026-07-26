/// Schéma Firestore — maison par utilisateur.
///
/// **Toutes** les données maison (appareils, pièces, alertes) vivent sous :
/// `maisons/{userId}/appareils`, `maisons/{userId}/pieces`, `maisons/{userId}/alerts`.
///
/// Alias conceptuel : `maison_<userId>` (ex. `maisons/usr_jean/...`).
/// L’ESP32 connaît `userId` et lit/écrit uniquement sous ce chemin.
///
/// État en ligne : `maisons/{userId}/isonline/isonline` → `{ isonline: bool }`.
///
/// Racine globale : `users`, `accessLogs` uniquement.
/// `users/{userId}/preferences/settings` = thème, langue, membres (pas les pièces).
class FirestoreSchema {
  FirestoreSchema._();

  static const usersCollection = 'users';
  static const maisonsCollection = 'maisons';
  static const accessLogsCollection = 'accessLogs';

  /// Sous-collections de `maisons/{userId}` — seul emplacement lecture/écriture.
  static const houseAppareilsSubcollection = 'appareils';
  static const houseAlertsSubcollection = 'alerts';
  static const housePiecesSubcollection = 'pieces';
  static const houseIsonlineSubcollection = 'isonline';
  static const houseInvitesSubcollection = 'invites';

  /// Index global pour rejoindre une maison par code : `inviteCodes/{code}`.
  static const inviteCodesCollection = 'inviteCodes';

  static const houseIsonlineDocId = 'isonline';
  static const fieldIsonline = 'isonline';

  static const preferencesSubcollection = 'preferences';
  static const rfidCardsSubcollection = 'rfidCards';
  static const preferencesDocId = 'settings';

  static const fieldUserId = 'userId';

  /// ID document `maisons/{houseId}` (peut différer du propriétaire).
  static const fieldHouseId = 'houseId';

  /// Nom affiché de la maison (admin).
  static const fieldHouseName = 'name';

  /// Propriétaire rattaché (`users/{ownerUserId}`), null si maison orpheline.
  static const fieldOwnerUserId = 'ownerUserId';

  /// Membres invités (maisons sans propriétaire ou complément admin).
  static const fieldMemberUserIds = 'memberUserIds';

  /// Maison gérée par un propriétaire (`users/{userId}.ownedHouseId`).
  static const fieldOwnedHouseId = 'ownedHouseId';

  /// Maison consultée par un invité (`users/{userId}.memberHouseId`).
  static const fieldMemberHouseId = 'memberHouseId';

  static const fieldCreatedByAdmin = 'createdByAdmin';

  /// Chemin logique : `maisons/usr_jean`.
  static String houseDocPath(String houseId) =>
      '$maisonsCollection/${houseId.trim()}';
}

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

  String get devicesCollection => FirestoreSchema.houseAppareilsSubcollection;

  String get deviceRoomFk => 'piece';

  static const fieldUserId = FirestoreSchema.fieldUserId;
}
