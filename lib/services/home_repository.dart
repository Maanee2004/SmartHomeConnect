import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';

abstract class HomeRepository {
  Stream<List<HouseRoom>> watchRooms();

  Stream<List<Device>> watchDevices();

  /// `true` si l’ESP32 a signalé la maison en ligne (`maisons/{userId}/isonline/isonline`).
  Stream<bool> watchHouseOnline();

  bool get usesCanonicalSchema;

  Future<void> sendDeviceCommand(String deviceId, Map<String, dynamic> patch);

  Future<String> addRoom(String name);

  /// Renomme une pièce (id inchangé) et met à jour le champ `piece` des appareils.
  Future<void> renameRoom(String roomId, String newName);

  /// Schéma `appareils` : DHT|PIR|RFID|ULTRA|RELAIS|LAMPE|MOTEUR|SERVO|MAX, pin 2–53.
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

  /// Broches déjà prises → nom affiché de l’appareil (pour le sélecteur GPIO).
  Future<Map<int, String>> pinUsageLabels();

  Future<List<Device>> listRfidReaders();

  /// Met à jour la broche GPIO (2–53), vérifie l’unicité.
  Future<void> updateDevicePin(String deviceId, int pin);

  /// Déplace un appareil vers une autre pièce (champ `piece`).
  Future<void> updateDevicePiece(String deviceId, String roomId);

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
