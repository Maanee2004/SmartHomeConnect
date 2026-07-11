import 'package:smart_home/models/device.dart';

/// Statistiques agrégées pour le tableau de bord maison.
class HomeDashboardStats {
  const HomeDashboardStats({
    required this.total,
    required this.onCount,
    required this.instantWatts,
    required this.sensorCount,
    required this.actuatorCount,
  });

  final int total;
  final int onCount;
  final double instantWatts;
  final int sensorCount;
  final int actuatorCount;

  /// Puissance nominale estimée (W) par type d'actionneur allumé.
  static double _nominalWatts(Device d) {
    switch (d.normalizedType) {
      case 'LAMPE':
        return 60;
      case 'MOTEUR':
        return 120;
      case 'LED':
        return 5;
      case 'SERVO':
        return 15;
      case 'MAX':
        return 20;
      case 'RELAIS':
      default:
        return 40;
    }
  }

  factory HomeDashboardStats.fromDevices(List<Device> devices) {
    var on = 0;
    var sensors = 0;
    var actuators = 0;
    var watts = 0.0;

    for (final d in devices) {
      if (d.isCapteur) {
        sensors++;
      } else {
        actuators++;
        if (d.isOn) {
          on++;
          watts += _nominalWatts(d);
        }
      }
    }

    return HomeDashboardStats(
      total: devices.length,
      onCount: on,
      instantWatts: watts,
      sensorCount: sensors,
      actuatorCount: actuators,
    );
  }

  String get wattsLabel {
    if (instantWatts >= 1000) {
      return '${(instantWatts / 1000).toStringAsFixed(2)} kW';
    }
    return '${instantWatts.toStringAsFixed(0)} W';
  }
}
