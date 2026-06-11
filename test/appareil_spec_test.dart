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
      expect(p['type'], 'RELAIS');
      expect(p['unit'], 'booleen');
      expect(p['label'], 'Éclairage Principal');
    });

    test('LIGHT UI mappe vers RELAIS en base', () {
      final p = AppareilSpec.actuatorPayload(
        appareilId: 'lampe_salon',
        piece: 'Salon',
        type: 'LIGHT',
        label: 'Lampe',
        pin: 3,
        userId: 'usr_test',
      );
      expect(p['type'], 'RELAIS');
    });

    test('DHT22 stocke temp et hum dans valeur', () {
      final p = AppareilSpec.sensorPayload(
        appareilId: 'dht_salon',
        piece: 'Salon',
        type: 'DHT22',
        label: 'Capteur DHT Salon',
        valeur: 24.5,
        unit: '°C/%',
        userId: 'usr_test',
        pin: 5,
        temperature: 24.5,
        humidity: 60.0,
      );
      expect(p['type'], 'DHT22');
      expect(p['valeur'], '24.5/60.0');
      expect(p['temperature'], 24.5);
      expect(p['humidity'], 60.0);
      expect(p['unit'], '°C/%');
    });

    test('RFID capteur unit string', () {
      final p = AppareilSpec.sensorPayload(
        appareilId: 'salon2_lecteur_rfid',
        piece: 'salon2',
        type: 'RFID',
        label: 'Lecteur RFID Entrée',
        valeur: '0',
        unit: '',
        userId: 'usr_test',
        pin: 10,
      );
      expect(p['type'], 'RFID');
      expect(p['unit'], 'string');
      expect(p['valeur'], '0');
    });

    test('SERVO avec rfid_cible', () {
      final p = AppareilSpec.actuatorPayload(
        appareilId: 'salon2_porte_servo',
        piece: 'salon2',
        type: 'SERVO',
        label: 'Servo Portail Principal',
        pin: 9,
        valeur: 0,
        userId: 'usr_test',
        rfidCible: 'salon2_lecteur_rfid',
      );
      expect(p['type'], 'SERVO');
      expect(p['unit'], 'angle');
      expect(p['rfid_cible'], 'salon2_lecteur_rfid');
      expect(p['valeur'], 0);
    });

    test('PIR capteur unit booleen', () {
      final p = AppareilSpec.sensorPayload(
        appareilId: 'pir_chambre',
        piece: 'Chambre',
        type: 'PIR',
        label: 'PIR',
        valeur: 0,
        unit: '',
        userId: 'usr_test',
        pin: 4,
      );
      expect(p['type'], 'PIR');
      expect(p['unit'], 'booleen');
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

    test('dht22 combine temp et humidite', () {
      final d = Device.fromFirestore('dht_salon', {
        'sensorId': 'dht_salon',
        'valeur': 24.5,
        'piece': 'Salon',
        'type': 'DHT22',
        'unit': '°C/%',
        'label': 'Capteur DHT Salon',
        'pin': 5,
        'temperature': 24.5,
        'humidity': 60.0,
      });
      expect(d.temperatureCelsius, 24.5);
      expect(d.humidityPercent, 60.0);
      expect(d.isDhtCombined, isTrue);
      expect(d.isCapteur, isTrue);
      expect(d.name, 'Capteur DHT Salon');
    });

    test('dht_temp avec valeur combinee temp/hum', () {
      final d = Device.fromFirestore('dht_temp_salon', {
        'valeur': '24.5/60',
        'piece': 'Salon',
        'type': 'DHT_TEMP',
        'unit': '°C/%',
        'label': 'Capteur DHT Salon',
        'pin': 5,
      });
      expect(d.temperatureCelsius, 24.5);
      expect(d.humidityPercent, 60.0);
      expect(d.isDhtDisplay, isTrue);
      expect(d.piece, 'Salon');
      expect(d.isCapteur, isTrue);
      expect(d.isActionneur, isFalse);
    });

    test('valeur chaine temp,hum', () {
      final d = Device.fromFirestore('dht_salon', {
        'sensorId': 'dht_salon',
        'valeur': '24.5,60',
        'piece': 'Salon',
        'type': 'DHT22',
        'label': 'Capteur DHT',
        'pin': 5,
      });
      expect(d.temperatureCelsius, 24.5);
      expect(d.humidityPercent, 60.0);
    });

    test('fusion legacy dht_temp + dht_hum', () {
      final temp = Device.fromFirestore('dht_temp_salon', {
        'sensorId': 'dht_temp_salon',
        'valeur': 24.5,
        'piece': 'Salon',
        'type': 'DHT_TEMP',
        'pin': 5,
        'label': 'Température Salon',
      });
      final hum = Device.fromFirestore('dht_hum_salon', {
        'sensorId': 'dht_hum_salon',
        'valeur': 60,
        'piece': 'Salon',
        'type': 'DHT_HUM',
        'pin': 5,
        'label': 'Humidité Salon',
      });
      final merged = Device.mergeDhtPair(temp, hum);
      expect(merged?.temperatureCelsius, 24.5);
      expect(merged?.humidityPercent, 60.0);
      expect(merged?.isMergedDhtPair, isTrue);
      expect(merged?.humidityPercent, 60.0);
      expect(merged?.normalizedType, 'DHT_PAIR');
    });

    test('capteur avec pin reste capteur', () {
      final d = Device.fromFirestore('pir_chambre', {
        'sensorId': 'pir_chambre',
        'valeur': 1,
        'piece': 'Chambre',
        'type': 'PIR',
        'unit': 'booleen',
        'label': 'Détecteur Chambre',
        'pin': 4,
      });
      expect(d.isCapteur, isTrue);
      expect((d.valeur ?? 0) != 0, isTrue);
    });
  });
}
