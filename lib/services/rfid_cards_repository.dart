import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/models/appareil_spec.dart';
import 'package:smart_home/models/rfid_card.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_house_paths.dart';
import 'package:smart_home/services/firestore_schema.dart';

class RfidCardFailure implements Exception {
  RfidCardFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class RfidCardsRepository {
  RfidCardsRepository._();
  static final RfidCardsRepository instance = RfidCardsRepository._();

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection(FirestoreSchema.usersCollection);

  String _ownerUserId() {
    final owner = AuthService.instance.houseOwnerUserId;
    if (owner != null && owner.isNotEmpty) return owner;
    final id = AuthService.instance.currentUserId;
    if (id == null || id.isEmpty) {
      throw RfidCardFailure('Utilisateur non connecté.');
    }
    return id;
  }

  String _houseId() {
    final active = AuthService.instance.activeHouseId;
    if (active != null && active.isNotEmpty) return active;
    return _ownerUserId();
  }

  CollectionReference<Map<String, dynamic>> _cardsCol(String userId) =>
      _users.doc(userId).collection(FirestoreSchema.rfidCardsSubcollection);

  CollectionReference<Map<String, dynamic>> _appareilsCol(String userId) =>
      FirestoreHousePaths.appareils(FirebaseFirestore.instance, userId);

  static String _normalizeUid(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String cardDocIdFromUid(String uid) {
    final n = _normalizeUid(uid);
    final base = n.isEmpty ? 'card_unknown' : 'card_$n';
    return base.length > 120 ? base.substring(0, 120) : base;
  }

  Stream<List<RfidCard>> watchCards() {
    final userId = _ownerUserId();
    return _cardsCol(userId).snapshots().map((snap) {
      final cards = snap.docs
          .map((d) => RfidCard.fromFirestore(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.label.compareTo(b.label));
      return cards;
    });
  }

  Future<void> _assertUidUnique(
    String userId,
    String uid, {
    String? exceptCardId,
  }) async {
    final target = _normalizeUid(uid);
    if (target.isEmpty) throw RfidCardFailure('UID du badge invalide.');
    final snap = await _cardsCol(userId).get();
    for (final doc in snap.docs) {
      if (exceptCardId != null && doc.id == exceptCardId) continue;
      final existing = RfidCard.fromFirestore(doc.id, doc.data());
      if (_normalizeUid(existing.uid) == target) {
        throw RfidCardFailure('Ce badge est déjà enregistré.');
      }
    }
  }

  Future<String> addCard({
    required String uid,
    required String label,
    String? servoId,
    String? readerId,
    RfidBadgeEffect effect = RfidBadgeEffect.toggle,
  }) async {
    final userId = _ownerUserId();
    final normalizedUid = _normalizeUid(uid);
    final displayLabel = label.trim();
    if (normalizedUid.isEmpty) {
      throw RfidCardFailure('Saisis l’UID du badge (ex. A1B2C3D4).');
    }
    if (displayLabel.isEmpty) {
      throw RfidCardFailure('Donne un nom au badge (ex. Papa, Invité).');
    }

    await _assertUidUnique(userId, normalizedUid);
    final cardId = cardDocIdFromUid(normalizedUid);
    final card = RfidCard(
      cardId: cardId,
      uid: normalizedUid,
      label: displayLabel,
      servoId: servoId?.trim(),
      readerId: readerId?.trim(),
      effect: effect,
    );
    await _cardsCol(userId).doc(cardId).set(
          card.toCreatePayload(
            userId: userId,
            uid: normalizedUid,
            label: displayLabel,
            servoId: servoId,
            readerId: readerId,
            effect: effect,
          ),
        );
    return cardId;
  }

  Future<void> updateCard({
    required String cardId,
    String? label,
    bool? active,
    String? servoId,
    String? readerId,
    RfidBadgeEffect? effect,
    bool clearServo = false,
    bool clearReader = false,
  }) async {
    final userId = _ownerUserId();
    final id = cardId.trim();
    if (id.isEmpty) return;

    final ref = _cardsCol(userId).doc(id);
    final snap = await ref.get();
    if (!snap.exists) throw RfidCardFailure('Badge introuvable.');

    final patch = <String, dynamic>{};
    if (label != null) {
      final t = label.trim();
      if (t.isEmpty) throw RfidCardFailure('Le nom du badge ne peut pas être vide.');
      patch['label'] = t;
    }
    if (active != null) patch['active'] = active;
    if (effect != null) patch['effect'] = effect.firestoreValue;
    if (clearServo) {
      patch['servoId'] = FieldValue.delete();
    } else if (servoId != null) {
      patch['servoId'] = servoId.trim().isEmpty ? FieldValue.delete() : servoId.trim();
    }
    if (clearReader) {
      patch['readerId'] = FieldValue.delete();
    } else if (readerId != null) {
      patch['readerId'] =
          readerId.trim().isEmpty ? FieldValue.delete() : readerId.trim();
    }
    if (patch.isEmpty) return;
    await ref.set(patch, SetOptions(merge: true));
  }

  Future<void> deleteCard(String cardId) async {
    final userId = _ownerUserId();
    final id = cardId.trim();
    if (id.isEmpty) return;
    await _cardsCol(userId).doc(id).delete();
  }

  /// Lie un servomoteur (porte) à un lecteur RFID (`rfid_cible`).
  Future<void> linkServoToReader({
    required String servoId,
    String? readerId,
  }) async {
    final houseId = _houseId();
    final sid = servoId.trim();
    if (sid.isEmpty) return;

    final ref = _appareilsCol(houseId).doc(sid);
    final snap = await ref.get();
    if (!snap.exists) throw RfidCardFailure('Porte (SERVO) introuvable.');

    final rid = readerId?.trim();
    await ref.set(
      {
        if (rid != null && rid.isNotEmpty)
          AppareilSpec.fieldRfidCible: rid
        else
          AppareilSpec.fieldRfidCible: FieldValue.delete(),
        AppareilSpec.fieldLastChanged: FieldValue.serverTimestamp(),
        if (AuthService.instance.currentUserId != null)
          AppareilSpec.fieldChangedBy: AuthService.instance.currentUserId,
      },
      SetOptions(merge: true),
    );
  }
}
