import 'package:flutter/material.dart';

/// Type d’appareil placable sur le plan (icône palette).
enum PlanDeviceKind {
  lamp,
  fan,
  outlet,
  camera,
}

PlanDeviceKind? parsePlanDeviceKind(String? s) {
  switch (s) {
    case 'lamp':
      return PlanDeviceKind.lamp;
    case 'fan':
      return PlanDeviceKind.fan;
    case 'outlet':
      return PlanDeviceKind.outlet;
    case 'camera':
      return PlanDeviceKind.camera;
    default:
      return null;
  }
}

extension PlanDeviceKindX on PlanDeviceKind {
  IconData get icon {
    switch (this) {
      case PlanDeviceKind.lamp:
        return Icons.lightbulb_rounded;
      case PlanDeviceKind.fan:
        return Icons.air_rounded;
      case PlanDeviceKind.outlet:
        return Icons.power_rounded;
      case PlanDeviceKind.camera:
        return Icons.videocam_rounded;
    }
  }

  String get wireName {
    switch (this) {
      case PlanDeviceKind.lamp:
        return 'lamp';
      case PlanDeviceKind.fan:
        return 'fan';
      case PlanDeviceKind.outlet:
        return 'outlet';
      case PlanDeviceKind.camera:
        return 'camera';
    }
  }
}

/// Appareil posé dans une pièce (position relative au coin haut-gauche de la pièce).
class PlanDevice {
  PlanDevice({
    required this.id,
    required this.kind,
    required this.offsetInRoom,
  });

  final String id;
  final PlanDeviceKind kind;

  /// Centre de l’icône par rapport au `Rect` de la pièce (topLeft + offset = centre canvas).
  Offset offsetInRoom;

  static const double iconSize = 32;
  static const double margin = 16;

  PlanDevice copyWith({Offset? offsetInRoom}) {
    return PlanDevice(
      id: id,
      kind: kind,
      offsetInRoom: offsetInRoom ?? this.offsetInRoom,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.wireName,
        'dx': offsetInRoom.dx,
        'dy': offsetInRoom.dy,
      };

  static PlanDevice fromMap(Map<String, dynamic> m) {
    final kind = parsePlanDeviceKind(m['kind'] as String?) ?? PlanDeviceKind.lamp;
    return PlanDevice(
      id: m['id'] as String,
      kind: kind,
      offsetInRoom: Offset(
        (m['dx'] as num).toDouble(),
        (m['dy'] as num).toDouble(),
      ),
    );
  }

  /// Garde le centre de l’icône dans la pièce (marges).
  static Offset clampOffsetInRoom(Offset centreInRoom, Rect room) {
    final half = iconSize / 2;
    final minX = margin + half;
    final maxX = room.width - margin - half;
    final minY = margin + half;
    final maxY = room.height - margin - half;
    if (maxX < minX || maxY < minY) {
      return Offset(room.width / 2, room.height / 2);
    }
    return Offset(
      centreInRoom.dx.clamp(minX, maxX),
      centreInRoom.dy.clamp(minY, maxY),
    );
  }

  static List<PlanDevice> clampAllToRoom(List<PlanDevice> list, Rect room) {
    return list
        .map((d) => d.copyWith(offsetInRoom: clampOffsetInRoom(d.offsetInRoom, room)))
        .toList();
  }
}
