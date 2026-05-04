import 'dart:ui' show Offset, Rect;

import 'package:smart_home/models/plan_device.dart';

/// Une pièce du plan 2D (position + taille + appareils placés).
class Room {
  Room({
    required this.id,
    required this.name,
    required this.rect,
    List<PlanDevice>? devices,
  }) : devices = devices ?? [];

  final String id;
  String name;
  Rect rect;
  final List<PlanDevice> devices;

  Room copyWith({String? name, Rect? rect, List<PlanDevice>? devices}) {
    return Room(
      id: id,
      name: name ?? this.name,
      rect: rect ?? this.rect,
      devices: devices ??
          List<PlanDevice>.from(
            this.devices.map(
              (d) => PlanDevice(
                id: d.id,
                kind: d.kind,
                offsetInRoom: d.offsetInRoom,
              ),
            ),
          ),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'l': rect.left,
        't': rect.top,
        'w': rect.width,
        'h': rect.height,
        'devices': devices.map((d) => d.toMap()).toList(),
      };

  static Room fromMap(Map<String, dynamic> m) {
    final raw = m['devices'];
    final devs = <PlanDevice>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          devs.add(PlanDevice.fromMap(e));
        } else if (e is Map) {
          devs.add(PlanDevice.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }
    return Room(
      id: m['id'] as String,
      name: (m['name'] as String?) ?? 'Pièce',
      rect: Rect.fromLTWH(
        (m['l'] as num).toDouble(),
        (m['t'] as num).toDouble(),
        (m['w'] as num).toDouble(),
        (m['h'] as num).toDouble(),
      ),
      devices: devs,
    );
  }
}

/// Plan d’étage : liste de pièces.
class FloorPlan {
  FloorPlan({required this.rooms});

  final List<Room> rooms;

  factory FloorPlan.empty() => FloorPlan(rooms: []);

  FloorPlan copyWithRooms(List<Room> next) => FloorPlan(rooms: next);

  Map<String, dynamic> toFirestoreMap() => {
        'rooms': rooms.map((r) => r.toMap()).toList(),
      };

  static FloorPlan fromFirestoreMap(Map<String, dynamic>? data) {
    if (data == null) return FloorPlan.empty();
    final raw = data['rooms'];
    if (raw is! List) return FloorPlan.empty();
    final list = <Room>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        list.add(Room.fromMap(e));
      } else if (e is Map) {
        list.add(Room.fromMap(Map<String, dynamic>.from(e)));
      }
    }
    return FloorPlan(rooms: list);
  }

  /// Pièce au-dessus des autres en premier (dernier index = dessus).
  Room? hitTestRoom(Offset p) {
    for (var i = rooms.length - 1; i >= 0; i--) {
      if (rooms[i].rect.contains(p)) return rooms[i];
    }
    return null;
  }
}
