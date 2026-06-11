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
  static const fieldTemperature = 'temperature';
  static const fieldHumidity = 'humidity';
  static const fieldRfidCible = 'rfid_cible';

  static const allowedCategories = {'actionneur', 'capteur'};
  static const minPin = 2;
  static const maxPin = 53;
  static const minServoAngle = 0;
  static const maxServoAngle = 180;

  /// Types **exacts** attendus par l'Arduino (`extrairePin` / `CONFIG:`).
  static const arduinoSensorTypes = {
    'DHT22',
    'DHT_TEMP',
    'DHT_HUM',
    'PIR',
    'RFID',
  };
  static const arduinoActuatorTypes = {'RELAIS', 'LED', 'SERVO'};
  static const unitBooleen = 'booleen';
  static const unitString = 'string';
  static const unitAngle = 'angle';

  /// Libellés UI → valeur Firestore (MAJUSCULES strictes).
  static const uiSensorTypes = <String, String>{
    'DHT22': 'Capteur DHT (temp. + humidité dans valeur)',
    'DHT_TEMP': 'Capteur DHT (DHT_TEMP — temp./hum. dans valeur)',
    'DHT_HUM': 'Humidité seule (legacy DHT_HUM)',
    'PIR': 'Mouvement (PIR)',
    'RFID': 'Lecteur RFID',
  };

  /// Format Arduino / Firestore : température et humidité dans [fieldValeur].
  static String formatDhtValeur(num temperature, num humidity) =>
      '${temperature.toStringAsFixed(1)}/${humidity.toStringAsFixed(1)}';

  static const uiActuatorTypes = <String, String>{
    'RELAIS': 'Relais / lampe / prise (RELAIS)',
    'LED': 'LED directe (LED)',
    'SERVO': 'Servo porte (SERVO + rfid_cible)',
  };

  static bool isSensorType(String type) {
    final t = type.toUpperCase().trim();
    return t == 'DHT22' ||
        t == 'DHT_TEMP' ||
        t == 'DHT_HUM' ||
        t == 'PIR' ||
        t == 'RFID' ||
        t == 'SENSOR_TEMP' ||
        t == 'HUMIDITY';
  }

  /// Normalise vers un type capteur Arduino (sinon [ArgumentError]).
  static String canonicalSensorType(String raw) {
    switch (raw.toUpperCase().trim()) {
      case 'DHT22':
        return 'DHT22';
      case 'SENSOR_TEMP':
      case 'TEMPERATURE':
      case 'DHT_TEMP':
        return 'DHT_TEMP';
      case 'DHT_HUM':
      case 'HUMIDITY':
        return 'DHT_HUM';
      case 'PIR':
        return 'PIR';
      case 'RFID':
        return 'RFID';
      default:
        throw ArgumentError(
          'Type capteur non supporté: « $raw ». '
          'Utilisez DHT22, DHT_TEMP, DHT_HUM, PIR ou RFID (MAJUSCULES).',
        );
    }
  }

  static bool isDhtCombinedType(String type) {
    try {
      return canonicalSensorType(type) == 'DHT22';
    } catch (_) {
      return false;
    }
  }

  /// Normalise vers un type actionneur Arduino (sinon [ArgumentError]).
  static String canonicalActuatorType(String raw) {
    switch (raw.toUpperCase().trim()) {
      case 'LIGHT':
      case 'LAMPE':
      case 'FAN':
      case 'VENTILATEUR':
      case 'OUTLET':
      case 'PRISE':
      case 'CAMERA':
      case 'RELAIS':
        return 'RELAIS';
      case 'LED':
        return 'LED';
      case 'SERVO':
      case 'SERVO_MOTEUR':
      case 'PORTE':
        return 'SERVO';
      default:
        throw ArgumentError(
          'Type actionneur non supporté: « $raw ». '
          'Utilisez RELAIS, LED ou SERVO (MAJUSCULES).',
        );
    }
  }

  /// Broche GPIO requise pour tous les types Arduino (CONFIG + commandes).
  static bool requiresPin(String type) {
    try {
      if (isSensorType(type)) {
        canonicalSensorType(type);
      } else {
        canonicalActuatorType(type);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static String unitForSensorType(String canonicalType) {
    switch (canonicalType) {
      case 'DHT22':
        return '°C/%';
      case 'DHT_TEMP':
        return '°C';
      case 'DHT_HUM':
        return '%';
      case 'PIR':
        return unitBooleen;
      case 'RFID':
        return unitString;
      default:
        return '';
    }
  }

  static String unitForActuatorType(String canonicalType) {
    if (canonicalType == 'SERVO') return unitAngle;
    return unitBooleen;
  }

  static Map<String, dynamic> sensorPayload({
    required String appareilId,
    required String piece,
    required String type,
    required String label,
    required Object valeur,
    required String unit,
    required String userId,
    int? pin,
    num? temperature,
    num? humidity,
  }) {
    validatePiece(piece);
    if (pin != null) validatePin(pin);
    final canonical = canonicalSensorType(type);
    final isDht = canonical == 'DHT22' || canonical == 'DHT_TEMP';
    final resolvedValeur = isDht && temperature is num && humidity is num
        ? formatDhtValeur(temperature, humidity)
        : valeur;
    return {
      fieldSensorId: appareilId,
      fieldType: canonical,
      fieldCategorie: 'capteur',
      fieldLabel: label.trim(),
      fieldValeur: resolvedValeur,
      fieldUnit: unit.isNotEmpty ? unit : unitForSensorType(canonical),
      fieldPiece: piece.trim(),
      fieldUserId: userId,
      fieldTimestamp: FieldValue.serverTimestamp(),
      if (pin != null) fieldPin: pin,
      if (isDht && temperature is num) fieldTemperature: temperature,
      if (isDht && humidity is num) fieldHumidity: humidity,
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
    String? rfidCible,
  }) {
    validatePiece(piece);
    validatePin(pin);
    final canonical = canonicalActuatorType(type);
    if (canonical == 'SERVO') {
      validateValeurServo(valeur);
      if (rfidCible == null || rfidCible.trim().isEmpty) {
        throw ArgumentError(
          'rfid_cible obligatoire pour SERVO (id du lecteur RFID lié).',
        );
      }
    } else {
      validateValeurActionneur(valeur);
    }
    return {
      fieldActuatorId: appareilId,
      fieldType: canonical,
      fieldCategorie: 'actionneur',
      fieldLabel: label.trim(),
      fieldValeur: valeur,
      fieldUnit: unitForActuatorType(canonical),
      fieldPin: pin,
      fieldPiece: piece.trim(),
      fieldUserId: userId,
      fieldLastChanged: FieldValue.serverTimestamp(),
      if (changedBy != null && changedBy.isNotEmpty)
        fieldChangedBy: changedBy,
      if (canonical == 'SERVO')
        fieldRfidCible: rfidCible!.trim(),
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

  static void validateValeurServo(int valeur) {
    if (valeur < minServoAngle || valeur > maxServoAngle) {
      throw ArgumentError(
        'valeur servo : $minServoAngle–$maxServoAngle (angle en degrés)',
      );
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
    if (patch.containsKey('angle') || patch.containsKey('servoAngle')) {
      final raw = patch['angle'] ?? patch['servoAngle'];
      final i = raw is int ? raw : (raw is num ? raw.toInt() : null);
      if (i == null) throw ArgumentError('angle servo invalide');
      validateValeurServo(i);
      return {
        fieldValeur: i,
        fieldLastChanged: FieldValue.serverTimestamp(),
        if (changedBy != null && changedBy.isNotEmpty)
          fieldChangedBy: changedBy,
      };
    }
    if (patch.containsKey(fieldValeur)) {
      final v = patch[fieldValeur];
      if (cat == 'actionneur') {
        final i = v is int ? v : (v is num ? v.toInt() : null);
        if (i == null) throw ArgumentError('valeur actionneur invalide');
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
      data.containsKey(fieldPiece) &&
      (data.containsKey(fieldValeur) ||
          data.containsKey(fieldTemperature) ||
          data.containsKey(fieldHumidity) ||
          data.containsKey(fieldSensorId) ||
          data.containsKey(fieldActuatorId));

  static String displayLabel(Map<String, dynamic> data, String id) {
    final label = (data[fieldLabel] as String?)?.trim();
    if (label != null && label.isNotEmpty) return label;
    return _labelFromId(id);
  }

  static String _labelFromId(String id) {
    final lower = id.toLowerCase();
    if (lower.startsWith('dht22') || lower == 'dht_salon') return 'Capteur DHT';
    if (lower.startsWith('dht_temp')) return 'Température';
    if (lower.startsWith('dht_hum')) return 'Humidité';
    if (lower.startsWith('pir')) return 'Détecteur mouvement';
    if (lower.contains('rfid')) return 'Lecteur RFID';
    if (lower.contains('servo') || lower.contains('porte')) return 'Servo porte';
    if (lower.startsWith('lampe')) return 'Lampe';
    if (lower.startsWith('moteur')) return 'Moteur';
    if (lower.startsWith('buzzer')) return 'Alarme';
    return id;
  }

  static String typeFromData(Map<String, dynamic> data, String id) {
    final t = (data[fieldType] as String?)?.trim();
    if (t != null && t.isNotEmpty) return t.toUpperCase();
    final lower = id.toLowerCase();
    if (lower.startsWith('dht22') || lower == 'dht_salon') return 'DHT22';
    if (lower.startsWith('dht_temp')) return 'DHT_TEMP';
    if (lower.startsWith('dht_hum')) return 'DHT_HUM';
    if (lower.startsWith('pir')) return 'PIR';
    if (lower.contains('rfid')) return 'RFID';
    if (lower.contains('servo') || lower.contains('porte')) return 'SERVO';
    if (lower.startsWith('led')) return 'LED';
    return 'RELAIS';
  }

  static String categorieFromData(Map<String, dynamic> data, String id) {
    final c = data[fieldCategorie] as String?;
    if (c != null && c.isNotEmpty) return c.trim();
    if (data.containsKey(fieldSensorId)) return 'capteur';
    if (data.containsKey(fieldActuatorId)) return 'actionneur';
    final ty = typeFromData(data, id);
    if (isSensorType(ty)) return 'capteur';
    return 'actionneur';
  }
}
