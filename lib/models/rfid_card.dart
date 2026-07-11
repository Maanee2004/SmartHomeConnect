import 'package:cloud_firestore/cloud_firestore.dart';

/// Effet déclenché quand un badge autorisé est scanné sur le lecteur lié.
enum RfidBadgeEffect {
  toggle,
  open;

  String get firestoreValue => name;

  static RfidBadgeEffect fromFirestore(Object? raw) {
    final v = raw?.toString().trim().toLowerCase();
    if (v == 'open' || v == 'ouvrir') return RfidBadgeEffect.open;
    return RfidBadgeEffect.toggle;
  }

  String get label => switch (this) {
        RfidBadgeEffect.toggle => 'Basculer la porte',
        RfidBadgeEffect.open => 'Ouvrir uniquement',
      };
}

/// Badge RFID autorisé — `users/{userId}/rfidCards/{cardId}`.
class RfidCard {
  const RfidCard({
    required this.cardId,
    required this.uid,
    required this.label,
    this.active = true,
    this.createdAt,
    this.servoId,
    this.readerId,
    this.effect = RfidBadgeEffect.toggle,
  });

  final String cardId;
  final String uid;
  final String label;
  final bool active;
  final DateTime? createdAt;

  /// Porte (doc `SERVO` dans `maisons/{userId}/appareils`).
  final String? servoId;

  /// Lecteur RFID optionnel (plusieurs lecteurs). `null` = tout lecteur lié à la porte.
  final String? readerId;
  final RfidBadgeEffect effect;

  factory RfidCard.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    DateTime? at;
    if (created is Timestamp) at = created.toDate();

    final rawUid = (data['uid'] as String?)?.trim() ??
        (data['valeur'] as String?)?.trim() ??
        '';
    final rawLabel = (data['label'] as String?)?.trim() ??
        (data['nom'] as String?)?.trim() ??
        (data['name'] as String?)?.trim() ??
        '';

    return RfidCard(
      cardId: id,
      uid: rawUid,
      label: rawLabel.isEmpty ? 'Badge' : rawLabel,
      active: data['active'] != false && data['actif'] != false,
      createdAt: at,
      servoId: (data['servoId'] as String?)?.trim(),
      readerId: (data['readerId'] as String?)?.trim(),
      effect: RfidBadgeEffect.fromFirestore(data['effect']),
    );
  }

  Map<String, dynamic> toCreatePayload({
    required String userId,
    required String uid,
    required String label,
    String? servoId,
    String? readerId,
    RfidBadgeEffect effect = RfidBadgeEffect.toggle,
  }) =>
      {
        'cardId': cardId,
        'userId': userId,
        'uid': uid,
        'label': label,
        'active': true,
        'effect': effect.firestoreValue,
        if (servoId != null && servoId.isNotEmpty) 'servoId': servoId,
        if (readerId != null && readerId.isNotEmpty) 'readerId': readerId,
        'createdAt': FieldValue.serverTimestamp(),
      };

  RfidCard copyWith({
    String? label,
    bool? active,
    String? servoId,
    String? readerId,
    RfidBadgeEffect? effect,
    bool clearServo = false,
    bool clearReader = false,
  }) =>
      RfidCard(
        cardId: cardId,
        uid: uid,
        label: label ?? this.label,
        active: active ?? this.active,
        createdAt: createdAt,
        servoId: clearServo ? null : (servoId ?? this.servoId),
        readerId: clearReader ? null : (readerId ?? this.readerId),
        effect: effect ?? this.effect,
      );
}
