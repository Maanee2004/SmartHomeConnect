import 'package:cloud_firestore/cloud_firestore.dart';

/// Schéma académique — `maisons/{userId}/appareils` (capteurs + actionneurs).
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

  /// UART / SPI / boot ESP32 — non assignables via l’app.
  static const reservedPins = <int>{2, 3, 9, 11, 12, 13};

  /// Rôles matériels (affichage admin / guide technique).
  static const reservedPinRoles = <int, String>{
    2: 'TX',
    3: 'RX',
    9: 'RST / flash',
    11: 'MOSI',
    12: 'MISO',
    13: 'SCK',
  };

  static bool isPinSelectable(int pin) =>
      pin >= minPin && pin <= maxPin && !reservedPins.contains(pin);

  static String get reservedPinsListText {
    final sorted = reservedPins.toList()..sort();
    return sorted.join(', ');
  }

  /// Libellé court pour une broche réservée.
  static String reservedPinLabel(int pin, {bool technical = false}) {
    if (!reservedPins.contains(pin)) return '';
    if (technical) {
      final role = reservedPinRoles[pin];
      if (role != null) return role;
    }
    return 'ESP32';
  }

  static const unitBooleen = 'booleen';
  static const unitUid = 'uid';
  static const unitCm = 'cm';
  static const unitCelsiusPercent = 'celsius/%';

  /// Types capteurs Arduino (`CONFIG:` / lecture).
  static const arduinoSensorTypes = {
    'DHT',
    'DHT22',
    'DHT_TEMP',
    'DHT_HUM',
    'PIR',
    'RFID',
    'ULTRA',
  };

  /// Types actionneurs Arduino.
  static const arduinoActuatorTypes = {
    'RELAIS',
    'LAMPE',
    'MOTEUR',
    'LED',
    'SERVO',
    'MAX',
  };

  static const uiSensorTypes = <String, String>{
    'DHT': 'Température / humidité (DHT)',
    'PIR': 'Mouvement (PIR)',
    'RFID': 'Lecteur RFID (UID badge)',
    'ULTRA': 'Distance ultrason (HC-SR04)',
  };

  static const uiActuatorTypes = <String, String>{
    'RELAIS': 'Relais ON/OFF',
    'LAMPE': 'Lampe',
    'SERVO': 'Servomoteur porte (SERVO)',
    'MAX': 'Matrice LED (MAX7219)',
  };

  static String formatDhtValeur(num temperature, num humidity) =>
      '${temperature.toStringAsFixed(1)}/${humidity.toStringAsFixed(1)}';

  static bool isSensorType(String type) {
    final t = type.toUpperCase().trim();
    return t == 'DHT' ||
        t == 'DHT22' ||
        t == 'DHT_TEMP' ||
        t == 'DHT_HUM' ||
        t == 'PIR' ||
        t == 'RFID' ||
        t == 'ULTRA' ||
        t == 'SENSOR_TEMP' ||
        t == 'HUMIDITY';
  }

  static bool isDhtType(String type) {
    final t = type.toUpperCase().trim();
    return t == 'DHT' ||
        t == 'DHT22' ||
        t == 'DHT_TEMP' ||
        t == 'DHT_HUM' ||
        t == 'SENSOR_TEMP' ||
        t == 'TEMPERATURE' ||
        t == 'TEMP';
  }

  /// Type Firestore canonique pour un **nouveau** capteur.
  static String canonicalSensorType(String raw) {
    switch (raw.toUpperCase().trim()) {
      case 'DHT':
      case 'DHT22':
      case 'SENSOR_TEMP':
      case 'TEMPERATURE':
      case 'DHT_TEMP':
      case 'TEMP':
        return 'DHT';
      case 'DHT_HUM':
      case 'HUMIDITY':
        return 'DHT_HUM';
      case 'PIR':
        return 'PIR';
      case 'RFID':
        return 'RFID';
      case 'ULTRA':
      case 'ULTRASON':
      case 'HC-SR04':
        return 'ULTRA';
      default:
        throw ArgumentError(
          'Type capteur non supporté: « $raw ». '
          'Utilisez DHT, PIR, RFID ou ULTRA.',
        );
    }
  }

  static bool isDhtCombinedType(String type) => isDhtType(type);

  static String canonicalActuatorType(String raw) {
    switch (raw.toUpperCase().trim()) {
      case 'RELAIS':
      case 'OUTLET':
      case 'PRISE':
      case 'FAN':
      case 'VENTILATEUR':
        return 'RELAIS';
      case 'LAMPE':
      case 'LIGHT':
        return 'LAMPE';
      case 'MOTEUR':
      case 'MOTOR':
        return 'MOTEUR';
      case 'LED':
        return 'LED';
      case 'SERVO':
      case 'SERVO_MOTEUR':
      case 'PORTE':
        return 'SERVO';
      case 'MAX':
      case 'MAX7219':
      case 'MATRICE':
        return 'MAX';
      default:
        throw ArgumentError(
          'Type actionneur non supporté: « $raw ». '
          'Utilisez RELAIS, LAMPE, SERVO ou MAX.',
        );
    }
  }

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
      case 'DHT':
      case 'DHT22':
      case 'DHT_TEMP':
        return unitCelsiusPercent;
      case 'DHT_HUM':
        return '%';
      case 'PIR':
        return unitBooleen;
      case 'RFID':
        return unitUid;
      case 'ULTRA':
        return unitCm;
      default:
        return '';
    }
  }

  static String unitForActuatorType(String canonicalType) => unitBooleen;

  static Object _normalizeValeur(Object raw) {
    if (raw is String) return raw.trim();
    if (raw is num) return raw == 0 || raw == 1 ? '${raw.toInt()}' : raw;
    return raw;
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
    final isDht = isDhtType(canonical);
    Object resolvedValeur = _normalizeValeur(valeur);
    if (isDht && temperature is num && humidity is num) {
      resolvedValeur = formatDhtValeur(temperature, humidity);
    }
    return {
      fieldSensorId: appareilId,
      fieldType: canonical == 'DHT_HUM' ? 'DHT_HUM' : canonical,
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
    Object valeur = '0',
    required String userId,
    String? changedBy,
    String? rfidCible,
  }) {
    validatePiece(piece);
    validatePin(pin);
    final canonical = canonicalActuatorType(type);
    final v = _actuatorValeurString(valeur);
    validateValeurActionneur(v);
    return {
      fieldActuatorId: appareilId,
      fieldType: canonical,
      fieldCategorie: 'actionneur',
      fieldLabel: label.trim(),
      fieldValeur: v,
      fieldUnit: unitForActuatorType(canonical),
      fieldPin: pin,
      fieldPiece: piece.trim(),
      fieldUserId: userId,
      fieldLastChanged: FieldValue.serverTimestamp(),
      if (changedBy != null && changedBy.isNotEmpty) fieldChangedBy: changedBy,
      if (canonical == 'SERVO') fieldRfidCible: (rfidCible ?? '').trim(),
    };
  }

  static String _actuatorValeurString(Object raw) {
    if (raw is String) {
      final t = raw.trim();
      if (t == '0' || t == '1') return t;
      final n = int.tryParse(t);
      if (n == 0 || n == 1) return '$n';
    }
    if (raw is num) return raw == 0 ? '0' : '1';
    if (raw is bool) return raw ? '1' : '0';
    return '0';
  }

  static void validatePiece(String piece) {
    if (piece.trim().isEmpty) {
      throw ArgumentError('piece requis (ex: Salon, garage)');
    }
  }

  static void validatePin(int pin) {
    if (pin < minPin || pin > maxPin) {
      throw ArgumentError('pin hors plage ($minPin–$maxPin) : $pin');
    }
    if (reservedPins.contains(pin)) {
      throw ArgumentError(
        'Broche $pin réservée (module ESP32 : UART/SPI, TX, RX, MOSI, RST…). '
        'Broches utilisables : voir la liste « Broches libres ».',
      );
    }
  }

  /// ULTRA (HC-SR04) : Trigger = [pin], Echo = pin + 1.
  static void validatePinForDeviceType(int pin, String deviceType) {
    validatePin(pin);
    if (deviceType.trim().toUpperCase() == 'ULTRA') {
      validatePin(pin + 1);
    }
  }

  static void validateValeurActionneur(Object valeur) {
    final v = _actuatorValeurString(valeur);
    if (v != '0' && v != '1') {
      throw ArgumentError('valeur actionneur : "0" ou "1"');
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
        fieldValeur: on ? '1' : '0',
        fieldLastChanged: FieldValue.serverTimestamp(),
        if (changedBy != null && changedBy.isNotEmpty)
          fieldChangedBy: changedBy,
      };
    }
    if (patch.containsKey(fieldValeur)) {
      final v = patch[fieldValeur];
      if (cat == 'actionneur') {
        return {
          fieldValeur: _actuatorValeurString(v ?? '0'),
          fieldLastChanged: FieldValue.serverTimestamp(),
          if (changedBy != null && changedBy.isNotEmpty)
            fieldChangedBy: changedBy,
        };
      }
      return {
        fieldValeur: v is num ? v : (v?.toString() ?? '0'),
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
    if (lower.startsWith('dht') || lower.contains('temp')) {
      return 'Capteur Température/Humidité';
    }
    if (lower.startsWith('pir')) return 'Détecteur PIR';
    if (lower.contains('rfid')) return 'Lecteur Badge RFID';
    if (lower.contains('ultra')) return 'Capteur de Distance';
    if (lower.contains('servo') || lower.contains('porte')) {
      return 'Servomoteur Portail';
    }
    if (lower.contains('matrice') || lower.contains('max')) {
      return 'Matrice LED';
    }
    if (lower.startsWith('lampe')) return 'Lampe';
    if (lower.startsWith('moteur')) return 'Moteur';
    if (lower.startsWith('relais')) return 'Relais';
    return id;
  }

  static String typeFromData(Map<String, dynamic> data, String id) {
    final t = (data[fieldType] as String?)?.trim();
    if (t != null && t.isNotEmpty) return t.toUpperCase();
    final lower = id.toLowerCase();
    if (lower.startsWith('dht') || lower.contains('temp')) return 'DHT';
    if (lower.startsWith('pir')) return 'PIR';
    if (lower.contains('rfid')) return 'RFID';
    if (lower.contains('ultra')) return 'ULTRA';
    if (lower.contains('servo') || lower.contains('porte')) return 'SERVO';
    if (lower.contains('matrice') || lower.contains('max')) return 'MAX';
    if (lower.startsWith('lampe')) return 'LAMPE';
    if (lower.startsWith('moteur')) return 'MOTEUR';
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
