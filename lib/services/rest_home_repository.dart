import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';
import 'package:smart_home/services/home_repository.dart';

/// À brancher quand l’API backend (JWT + REST) est disponible.
///
/// Remplacer les corps par `package:http` (GET /rooms, GET /devices, PATCH commande).
class RestHomeRepository implements HomeRepository {
  RestHomeRepository({
    required this.baseUrl,
    required this.tokenProvider,
  });

  final String baseUrl;
  final Future<String?> Function() tokenProvider;

  @override
  bool get usesCanonicalSchema => false;

  @override
  Future<List<int>> availablePins() async => [];

  @override
  Stream<List<HouseRoom>> watchRooms() {
    return Stream<List<HouseRoom>>.error(
      UnimplementedError(
        'GET $baseUrl/rooms (+ polling ou WebSocket) — à implémenter avec le backend.',
      ),
    );
  }

  @override
  Stream<List<Device>> watchDevices() {
    return Stream<List<Device>>.error(
      UnimplementedError(
        'GET $baseUrl/devices — à implémenter avec le backend.',
      ),
    );
  }

  @override
  Stream<bool> watchHouseOnline() {
    return Stream<bool>.value(false);
  }

  @override
  Future<void> sendDeviceCommand(String deviceId, Map<String, dynamic> patch) {
    return Future<void>.error(
      UnimplementedError(
        'PATCH $baseUrl/devices/$deviceId/state — Bearer token via tokenProvider().',
      ),
    );
  }

  @override
  Future<String> addRoom(String name) {
    return Future<String>.error(
      UnimplementedError('POST $baseUrl/rooms — à implémenter.'),
    );
  }

  @override
  Future<void> renameRoom(String roomId, String newName) {
    return Future<void>.error(
      UnimplementedError('PATCH $baseUrl/rooms/$roomId — à implémenter.'),
    );
  }

  @override
  @override
  Future<List<Device>> listRfidReaders() {
    return Future<List<Device>>.error(
      UnimplementedError('GET RFID readers — à implémenter.'),
    );
  }

  @override
  Future<String> addDevice({
    required String roomId,
    required String name,
    required String type,
    int? pin,
    String? categorie,
    Map<String, dynamic>? initialState,
    String? rfidCible,
  }) {
    return Future<String>.error(
      UnimplementedError('POST $baseUrl/devices — à implémenter.'),
    );
  }

  @override
  @override
  Future<void> updateDevicePiece(String deviceId, String roomId) {
    return Future<void>.error(
      UnimplementedError('PATCH device piece — à implémenter.'),
    );
  }

  Future<void> updateDevicePin(String deviceId, int pin) {
    return Future<void>.error(
      UnimplementedError(
          'PATCH $baseUrl/devices/$deviceId/pin — à implémenter.'),
    );
  }

  @override
  Future<void> deleteRoom(String roomId) {
    return Future<void>.error(
      UnimplementedError('DELETE $baseUrl/rooms/$roomId — à implémenter.'),
    );
  }

  @override
  Future<void> deleteDevice(String deviceId) {
    return Future<void>.error(
      UnimplementedError('DELETE $baseUrl/devices/$deviceId — à implémenter.'),
    );
  }

  @override
  Future<void> addDhtSensor({
    required String roomId,
    required int pin,
    double? temperature,
    double? humidity,
  }) {
    return Future<void>.error(
      UnimplementedError('POST DHT sensor — à implémenter.'),
    );
  }

  @override
  Future<void> deleteDhtSensorPair(String tempDocId) {
    return Future<void>.error(
      UnimplementedError('DELETE DHT pair — à implémenter.'),
    );
  }
}
