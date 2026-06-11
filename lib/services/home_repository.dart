import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';

abstract class HomeRepository {
  Stream<List<HouseRoom>> watchRooms();

  Stream<List<Device>> watchDevices();

  bool get usesCanonicalSchema;

  Future<void> sendDeviceCommand(String deviceId, Map<String, dynamic> patch);

  Future<String> addRoom(String name);

  /// Schéma `appareils` : [type] ∈ DHT_TEMP|DHT_HUM|PIR|RELAIS|LED, [pin] 2–53.
  Future<String> addDevice({
    required String roomId,
    required String name,
    required String type,
    int? pin,
    String? categorie,
    Map<String, dynamic>? initialState,
    String? rfidCible,
  });

  Future<List<int>> availablePins();

  Future<List<Device>> listRfidReaders();

  /// Met à jour la broche GPIO (2–53), vérifie l’unicité.
  Future<void> updateDevicePin(String deviceId, int pin);

  Future<void> deleteRoom(String roomId);

  Future<void> deleteDevice(String deviceId);

  /// Un seul doc DHT : température et humidité dans `valeur` (ex. `24.5/60`).
  Future<void> addDhtSensor({
    required String roomId,
    required int pin,
    double? temperature,
    double? humidity,
  });

  Future<void> deleteDhtSensorPair(String tempDocId);
}
