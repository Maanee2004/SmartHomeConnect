/// Pièce « maison » (liste hiérarchique), distincte de [Room] du plan 2D.
class HouseRoom {
  const HouseRoom({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory HouseRoom.fromFirestore(String id, Map<String, dynamic> data) {
    final n = (data['name'] as String?)?.trim();
    return HouseRoom(
      id: id,
      name: (n == null || n.isEmpty) ? 'Pièce' : n,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
