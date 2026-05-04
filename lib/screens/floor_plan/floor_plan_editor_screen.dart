import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/floor_plan.dart';
import 'package:smart_home/models/plan_device.dart';
import 'package:smart_home/screens/floor_plan/floor_plan_painter.dart';
import 'package:smart_home/services/floor_plan_service.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

/// Éditeur de plan 2D : déplacement, redimensionnement (coins), renommer, Firestore.
class FloorPlanEditorScreen extends StatefulWidget {
  const FloorPlanEditorScreen({super.key});

  @override
  State<FloorPlanEditorScreen> createState() => _FloorPlanEditorScreenState();
}

class _FloorPlanEditorScreenState extends State<FloorPlanEditorScreen> {
  final _service = FloorPlanService();
  final GlobalKey _canvasKey = GlobalKey();
  static const double _handleHit = 18;
  static const double _minSide = FloorPlanPainter.minRoomSize;

  FloorPlan _plan = FloorPlan.empty();
  String? _selectedId;
  String? _activeCorner;
  String _mode = 'none';
  Offset? _lastLocal;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    if (Firebase.apps.isEmpty) {
      if (mounted) {
        setState(() {
          _plan = _defaultPlan();
          _loading = false;
        });
      }
      return;
    }
    try {
      final p = await _service.loadOnce();
      if (!mounted) return;
      setState(() {
        _plan = p.rooms.isEmpty ? _defaultPlan() : p;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _plan = _defaultPlan();
        _loading = false;
      });
    }
  }

  FloorPlan _defaultPlan() {
    return FloorPlan(
      rooms: [
        Room(
          id: 'r1',
          name: 'Salon',
          rect: const Rect.fromLTWH(40, 48, 160, 120),
        ),
        Room(
          id: 'r2',
          name: 'Cuisine',
          rect: const Rect.fromLTWH(220, 48, 140, 100),
        ),
      ],
    );
  }

  Room? _roomById(String? id) {
    if (id == null) return null;
    try {
      return _plan.rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  void _setPlan(FloorPlan next) {
    setState(() => _plan = next);
  }

  FloorPlan _replaceRoom(
    String id, {
    Rect? rect,
    String? name,
    List<PlanDevice>? devices,
  }) {
    return FloorPlan(
      rooms: _plan.rooms.map((r) {
        if (r.id != id) return r;
        final newRect = rect ?? r.rect;
        List<PlanDevice> devs;
        if (devices != null) {
          devs = PlanDevice.clampAllToRoom(
            devices
                .map(
                  (d) => PlanDevice(
                    id: d.id,
                    kind: d.kind,
                    offsetInRoom: d.offsetInRoom,
                  ),
                )
                .toList(),
            newRect,
          );
        } else {
          devs = List<PlanDevice>.from(
            r.devices.map(
              (d) => PlanDevice(
                id: d.id,
                kind: d.kind,
                offsetInRoom: d.offsetInRoom,
              ),
            ),
          );
          if (rect != null) {
            devs = PlanDevice.clampAllToRoom(devs, newRect);
          }
        }
        return Room(
          id: r.id,
          name: name ?? r.name,
          rect: newRect,
          devices: devs,
        );
      }).toList(),
    );
  }

  void _addPlanDevice(String roomId, PlanDeviceKind kind, Offset canvasLocal) {
    final room = _roomById(roomId);
    if (room == null) return;
    if (!room.rect.contains(canvasLocal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dépose l’appareil à l’intérieur de la pièce sélectionnée (surbrillance).',
          ),
        ),
      );
      return;
    }
    final centreInRoom = canvasLocal - room.rect.topLeft;
    final clamped = PlanDevice.clampOffsetInRoom(centreInRoom, room.rect);
    final dev = PlanDevice(
      id: 'd_${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      offsetInRoom: clamped,
    );
    final next = [
      ...room.devices.map(
        (d) => PlanDevice(
          id: d.id,
          kind: d.kind,
          offsetInRoom: d.offsetInRoom,
        ),
      ),
      dev,
    ];
    _setPlan(_replaceRoom(roomId, devices: next));
  }

  Rect _clampRect(Rect r, Size canvas) {
    var w = r.width.clamp(_minSide, canvas.width);
    var h = r.height.clamp(_minSide, canvas.height);
    var left = r.left.clamp(0.0, canvas.width - w);
    var top = r.top.clamp(0.0, canvas.height - h);
    return Rect.fromLTWH(left, top, w, h);
  }

  void _onPanStart(DragStartDetails d, Size canvas) {
    final p = d.localPosition;

    if (_selectedId != null) {
      final sel = _roomById(_selectedId);
      if (sel != null) {
        final corner = FloorPlanPainter.hitCorner(sel.rect, p, _handleHit);
        if (corner != null) {
          setState(() {
            _mode = 'resize';
            _activeCorner = corner;
            _lastLocal = p;
          });
          return;
        }
      }
    }

    final hit = _plan.hitTestRoom(p);
    if (hit != null) {
      setState(() {
        _selectedId = hit.id;
        _mode = 'move';
        _lastLocal = p;
        _activeCorner = null;
      });
      return;
    }

    setState(() {
      _selectedId = null;
      _mode = 'none';
      _activeCorner = null;
    });
  }

  void _onPanUpdate(DragUpdateDetails d, Size canvas) {
    final p = d.localPosition;
    final id = _selectedId;
    if (id == null) return;

    if (_mode == 'resize' && _activeCorner != null) {
      final room = _roomById(id);
      if (room == null) return;
      var nr = FloorPlanPainter.resizeFromCorner(
        room.rect,
        _activeCorner!,
        p,
        _minSide,
      );
      nr = _clampRect(nr, canvas);
      _setPlan(_replaceRoom(id, rect: nr));
      _lastLocal = p;
      return;
    }

    if (_mode == 'move' && _lastLocal != null) {
      final room = _roomById(id);
      if (room == null) return;
      final delta = p - _lastLocal!;
      _lastLocal = p;
      final shifted = room.rect.shift(delta);
      _setPlan(_replaceRoom(id, rect: _clampRect(shifted, canvas)));
    }
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() {
      _mode = 'none';
      _activeCorner = null;
      _lastLocal = null;
    });
  }

  void _addRoom(Size canvas) {
    final n = _plan.rooms.length + 1;
    final id = 'r_${DateTime.now().microsecondsSinceEpoch}';
    final w = 120.0;
    final h = 96.0;
    final left = (40 + (n * 17) % (canvas.width - w - 20)).clamp(0.0, canvas.width - w);
    final top = (60 + (n * 23) % (canvas.height - h - 20)).clamp(0.0, canvas.height - h);
    final room = Room(
      id: id,
      name: 'Pièce $n',
      rect: Rect.fromLTWH(left, top, w, h),
    );
    _setPlan(FloorPlan(rooms: [..._plan.rooms, room]));
    setState(() => _selectedId = id);
  }

  Future<void> _renameSelected() async {
    final id = _selectedId;
    final room = _roomById(id);
    if (room == null) return;

    final controller = TextEditingController(text: room.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = ctx.smartColors;
        return AlertDialog(
          backgroundColor: c.card,
          title: Text(
            'Renommer la pièce',
            style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(color: c.textPrimary),
            decoration: InputDecoration(
              hintText: 'Nom de la pièce',
              hintStyle: TextStyle(color: c.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (ok == true && mounted) {
      final name = controller.text.trim();
      if (name.isNotEmpty) {
        _setPlan(_replaceRoom(room.id, name: name));
      }
    }
    controller.dispose();
  }

  Future<void> _save() async {
    if (Firebase.apps.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase non initialisé — impossible de sauvegarder.')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.save(_plan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan enregistré sur Firestore')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur sauvegarde: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reload() async {
    if (Firebase.apps.isEmpty) return;
    setState(() => _loading = true);
    try {
      final p = await _service.loadOnce();
      if (!mounted) return;
      setState(() {
        _plan = p.rooms.isEmpty ? _defaultPlan() : p;
        _selectedId = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: c.textPrimary),
        title: Text(
          'Plan 2D',
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          const ThemeToggleButton(),
          if (_selectedId != null)
            IconButton(
              tooltip: 'Renommer',
              onPressed: _renameSelected,
              icon: Icon(
                Icons.drive_file_rename_outline,
                color: c.textSecondary,
              ),
            ),
          IconButton(
            tooltip: 'Recharger depuis Firestore',
            onPressed: _loading ? null : _reload,
            icon: Icon(
              Icons.cloud_download_outlined,
              color: c.textSecondary,
            ),
          ),
          IconButton(
            tooltip: 'Enregistrer sur Firestore',
            onPressed: _saving ? null : _save,
            icon: _saving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.textPrimary,
                    ),
                  )
                : Icon(
                    Icons.cloud_upload_outlined,
                    color: c.textSecondary,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final mq = MediaQuery.sizeOf(context);
          final h = (mq.height - kToolbarHeight - 160).clamp(200.0, 600.0);
          _addRoom(Size(mq.width - 32, h));
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Ajouter une pièce'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sélectionne une pièce, puis glisse une icône depuis la palette vers le plan. '
                    'Tu peux déplacer la pièce ou redimensionner avec les coins.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedId != null) ...[
                    _devicePalette(),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: DragTarget<PlanDeviceKind>(
                            onAcceptWithDetails: (details) {
                              final render =
                                  _canvasKey.currentContext?.findRenderObject()
                                      as RenderBox?;
                              if (render == null) return;
                              final local =
                                  render.globalToLocal(details.offset);
                              final roomId = _selectedId;
                              if (roomId == null) return;
                              _addPlanDevice(roomId, details.data, local);
                            },
                            builder: (context, candidateData, rejected) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  RepaintBoundary(
                                    key: _canvasKey,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onPanStart: (d) => _onPanStart(d, size),
                                      onPanUpdate: (d) => _onPanUpdate(d, size),
                                      onPanEnd: _onPanEnd,
                                      child: CustomPaint(
                                        size: size,
                                        painter: FloorPlanPainter(
                                          plan: _plan,
                                          selectedRoomId: _selectedId,
                                          palette: c,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (candidateData.isNotEmpty &&
                                      _selectedId != null)
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: accentColor,
                                              width: 2,
                                            ),
                                            color: accentColor
                                                .withValues(alpha: 0.08),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _devicePalette() {
    final c = context.smartColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appareils — glisse une icône sur le plan',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: PlanDeviceKind.values.map(_paletteDraggable).toList(),
          ),
        ],
      ),
    );
  }

  Widget _paletteDraggable(PlanDeviceKind kind) {
    final c = context.smartColors;
    return Draggable<PlanDeviceKind>(
      data: kind,
      feedback: Material(
        color: Colors.transparent,
        child: Icon(kind.icon, size: 40, color: accentColor),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: Icon(kind.icon, size: 32, color: c.textPrimary),
      ),
      child: Tooltip(
        message: switch (kind) {
          PlanDeviceKind.lamp => 'Lampe',
          PlanDeviceKind.fan => 'Ventilateur',
          PlanDeviceKind.outlet => 'Prise',
          PlanDeviceKind.camera => 'Caméra',
        },
        child: Material(
          color: c.inputFill,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(kind.icon, color: c.textPrimary, size: 28),
          ),
        ),
      ),
    );
  }
}
