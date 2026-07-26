import 'package:smart_home/models/appareil_spec.dart';

class Device {
  const Device({
    required this.id,
    required this.name,
    required this.roomId,
    required this.type,
    required this.state,
    this.isOnline = true,
    this.categorie,
    this.pin,
    this.valeur,
    this.piece,
    this.unit,
    this.temperature,
    this.humidity,
    this.isCanonical = false,
    this.isMergedDhtPair = false,
    this.humDocId,
    this.rfidCible,
  });

  final String id;
  final String name;
  final String roomId;
  final String type;
  final Map<String, dynamic> state;
  final bool isOnline;
  final String? categorie;
  final int? pin;
  final num? valeur;
  final String? piece;
  final String? unit;
  final double? temperature;
  final double? humidity;
  final bool isCanonical;

  /// Carte UI fusionnant dht_temp_* + dht_hum_* (même capteur physique).
  final bool isMergedDhtPair;

  /// Id Firestore du doc DHT_HUM associé (suppression paire).
  final String? humDocId;

  /// Lecteur RFID lié (champ `rfid_cible` sur un SERVO).
  final String? rfidCible;

  bool get isCapteur =>
      categorie == 'capteur' || AppareilSpec.isSensorType(type);

  bool get isActionneur => !isCapteur && categorie != 'capteur';

  bool get expectsPin => isActionneur && pin == null;

  bool get isDhtCombined =>
      isMergedDhtPair ||
      normalizedType == 'DHT' ||
      normalizedType == 'DHT22' ||
      normalizedType == 'DHT_TEMP';

  bool get isDhtDisplay => isDhtCombined;

  /// Type UI — aligné sur les codes Firestore / Arduino.
  String get normalizedType {
    if (isMergedDhtPair) return 'DHT_PAIR';
    final u = type.toUpperCase().trim();
    if (AppareilSpec.isDhtType(u)) {
      return u == 'DHT_HUM' ? 'DHT_HUM' : 'DHT';
    }
    if (u == 'PIR') return 'PIR';
    if (u == 'RFID') return 'RFID';
    if (u == 'ULTRA') return 'ULTRA';
    if (u == 'SERVO') return 'SERVO';
    if (u == 'MAX') return 'MAX';
    if (u == 'LAMPE' || u == 'LIGHT') return 'LAMPE';
    if (u == 'MOTEUR' || u == 'MOTOR') return 'MOTEUR';
    if (u == 'LED') return 'LED';
    if (u == 'RELAIS' || u == 'FAN' || u == 'OUTLET' || u == 'CAMERA') {
      return 'RELAIS';
    }
    return u.isEmpty ? 'RELAIS' : u;
  }

  static bool _truthy(Object? raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final t = raw.trim().toLowerCase();
      return t == '1' || t == 'true' || t == 'on';
    }
    return false;
  }

  bool get isOn {
    if (isCanonical && isActionneur) {
      return _truthy(state['valeur'] ?? valeur);
    }
    final v = state['isOn'] ?? state['valeur'] ?? valeur;
    return _truthy(v);
  }

  double? get temperatureCelsius {
    if (temperature != null) return temperature;
    if (normalizedType == 'DHT_HUM') return null;
    if (normalizedType == 'DHT' ||
        normalizedType == 'DHT_TEMP' ||
        normalizedType == 'DHT22' ||
        isDhtCombined) {
      for (final raw in [valeur, state['valeur']]) {
        final fromValeur = _dhtFromValeur(raw);
        if (fromValeur.$1 != null) return fromValeur.$1;
      }
    }
    final v = state['temperature'] ?? state['value'];
    return _readDouble(v);
  }

  double? get humidityPercent {
    if (humidity != null) return humidity!.clamp(0, 100);
    if (normalizedType == 'DHT_HUM' ||
        normalizedType == 'DHT22' ||
        normalizedType == 'DHT_TEMP' ||
        isDhtCombined) {
      for (final raw in [valeur, state['valeur']]) {
        final fromValeur = _dhtFromValeur(raw);
        if (fromValeur.$2 != null) return fromValeur.$2!.clamp(0, 100);
      }
      if (normalizedType == 'DHT_HUM' && valeur != null) {
        final v = _readDouble(valeur);
        if (v != null) return v.clamp(0, 100);
      }
    }
    final v = state['humidity'] ?? state['rh'];
    final parsed = _readDouble(v);
    return parsed?.clamp(0, 100);
  }

  double? get distanceCm {
    if (normalizedType != 'ULTRA') return null;
    final raw = state['valeur'] ?? valeur;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim().replaceAll(',', '.'));
    return null;
  }

  String? get rfidBadgeUid {
    if (normalizedType != 'RFID') return null;
    final raw = state['valeur'] ?? valeur;
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty || s == '0' ? null : s;
  }

  int get fanSpeed {
    final v = state['speed'] ?? state['fanSpeed'];
    if (v is num) return v.toInt();
    return 0;
  }

  bool get isActuatorOn {
    if (isCanonical && isCapteur) return false;
    if (isMergedDhtPair ||
        normalizedType == 'DHT_PAIR' ||
        normalizedType == 'DHT' ||
        normalizedType == 'DHT22' ||
        normalizedType == 'DHT_TEMP' ||
        normalizedType == 'DHT_HUM' ||
        normalizedType == 'PIR' ||
        normalizedType == 'RFID' ||
        normalizedType == 'ULTRA') {
      return false;
    }
    return isOn;
  }

  /// État actionneur pour affichage optimiste (avant retour Firestore).
  Device withActuatorOn(bool on) {
    final valStr = on ? '1' : '0';
    return Device(
      id: id,
      name: name,
      roomId: roomId,
      type: type,
      state: {
        ...state,
        'valeur': valStr,
        'isOn': on,
      },
      isOnline: isOnline,
      categorie: categorie,
      pin: pin,
      valeur: on ? 1 : 0,
      piece: piece,
      unit: unit,
      temperature: temperature,
      humidity: humidity,
      isCanonical: isCanonical,
      isMergedDhtPair: isMergedDhtPair,
      humDocId: humDocId,
      rfidCible: rfidCible,
    );
  }

  static Map<String, dynamic> _legacyState(Map<String, dynamic> data) {
    final raw = data['state'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is bool) return {'isOn': raw};
    return {'isOn': false};
  }

  static double? _readDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw.trim().replaceAll(',', '.'));
    return null;
  }

  /// Extrait température / humidité depuis [valeur] (nombre, map ou « 24.5,60 »).
  static (double?, double?) _dhtFromValeur(Object? raw) {
    if (raw == null) return (null, null);
    if (raw is num) return (raw.toDouble(), null);
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      return (
        _readDouble(
          m['temperature'] ?? m['temp'] ?? m['t'] ?? m['DHT_TEMP'],
        ),
        _readDouble(m['humidity'] ?? m['hum'] ?? m['h'] ?? m['DHT_HUM']),
      );
    }
    if (raw is String) {
      final s = raw.trim();
      final parts = s.split(RegExp(r'[,;/|]'));
      if (parts.length >= 2) {
        return (
          _readDouble(parts[0]),
          _readDouble(parts[1]),
        );
      }
      final single = _readDouble(s);
      if (single != null) return (single, null);
    }
    return (null, null);
  }

  static ({double? temp, double? hum}) _parseDhtFields(
    Map<String, dynamic> data,
    String id,
  ) {
    var temp = _readDouble(data[AppareilSpec.fieldTemperature]);
    var hum = _readDouble(
      data[AppareilSpec.fieldHumidity] ?? data['humidite'],
    );
    final fromValeur = _dhtFromValeur(data[AppareilSpec.fieldValeur]);
    temp ??= fromValeur.$1;
    hum ??= fromValeur.$2;

    final ty = AppareilSpec.typeFromData(data, id);
    if (ty == 'DHT_TEMP' && temp == null) {
      temp = _readDouble(data[AppareilSpec.fieldValeur]);
    }
    if (ty == 'DHT_HUM' && hum == null) {
      hum = _readDouble(data[AppareilSpec.fieldValeur]);
    }
    return (temp: temp, hum: hum);
  }

  static String? dhtSlugFromId(String id) {
    final m = RegExp(r'^dht_(?:temp|hum)_(.+)$', caseSensitive: false)
        .firstMatch(id.trim());
    return m?.group(1)?.toLowerCase();
  }

  /// Fusionne DHT_TEMP + DHT_HUM (même capteur : id dht_temp_x + dht_hum_x).
  static Device? mergeDhtPair(Device temp, Device hum) {
    if (temp.normalizedType != 'DHT_TEMP' || hum.normalizedType != 'DHT_HUM') {
      return null;
    }

    final tempSlug = dhtSlugFromId(temp.id);
    final humSlug = dhtSlugFromId(hum.id);
    final slugMatch =
        tempSlug != null && humSlug != null && tempSlug == humSlug;
    final pinMatch = temp.pin != null && temp.pin == hum.pin;
    final pieceMatch = (temp.piece ?? '').trim().toLowerCase() ==
        (hum.piece ?? '').trim().toLowerCase();

    if (!slugMatch && !(pinMatch && pieceMatch)) return null;

    final pieceLabel = (temp.piece ?? hum.piece ?? tempSlug ?? '').trim();

    return Device(
      id: temp.id,
      name: pieceLabel.isEmpty ? 'Capteur DHT' : 'Capteur DHT — $pieceLabel',
      roomId: temp.roomId,
      piece: temp.piece ?? hum.piece,
      type: 'DHT_TEMP',
      state: {...temp.state, ...hum.state},
      isOnline: temp.isOnline && hum.isOnline,
      categorie: 'capteur',
      pin: temp.pin ?? hum.pin,
      valeur: temp.valeur,
      unit: '°C/%',
      temperature: temp.temperatureCelsius,
      humidity: hum.humidityPercent,
      isCanonical: true,
      isMergedDhtPair: true,
      humDocId: hum.id,
    );
  }

  static String _slugFromPiece(String piece) =>
      piece.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  factory Device.fromFirestore(String id, Map<String, dynamic> data) {
    final status = data['status'] as String?;
    final online =
        (data['online'] as bool?) ?? (status == null || status != 'offline');

    if (AppareilSpec.isAppareilDocument(data)) {
      final pieceRaw = (data[AppareilSpec.fieldPiece] as String?)?.trim() ?? '';
      final cat = AppareilSpec.categorieFromData(data, id);
      final ty = AppareilSpec.typeFromData(data, id);
      final val = data[AppareilSpec.fieldValeur];
      num? valeur;
      if (val is num) {
        valeur = val;
      } else if (val is String) {
        final pair = _dhtFromValeur(val);
        valeur = pair.$1 ??
            num.tryParse(val.trim().replaceAll(',', '.')) ??
            (val.trim() == '1'
                ? 1
                : val.trim() == '0'
                    ? 0
                    : null);
      }
      int? pin;
      final pinRaw = data[AppareilSpec.fieldPin];
      if (pinRaw is num) pin = pinRaw.toInt();

      final dht = _parseDhtFields(data, id);
      final temp = dht.temp;
      final hum = dht.hum;
      final rfidLink = (data[AppareilSpec.fieldRfidCible] as String?)?.trim();

      return Device(
        id: id,
        name: AppareilSpec.displayLabel(data, id),
        roomId: pieceRaw.isEmpty ? '' : _slugFromPiece(pieceRaw),
        piece: pieceRaw.isEmpty ? null : pieceRaw,
        type: ty,
        state: {
          if (val != null) 'valeur': val,
          if (temp != null) 'temperature': temp,
          if (hum != null) 'humidity': hum,
          if (rfidLink != null && rfidLink.isNotEmpty)
            AppareilSpec.fieldRfidCible: rfidLink,
        },
        isOnline: online,
        categorie: cat,
        pin: pin,
        valeur: valeur,
        unit: data[AppareilSpec.fieldUnit] as String?,
        temperature: temp,
        humidity: hum,
        rfidCible: rfidLink,
        isCanonical: true,
      );
    }

    final nameRaw =
        (data['nom'] as String?)?.trim() ?? (data['name'] as String?)?.trim();
    final pieceLegacy = (data['piece'] as String?)?.trim();
    final roomRaw = pieceLegacy ??
        (data['piece_id'] as String?)?.trim() ??
        (data['roomId'] as String?)?.trim();

    return Device(
      id: id,
      name: (nameRaw == null || nameRaw.isEmpty)
          ? AppareilSpec.displayLabel(data, id)
          : nameRaw,
      roomId: roomRaw ?? '',
      piece: pieceLegacy,
      type: (data['type'] as String?)?.trim() ?? 'LIGHT',
      state: _legacyState(data),
      isOnline: online,
    );
  }
}
