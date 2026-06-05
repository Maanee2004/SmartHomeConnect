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
    this.isCanonical = false,
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
  final bool isCanonical;

  bool get isActionneur => categorie == 'actionneur';
  bool get isCapteur => categorie == 'capteur';

  /// Actionneur ou type legacy nécessitant une broche GPIO.
  bool get expectsPin =>
      isActionneur || AppareilSpec.requiresPin(type);

  String get normalizedType {
    final u = type.toUpperCase().trim();
    if (u == 'DHT_TEMP' || u == 'DHT22') return 'DHT_TEMP';
    if (u == 'DHT_HUM') return 'DHT_HUM';
    if (u == 'PIR') return 'PIR';
    if (u == 'RELAIS' || u == 'RELAIS') return 'RELAIS';
    if (u == 'LIGHT' || u == 'LAMPE') return 'LIGHT';
    return u.isEmpty ? 'RELAIS' : u;
  }

  bool get isOn {
    if (isCanonical && isActionneur) return valeur == 1;
    final v = state['isOn'] ?? valeur;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return false;
  }

  double? get temperatureCelsius {
    if (isCanonical &&
        (id.toLowerCase().contains('dht_temp') ||
            normalizedType == 'DHT_TEMP') &&
        valeur is num) {
      return valeur!.toDouble();
    }
    final v = state['temperature'] ?? state['value'];
    if (v is num) return v.toDouble();
    return null;
  }

  double? get humidityPercent {
    if (isCanonical &&
        (id.toLowerCase().contains('dht_hum') ||
            normalizedType == 'DHT_HUM') &&
        valeur is num) {
      return valeur!.toDouble().clamp(0, 100);
    }
    final v = state['humidity'] ?? state['rh'];
    if (v is num) return v.toDouble().clamp(0, 100);
    return null;
  }

  int get fanSpeed {
    final v = state['speed'] ?? state['fanSpeed'];
    if (v is num) return v.toInt();
    return 0;
  }

  bool get isActuatorOn {
    if (isCanonical && isCapteur) return false;
    if (normalizedType == 'DHT_TEMP' ||
        normalizedType == 'DHT_HUM' ||
        normalizedType == 'PIR' ||
        normalizedType == 'ULTRASON' ||
        normalizedType == 'RFID') {
      return false;
    }
    return isOn;
  }

  static Map<String, dynamic> _legacyState(Map<String, dynamic> data) {
    final raw = data['state'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is bool) return {'isOn': raw};
    return {'isOn': false};
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
      if (val is num) valeur = val;
      int? pin;
      final pinRaw = data[AppareilSpec.fieldPin];
      if (pinRaw is num) pin = pinRaw.toInt();

      return Device(
        id: id,
        name: AppareilSpec.displayLabel(data, id),
        roomId: pieceRaw.isEmpty ? '' : _slugFromPiece(pieceRaw),
        piece: pieceRaw.isEmpty ? null : pieceRaw,
        type: ty,
        state: {'valeur': valeur ?? 0},
        isOnline: online,
        categorie: cat,
        pin: pin,
        valeur: valeur,
        unit: data[AppareilSpec.fieldUnit] as String?,
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
