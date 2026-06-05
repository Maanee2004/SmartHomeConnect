import 'package:cloud_firestore/cloud_firestore.dart';

/// Schéma académique — collection racine `appareils` (SENSOR + ACTUATOR).
class AppareilSpec {
  AppareilSpec._();

  static const fieldPiece = 'piece';
  static const fieldValeur = 'valeur';
  static const fieldPin = 'pin';
  static const fieldCategorie = 'categorie';
  static const fieldType = 'type';
  static const fieldLabel = 'label';
  static const fieldUnit = 'unit';
  static const fieldSensorId = 'sensorId';
  static const fieldActuatorId = 'actuatorId';
  static const fieldTimestamp = 'timestamp';
  static const fieldLastChanged = 'lastChanged';
  static const fieldChangedBy = 'changedBy';
  static const fieldUserId = 'userId';

  static const allowedCategories = {'actionneur', 'capteur'};
  static const minPin = 2;
  static const maxPin = 53;

  static bool isSensorType(String type) {
    final t = type.toUpperCase().trim();
    return t == 'DHT22' ||
        t == 'DHT_TEMP' ||
        t == 'DHT_HUM' ||
        t == 'PIR' ||
        t == 'ULTRASON' ||
        t == 'RFID' ||
        t == 'SENSOR_TEMP';
  }

  /// Actionneurs (relais, lampe…) : broche GPIO obligatoire.
  static bool requiresPin(String type) => !isSensorType(type);

  static Map<String, dynamic> sensorPayload({
    required String appareilId,
    required String piece,
    required String type,
    required String label,
    required num valeur,
    required String unit,
    required String userId,
    int? pin,
  }) {
    validatePiece(piece);
    if (pin != null) validatePin(pin);
    return {
      fieldSensorId: appareilId,
      fieldType: type,
      fieldCategorie: 'capteur',
      fieldLabel: label.trim(),
      fieldValeur: valeur,
      fieldUnit: unit,
      fieldPiece: piece.trim(),
      fieldUserId: userId,
      fieldTimestamp: FieldValue.serverTimestamp(),
      if (pin != null) fieldPin: pin,
    };
  }

  static Map<String, dynamic> actuatorPayload({
    required String appareilId,
    required String piece,
    required String type,
    required String label,
    required int pin,
    int valeur = 0,
    required String userId,
    String? changedBy,
  }) {
    validatePiece(piece);
    validatePin(pin);
    validateValeurActionneur(valeur);
    return {
      fieldActuatorId: appareilId,
      fieldType: type,
      fieldCategorie: 'actionneur',
      fieldLabel: label.trim(),
      fieldValeur: valeur,
      fieldPin: pin,
      fieldPiece: piece.trim(),
      fieldUserId: userId,
      fieldLastChanged: FieldValue.serverTimestamp(),
      if (changedBy != null && changedBy.isNotEmpty)
        fieldChangedBy: changedBy,
    };
  }

  static void validatePiece(String piece) {
    if (piece.trim().isEmpty) {
      throw ArgumentError('piece requis (ex: Salon, Chambre)');
    }
  }

  static void validatePin(int pin) {
    if (pin < minPin || pin > maxPin) {
      throw ArgumentError('pin hors plage ($minPin–$maxPin) : $pin');
    }
  }

  static void validateValeurActionneur(int valeur) {
    if (valeur != 0 && valeur != 1) {
      throw ArgumentError('valeur actionneur : 0 ou 1');
    }
  }

  static Map<String, dynamic> commandPayload({
    required String? categorie,
    required Map<String, dynamic> patch,
    String? changedBy,
  }) {
    final cat = categorie?.trim() ?? 'actionneur';
    if (patch.containsKey('isOn')) {
      if (cat != 'actionneur') {
        throw ArgumentError('isOn réservé aux actionneurs');
      }
      final on = patch['isOn'] == true || patch['isOn'] == 1;
      return {
        fieldValeur: on ? 1 : 0,
        fieldLastChanged: FieldValue.serverTimestamp(),
        if (changedBy != null && changedBy.isNotEmpty)
          fieldChangedBy: changedBy,
      };
    }
    if (patch.containsKey(fieldValeur)) {
      final v = patch[fieldValeur];
      if (cat == 'actionneur') {
        final i = v is int ? v : (v is num ? v.toInt() : null);
        if (i == null || (i != 0 && i != 1)) {
          throw ArgumentError('valeur actionneur : int 0 ou 1');
        }
        return {
          fieldValeur: i,
          fieldLastChanged: FieldValue.serverTimestamp(),
          if (changedBy != null && changedBy.isNotEmpty)
            fieldChangedBy: changedBy,
        };
      }
      return {
        fieldValeur: v is num ? v : 0,
        fieldTimestamp: FieldValue.serverTimestamp(),
      };
    }
    throw ArgumentError('patch invalide');
  }

  static bool isAppareilDocument(Map<String, dynamic> data) =>
      data.containsKey(fieldPiece) && data.containsKey(fieldValeur);

  static String displayLabel(Map<String, dynamic> data, String id) {
    final label = (data[fieldLabel] as String?)?.trim();
    if (label != null && label.isNotEmpty) return label;
    return _labelFromId(id);
  }

  static String _labelFromId(String id) {
    final lower = id.toLowerCase();
    if (lower.startsWith('dht_temp')) return 'Température';
    if (lower.startsWith('dht_hum')) return 'Humidité';
    if (lower.startsWith('pir')) return 'Détecteur mouvement';
    if (lower.startsWith('lampe')) return 'Lampe';
    if (lower.startsWith('moteur')) return 'Moteur';
    if (lower.startsWith('buzzer')) return 'Alarme';
    return id;
  }

  static String typeFromData(Map<String, dynamic> data, String id) {
    final t = (data[fieldType] as String?)?.trim();
    if (t != null && t.isNotEmpty) return t.toUpperCase();
    final lower = id.toLowerCase();
    if (lower.startsWith('dht_temp')) return 'DHT_TEMP';
    if (lower.startsWith('dht_hum')) return 'DHT_HUM';
    if (lower.startsWith('pir')) return 'PIR';
    if (lower.startsWith('ultrason')) return 'ULTRASON';
    if (lower.startsWith('rfid')) return 'RFID';
    return 'RELAIS';
  }

  static String categorieFromData(Map<String, dynamic> data, String id) {
    final c = data[fieldCategorie] as String?;
    if (c != null && c.isNotEmpty) return c.trim();
    if (data.containsKey(fieldPin)) return 'actionneur';
    return 'capteur';
  }
}
