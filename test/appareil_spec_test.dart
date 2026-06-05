import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home/models/appareil_spec.dart';
import 'package:smart_home/models/device.dart';

void main() {
  group('AppareilSpec payloads', () {
    test('actionneur avec piece et label', () {
      final p = AppareilSpec.actuatorPayload(
        appareilId: 'lampe_salon',
        piece: 'Salon',
        type: 'RELAIS',
        label: 'Éclairage Principal',
        pin: 2,
        valeur: 1,
        userId: 'usr_test',
      );
      expect(p['actuatorId'], 'lampe_salon');
      expect(p['piece'], 'Salon');
      expect(p['pin'], 2);
      expect(p['valeur'], 1);
      expect(p['categorie'], 'actionneur');
      expect(p['label'], 'Éclairage Principal');
    });

    test('capteur avec piece et unit', () {
      final p = AppareilSpec.sensorPayload(
        appareilId: 'dht_temp_salon',
        piece: 'Chambre',
        type: 'DHT_TEMP',
        label: 'Température',
        valeur: 1,
        unit: '°C',
        userId: 'usr_test',
      );
      expect(p['sensorId'], 'dht_temp_salon');
      expect(p['piece'], 'Chambre');
      expect(p['valeur'], 1);
      expect(p['unit'], '°C');
      expect(p.containsKey('timestamp'), isTrue);
    });
  });

  group('Device.fromFirestore', () {
    test('regroupe par piece', () {
      final d = Device.fromFirestore('lampe_salon', {
        'valeur': 1,
        'pin': 2,
        'categorie': 'actionneur',
        'piece': 'Salon',
        'label': 'Éclairage Principal',
      });
      expect(d.piece, 'Salon');
      expect(d.isOn, isTrue);
      expect(d.isActionneur, isTrue);
      expect(d.name, 'Éclairage Principal');
    });

    test('dht_temp_salon', () {
      final d = Device.fromFirestore('dht_temp_salon', {
        'valeur': 24.5,
        'piece': 'Salon',
        'type': 'DHT_TEMP',
        'unit': '°C',
      });
      expect(d.temperatureCelsius, 24.5);
      expect(d.piece, 'Salon');
    });
  });
}
