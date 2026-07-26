import 'package:flutter_test/flutter_test.dart';
import 'package:smart_home/models/appareil_spec.dart';
import 'package:smart_home/models/device.dart';

void main() {
  group('AppareilSpec payloads', () {
    test('actionneur RELAIS avec piece et label', () {
      final p = AppareilSpec.actuatorPayload(
        appareilId: 'relais_salon',
        piece: 'salon2',
        type: 'RELAIS',
        label: 'Relais',
        pin: 4,
        valeur: '1',
        userId: 'usr_test',
      );
      expect(p['actuatorId'], 'relais_salon');
      expect(p['piece'], 'salon2');
      expect(p['pin'], 4);
      expect(p['valeur'], '1');
      expect(p['categorie'], 'actionneur');
      expect(p['type'], 'RELAIS');
      expect(p['unit'], 'booleen');
    });

    test('LAMPE mappe vers LAMPE', () {
      final p = AppareilSpec.actuatorPayload(
        appareilId: 'lampe_salon',
        piece: 'Salon',
        type: 'LIGHT',
        label: 'Lampe',
        pin: 4,
        userId: 'usr_test',
      );
      expect(p['type'], 'LAMPE');
      expect(p['valeur'], '0');
    });

    test('DHT stocke temp et hum dans valeur', () {
      final p = AppareilSpec.sensorPayload(
        appareilId: 'salon2_temp_rature',
        piece: 'salon2',
        type: 'DHT',
        label: 'Capteur Température/Humidité',
        valeur: 24.5,
        unit: '',
        userId: 'usr_test',
        pin: 14,
        temperature: 24.5,
        humidity: 60.2,
      );
      expect(p['type'], 'DHT');
      expect(p['valeur'], '24.5/60.2');
      expect(p['unit'], 'celsius/%');
    });

    test('RFID capteur unit uid', () {
      final p = AppareilSpec.sensorPayload(
        appareilId: 'rfid_entree',
        piece: 'garage',
        type: 'RFID',
        label: 'Lecteur Badge RFID',
        valeur: '0',
        unit: '',
        userId: 'usr_test',
        pin: 10,
      );
      expect(p['type'], 'RFID');
      expect(p['unit'], 'uid');
      expect(p['valeur'], '0');
    });

    test('ULTRA capteur unit cm', () {
      final p = AppareilSpec.sensorPayload(
        appareilId: 'ultra_garage',
        piece: 'garage',
        type: 'ULTRA',
        label: 'Capteur de Distance',
        valeur: '45',
        unit: '',
        userId: 'usr_test',
        pin: 5,
      );
      expect(p['type'], 'ULTRA');
      expect(p['unit'], 'cm');
      expect(p['valeur'], '45');
    });

    test('SERVO avec rfid_cible optionnel', () {
      final p = AppareilSpec.actuatorPayload(
        appareilId: 'servo_porte',
        piece: 'garage',
        type: 'SERVO',
        label: 'Servomoteur Portail',
        pin: 18,
        valeur: '0',
        userId: 'usr_test',
        rfidCible: 'rfid_entree',
      );
      expect(p['type'], 'SERVO');
      expect(p['unit'], 'booleen');
      expect(p['rfid_cible'], 'rfid_entree');
      expect(p['valeur'], '0');
    });

    test('SERVO sans rfid_cible', () {
      final p = AppareilSpec.actuatorPayload(
        appareilId: 'servo_porte',
        piece: 'garage',
        type: 'SERVO',
        label: 'Servomoteur Portail',
        pin: 18,
        userId: 'usr_test',
      );
      expect(p['rfid_cible'], '');
    });

    test('MAX actionneur', () {
      final p = AppareilSpec.actuatorPayload(
        appareilId: 'matrice_max',
        piece: 'salon2',
        type: 'MAX',
        label: 'Matrice LED Notification',
        pin: 7,
        valeur: '1',
        userId: 'usr_test',
      );
      expect(p['type'], 'MAX');
      expect(p['unit'], 'booleen');
    });

    test('PIR capteur unit booleen', () {
      final p = AppareilSpec.sensorPayload(
        appareilId: 'pir_chambre',
        piece: 'Chambre',
        type: 'PIR',
        label: 'Détecteur PIR',
        valeur: '0',
        unit: '',
        userId: 'usr_test',
        pin: 4,
      );
      expect(p['type'], 'PIR');
      expect(p['unit'], 'booleen');
    });
  });

  group('Device.fromFirestore', () {
    test('actionneur string valeur on/off', () {
      final d = Device.fromFirestore('relais_salon', {
        'valeur': '1',
        'pin': 2,
        'categorie': 'actionneur',
        'piece': 'Salon',
        'type': 'RELAIS',
        'label': 'Relais',
      });
      expect(d.isOn, isTrue);
      expect(d.isActionneur, isTrue);
    });

    test('dht combine temp et humidite', () {
      final d = Device.fromFirestore('dht_salon', {
        'sensorId': 'dht_salon',
        'valeur': '24.5/60.2',
        'piece': 'salon2',
        'type': 'DHT',
        'unit': 'celsius/%',
        'label': 'Capteur Température/Humidité',
        'pin': 2,
      });
      expect(d.temperatureCelsius, 24.5);
      expect(d.humidityPercent, 60.2);
      expect(d.isDhtCombined, isTrue);
    });

    test('ultra distance cm', () {
      final d = Device.fromFirestore('ultra_garage', {
        'sensorId': 'ultra_garage',
        'valeur': '45',
        'piece': 'garage',
        'type': 'ULTRA',
        'unit': 'cm',
        'label': 'Capteur de Distance',
        'pin': 5,
      });
      expect(d.distanceCm, 45);
      expect(d.normalizedType, 'ULTRA');
    });

    test('servo booleen', () {
      final d = Device.fromFirestore('servo_porte', {
        'actuatorId': 'servo_porte',
        'valeur': '1',
        'piece': 'garage',
        'type': 'SERVO',
        'unit': 'booleen',
        'rfid_cible': 'rfid_entree',
        'pin': 9,
      });
      expect(d.isOn, isTrue);
      expect(d.rfidCible, 'rfid_entree');
    });
  });

  group('GPIO réservées ESP32', () {
    test('broches 2,3,9,11,12,13 interdites', () {
      for (final p in AppareilSpec.reservedPins) {
        expect(
          () => AppareilSpec.validatePin(p),
          throwsA(isA<ArgumentError>()),
        );
        expect(AppareilSpec.isPinSelectable(p), isFalse);
      }
      expect(AppareilSpec.isPinSelectable(4), isTrue);
    });

    test('ULTRA : echo (pin+1) ne doit pas être réservée', () {
      expect(
        () => AppareilSpec.validatePinForDeviceType(8, 'ULTRA'),
        throwsA(isA<ArgumentError>()),
      );
      expect(() => AppareilSpec.validatePinForDeviceType(4, 'ULTRA'), returnsNormally);
    });
  });
}
