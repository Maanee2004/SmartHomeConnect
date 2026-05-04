import 'package:flutter/material.dart';
import 'package:smart_home/models/floor_plan.dart';
import 'package:smart_home/models/plan_device.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Dessine le plan : grille, pièces, appareils, sélection et poignées.
class FloorPlanPainter extends CustomPainter {
  FloorPlanPainter({
    required this.plan,
    required this.selectedRoomId,
    required this.palette,
    this.handleRadius = 10,
  });

  final FloorPlan plan;
  final String? selectedRoomId;
  final SmartHomeColors palette;
  final double handleRadius;

  static const double minRoomSize = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = palette.planCanvasBg;
    canvas.drawRect(Offset.zero & size, bg);

    _drawGrid(canvas, size);

    for (final room in plan.rooms) {
      final isSelected = room.id == selectedRoomId;
      final r = room.rect;

      final fill = Paint()
        ..color =
            isSelected ? palette.planRoomSelectedFill : palette.planRoomIdle;
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.5
        ..color = isSelected ? palette.planBorderSelected : palette.planBorder;

      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(8)),
        border,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: room.name,
          style: TextStyle(
            color: palette.planNameColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: r.width - 12);

      tp.paint(
        canvas,
        Offset(
          r.left + 8,
          r.top + (r.height - tp.height) / 2,
        ),
      );

      for (final dev in room.devices) {
        final centre = r.topLeft + dev.offsetInRoom;
        _drawDeviceIcon(canvas, dev.kind.icon, centre);
      }

      if (isSelected) {
        _drawHandles(canvas, r);
      }
    }
  }

  void _drawDeviceIcon(Canvas canvas, IconData icon, Offset centre) {
    final sz = PlanDevice.iconSize;
    final bg = Paint()..color = palette.planDeviceBg;
    canvas.drawCircle(centre, sz / 2 + 2, bg);

    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: sz * 0.85,
          fontFamily: icon.fontFamily ?? 'MaterialIcons',
          package: icon.fontPackage,
          color: palette.planIconColor,
        ),
      ),
    )..layout();
    tp.paint(
      canvas,
      centre - Offset(tp.width / 2, tp.height / 2),
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = palette.planGrid
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawHandles(Canvas canvas, Rect r) {
    final paint = Paint()..color = palette.planHandle;
    final border = Paint()
      ..color = palette.planHandleRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final c in corners(r)) {
      canvas.drawCircle(c, handleRadius, paint);
      canvas.drawCircle(c, handleRadius, border);
    }
  }

  static List<Offset> corners(Rect r) => [
        r.topLeft,
        r.topRight,
        r.bottomLeft,
        r.bottomRight,
      ];

  static String? hitCorner(Rect rect, Offset p, double radius) {
    const names = ['tl', 'tr', 'bl', 'br'];
    final pts = corners(rect);
    for (var i = 0; i < 4; i++) {
      if ((pts[i] - p).distance <= radius) return names[i];
    }
    return null;
  }

  static Rect resizeFromCorner(
      Rect r, String corner, Offset p, double minSize) {
    double left = r.left, top = r.top, right = r.right, bottom = r.bottom;
    switch (corner) {
      case 'br':
        right = p.dx.clamp(left + minSize, double.infinity);
        bottom = p.dy.clamp(top + minSize, double.infinity);
        break;
      case 'bl':
        left = p.dx.clamp(-double.infinity, right - minSize);
        bottom = p.dy.clamp(top + minSize, double.infinity);
        break;
      case 'tr':
        right = p.dx.clamp(left + minSize, double.infinity);
        top = p.dy.clamp(-double.infinity, bottom - minSize);
        break;
      case 'tl':
        left = p.dx.clamp(-double.infinity, right - minSize);
        top = p.dy.clamp(-double.infinity, bottom - minSize);
        break;
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) {
    if (oldDelegate.selectedRoomId != selectedRoomId) return true;
    if (oldDelegate.plan.rooms.length != plan.rooms.length) return true;
    if (!identical(oldDelegate.plan, plan)) return true;
    for (var i = 0; i < plan.rooms.length; i++) {
      final a = oldDelegate.plan.rooms[i];
      final b = plan.rooms[i];
      if (a.id != b.id ||
          a.rect != b.rect ||
          a.name != b.name ||
          a.devices.length != b.devices.length) {
        return true;
      }
      for (var j = 0; j < a.devices.length; j++) {
        final da = a.devices[j];
        final db = b.devices[j];
        if (da.id != db.id ||
            da.kind != db.kind ||
            da.offsetInRoom != db.offsetInRoom) {
          return true;
        }
      }
    }
    return false;
  }
}
