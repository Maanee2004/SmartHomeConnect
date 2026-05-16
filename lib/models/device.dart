/// Appareil domotique (contrat backend : `type`, `state` flexible, `roomId`).
class Device {
  const Device({
    required this.id,
    required this.name,
    required this.roomId,
    required this.type,
    required this.state,
    this.isOnline = true,
  });

  final String id;
  final String name;
  final String roomId;

  /// Valeurs attendues : `LIGHT`, `SENSOR_TEMP`, `FAN`, etc. (normalisé en majuscules).
  final String type;
  final Map<String, dynamic> state;
  final bool isOnline;

  /// Type normalisé pour les `switch` UI.
  String get normalizedType {
    final u = type.toUpperCase().trim();
    if (u == 'LAMP' || u == 'LAMPE' || u == 'LIGHT' || u == 'LIGHTBULB') {
      return 'LIGHT';
    }
    if (u == 'FAN' || u == 'VENTILATEUR') return 'FAN';
    if (u == 'SENSOR_TEMP' || u == 'TEMPERATURE' || u == 'TEMP') {
      return 'SENSOR_TEMP';
    }
    if (u == 'SENSOR_HUMID' ||
        u == 'HUMIDITY' ||
        u == 'HUM' ||
        u == 'HYGRO') {
      return 'SENSOR_TEMP';
    }
    if (u == 'CAMERA' || u == 'CAMÉRA' || u == 'CAM') {
      return 'CAMERA';
    }
    if (u == 'OUTLET' || u == 'PRISE' || u == 'SOCKET') {
      return 'OUTLET';
    }
    return u.isEmpty ? 'LIGHT' : u;
  }

  bool get isOn {
    final v = state['isOn'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    return false;
  }

  double? get temperatureCelsius {
    final v = state['temperature'] ?? state['value'] ?? state['temp'];
    if (v is num) return v.toDouble();
    return null;
  }

  /// Humidité relative (0–100), clés usuelles : `humidity`, `rh`, `humid`.
  double? get humidityPercent {
    final v = state['humidity'] ??
        state['humidityRh'] ??
        state['rh'] ??
        state['humid'] ??
        state['humidityPercent'];
    if (v is num) return v.toDouble().clamp(0, 100);
    return null;
  }

  int get fanSpeed {
    final v = state['speed'] ?? state['fanSpeed'];
    if (v is int) return v.clamp(0, 3);
    if (v is num) return v.toInt().clamp(0, 3);
    return 0;
  }

  /// Capteurs ne comptent pas comme « appareil allumé » pour les résumés.
  bool get isActuatorOn {
    final t = normalizedType;
    if (t == 'SENSOR_TEMP') return false;
    return isOn;
  }

  static Map<String, dynamic> _stateFromFirestore(Map<String, dynamic> data) {
    final raw = data['state'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is bool) {
      return {'isOn': raw};
    }
    return {'isOn': false};
  }

  factory Device.fromFirestore(String id, Map<String, dynamic> data) {
    final nameRaw = (data['name'] as String?)?.trim();
    final typeRaw = (data['type'] as String?)?.trim();
    final status = data['status'] as String?;
    final explicitOnline = data['online'] as bool?;
    final online = explicitOnline ??
        (status == null || status != 'offline');

    return Device(
      id: id,
      name: (nameRaw == null || nameRaw.isEmpty) ? 'Appareil' : nameRaw,
      roomId: (data['roomId'] as String?)?.trim() ?? '',
      type: (typeRaw == null || typeRaw.isEmpty) ? 'LIGHT' : typeRaw,
      state: _stateFromFirestore(data),
      isOnline: online,
    );
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    final nameRaw = (json['name'] as String?)?.trim();
    final typeRaw = (json['type'] as String?)?.trim();
    final stateRaw = json['state'];
    Map<String, dynamic> st;
    if (stateRaw is Map) {
      st = Map<String, dynamic>.from(stateRaw);
    } else if (stateRaw is bool) {
      st = {'isOn': stateRaw};
    } else {
      st = {'isOn': false};
    }
    return Device(
      id: json['id'] as String,
      name: (nameRaw == null || nameRaw.isEmpty) ? 'Appareil' : nameRaw,
      roomId: (json['roomId'] as String?)?.trim() ?? '',
      type: (typeRaw == null || typeRaw.isEmpty) ? 'LIGHT' : typeRaw,
      state: st,
      isOnline: (json['online'] as bool?) ??
          ((json['status'] as String?) != 'offline'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'roomId': roomId,
        'type': type,
        'state': state,
        'online': isOnline,
      };
}
