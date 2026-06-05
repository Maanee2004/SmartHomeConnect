import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';

abstract class HomeRepository {
  Stream<List<HouseRoom>> watchRooms();

  Stream<List<Device>> watchDevices();

  bool get usesCanonicalSchema;

  Future<void> sendDeviceCommand(String deviceId, Map<String, dynamic> patch);

  Future<String> addRoom(String name);

  /// Schéma `appareils` : [type] ∈ relais|DHT22|PIR, [pin] 2–53, [categorie] optionnelle.
  Future<String> addDevice({
    required String roomId,
    required String name,
    required String type,
    int? pin,
    String? categorie,
    Map<String, dynamic>? initialState,
  });

  Future<List<int>> availablePins();

  /// Met à jour la broche GPIO (2–53), vérifie l’unicité.
  Future<void> updateDevicePin(String deviceId, int pin);

  Future<void> deleteRoom(String roomId);

  Future<void> deleteDevice(String deviceId);
}
