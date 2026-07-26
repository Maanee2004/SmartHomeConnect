import 'package:smart_home/models/device.dart';

class HouseRoom {
  const HouseRoom({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  static String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Identifiant document pièce (aligné sur [FirestoreHomeRepository.slugifyRoomDocumentId]).
  static String slugFromLabel(String rawName) {
    var s = rawName.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    if (s.isEmpty) s = 'piece';
    return s.length > 120 ? s.substring(0, 120) : s;
  }

  /// Appareil rattaché à cette pièce (nom `piece`, slug ou id legacy).
  static bool deviceBelongsToRoom(Device device, HouseRoom room) {
    if (device.roomId == room.id) return true;
    final piece = device.piece?.trim();
    if (piece == null || piece.isEmpty) return false;
    if (_norm(piece) == _norm(room.name)) return true;
    if (slugFromLabel(piece) == room.id) return true;
    final simple =
        piece.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    return simple == room.id;
  }

  /// Fusionne les pièces Firestore (`pieces`) et les zones dérivées du champ `piece` des appareils.
  static List<HouseRoom> mergeWithDevicePieces(
    List<HouseRoom> firestoreRooms,
    List<Device> devices,
  ) {
    final byKey = <String, HouseRoom>{};
    for (final r in firestoreRooms) {
      byKey[_norm(r.name)] = r;
    }
    for (final d in devices) {
      final p = d.piece?.trim();
      if (p == null || p.isEmpty) continue;
      final key = _norm(p);
      byKey.putIfAbsent(
        key,
        () => HouseRoom(id: key.replaceAll(' ', '_'), name: p),
      );
    }
    return byKey.values.toList();
  }

  factory HouseRoom.fromFirestore(String id, Map<String, dynamic> data) {
    final n =
        (data['nom'] as String?)?.trim() ?? (data['name'] as String?)?.trim();
    return HouseRoom(
      id: id,
      name: (n == null || n.isEmpty) ? 'Pièce' : n,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
