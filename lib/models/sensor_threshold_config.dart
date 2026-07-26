/// Seuil d’alerte pour un type de capteur (DHT, ULTRA…).
class SensorThresholdConfig {
  const SensorThresholdConfig({
    this.enabled = false,
    this.alertAbove = true,
    this.threshold = 35,
  });

  final bool enabled;

  /// `true` = alerte si valeur **au-dessus** du seuil ; `false` = en dessous.
  final bool alertAbove;
  final double threshold;

  static const defaultsByType = <String, SensorThresholdConfig>{
    'DHT': SensorThresholdConfig(
      enabled: true,
      alertAbove: true,
      threshold: 35,
    ),
    'ULTRA': SensorThresholdConfig(
      enabled: false,
      alertAbove: false,
      threshold: 30,
    ),
    'RFID': SensorThresholdConfig(enabled: true, alertAbove: true, threshold: 0),
  };

  SensorThresholdConfig copyWith({
    bool? enabled,
    bool? alertAbove,
    double? threshold,
  }) =>
      SensorThresholdConfig(
        enabled: enabled ?? this.enabled,
        alertAbove: alertAbove ?? this.alertAbove,
        threshold: threshold ?? this.threshold,
      );

  Map<String, dynamic> toFirestore() => {
        'enabled': enabled,
        'alertAbove': alertAbove,
        'threshold': threshold,
      };

  factory SensorThresholdConfig.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) {
      return const SensorThresholdConfig();
    }
    final raw = data['threshold'];
    final threshold = raw is num ? raw.toDouble() : 35.0;
    return SensorThresholdConfig(
      enabled: data['enabled'] as bool? ?? false,
      alertAbove: data['alertAbove'] as bool? ?? true,
      threshold: threshold,
    );
  }

  static SensorThresholdConfig forType(String type) {
    final key = type.trim().toUpperCase();
    return defaultsByType[key] ?? const SensorThresholdConfig();
  }

  bool triggers(num value) {
    if (!enabled) return false;
    return alertAbove ? value > threshold : value < threshold;
  }
}
