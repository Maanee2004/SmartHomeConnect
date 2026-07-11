import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/home_dashboard_stats.dart';

void main() {
  group('HomeDashboardStats', () {
    test('compte allumés et watts', () {
      final devices = [
        const Device(
          id: 'l1',
          name: 'Lampe',
          roomId: 'salon',
          type: 'LAMPE',
          state: {'valeur': '1'},
          isOnline: true,
        ),
        const Device(
          id: 'r1',
          name: 'Relais',
          roomId: 'salon',
          type: 'RELAIS',
          state: {'valeur': '0'},
          isOnline: true,
        ),
        const Device(
          id: 'dht',
          name: 'DHT',
          roomId: 'salon',
          type: 'DHT',
          state: {},
          categorie: 'capteur',
          isOnline: false,
        ),
      ];

      final stats = HomeDashboardStats.fromDevices(devices);
      expect(stats.total, 3);
      expect(stats.onCount, 1);
      expect(stats.instantWatts, 60);
      expect(stats.sensorCount, 1);
      expect(stats.actuatorCount, 2);
    });
  });
}
