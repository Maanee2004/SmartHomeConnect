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
