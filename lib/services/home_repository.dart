import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';

/// Contrat données « Maison → Pièces → Appareils » (Firestore : détection `maison/_data/…` ou `/rooms`).
/// Implémentations : [FirestoreHomeRepository], plus tard REST ([RestHomeRepository]).
abstract class HomeRepository {
  Stream<List<HouseRoom>> watchRooms();

  Stream<List<Device>> watchDevices();

  /// Fusionne [patch] dans `device.state` côté persistance (Firestore ou PATCH API).
  Future<void> sendDeviceCommand(String deviceId, Map<String, dynamic> patch);

  /// Ajoute une pièce ; retourne l’**ID document** (slug dérivé du nom, ex. `salon`, `salon_2`).
  Future<String> addRoom(String name);

  /// Ajoute un appareil ; retourne l’**ID document** (`{roomId}_{slug_nom}`, ex. `salon_lampe`).
  Future<String> addDevice({
    required String roomId,
    required String name,
    required String type,
    Map<String, dynamic>? initialState,
  });

  /// Supprime la pièce et, en cascade, tous les appareils dont `roomId` correspond.
  Future<void> deleteRoom(String roomId);

  /// Supprime un document appareil.
  Future<void> deleteDevice(String deviceId);
}
