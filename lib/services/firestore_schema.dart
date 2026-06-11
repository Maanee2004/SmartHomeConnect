/// Schéma Firestore académique (UML).
///
/// Root: `users`, `appareils`, `accessLogs`, `alerts`
/// Pièces = champ `piece` sur `appareils` + liste `pieces` dans
/// `users/{userId}/preferences/settings`.
///
/// ### Rôle admin (login → interface admin)
/// Document `users/{userId}` :
/// ```json
/// { "role": "admin" }
/// ```
/// Valeurs : `"admin"` | `"user"` (défaut à l’inscription).
///
/// ### Membre rattaché à une maison
/// ```json
/// { "houseOwnerUserId": "usr_proprietaire" }
/// ```
/// + `users/{owner}/preferences/settings.memberUserIds[]`.
///
/// ### RFID + SERVO (liaison dynamique porte)
/// Lecteur RFID (capteur) :
/// ```json
/// { "type": "RFID", "categorie": "capteur", "unit": "string", "valeur": "0" }
/// ```
/// Servomoteur (actionneur) — champ `rfid_cible` = id du lecteur :
/// ```json
/// {
///   "type": "SERVO",
///   "categorie": "actionneur",
///   "unit": "angle",
///   "valeur": 0,
///   "rfid_cible": "salon2_lecteur_rfid"
/// }
/// ```
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
