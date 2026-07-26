import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/models/appareil_spec.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/home_dashboard_stats.dart';
import 'package:smart_home/models/house_room.dart';
import 'package:smart_home/screens/auth/login_screen.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/services/home_repository.dart';
import 'package:smart_home/theme/room_icons.dart';
import 'package:smart_home/widgets/dashboard_stats_panel.dart';
import 'package:smart_home/widgets/device_card.dart';
import 'package:smart_home/widgets/device_grid_skeleton.dart';
import 'package:smart_home/widgets/load_error_view.dart';
import 'package:smart_home/widgets/pin_picker_dialog.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';
import 'package:smart_home/l10n/app_localizations.dart';

/// Accueil : appareils filtrés par pièce (défaut **Salon**), sélection via menu ⋮.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.bottomNavigationBar,
    this.onGoHome,
    this.readOnly,
    this.showHeader = true,
    this.houseTitlePrefix,
    this.embedded = false,
    this.focusRoomId,
  });

  final Widget? bottomNavigationBar;
  final VoidCallback? onGoHome;

  /// `false` par défaut pour admin ; `true` pour utilisateurs standards.
  final bool? readOnly;

  final bool showHeader;
  final String? houseTitlePrefix;
  final bool embedded;

  /// Onglet Pièces → ouvre l’accueil filtré sur cette pièce.
  final String? focusRoomId;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static final HomeRepository _repo = FirestoreHomeRepository();

  bool get _canAddDevices =>
      widget.readOnly != true && AuthService.instance.canAddDevices;

  bool get _canAssignDevicesToRooms =>
      widget.readOnly != true &&
      AuthService.instance.canAssignDevicesToRooms;

  bool get _canFullManageDevices =>
      widget.readOnly != true && AuthService.instance.canManageDevices;

  bool get _canAddRoom =>
      AuthService.instance.canAddRooms && Firebase.apps.isNotEmpty;

  /// `true` = afficher tous les appareils, titre « Toute la maison ».
  bool _allHouse = false;

  /// Pièce explicitement choisie dans le menu ; `null` = règle par défaut (Salon ou 1ʳᵉ pièce).
  String? _pickedRoomId;

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyExternalRoomFocus(widget.focusRoomId);
  }

  @override
  void initState() {
    super.initState();
    _applyExternalRoomFocus(widget.focusRoomId);
  }

  void _applyExternalRoomFocus(String? roomId) {
    final id = roomId?.trim();
    if (id == null || id.isEmpty) return;
    if (_pickedRoomId == id && !_allHouse) return;
    _pickedRoomId = id;
    _allHouse = false;
  }

  String _effectiveRoomId(List<HouseRoom> rooms) {
    if (rooms.isEmpty) return '';
    if (_pickedRoomId != null && rooms.any((r) => r.id == _pickedRoomId)) {
      return _pickedRoomId!;
    }
    for (final r in rooms) {
      if (r.name.toLowerCase().trim() == 'salon') return r.id;
    }
    return rooms.first.id;
  }

  String _appBarTitle(BuildContext context, List<HouseRoom> rooms, bool firebaseReady) {
    final l = context.l10n;
    if (!firebaseReady) return l.appTitle;
    if (rooms.isEmpty) return l.myHouse;
    if (_allHouse) return l.wholeHouse;
    final id = _effectiveRoomId(rooms);
    for (final r in rooms) {
      if (r.id == id) return r.name;
    }
    return l.defaultRoomSalon;
  }

  List<Device> _filteredDevices(List<Device> all, List<HouseRoom> rooms) {
    if (_allHouse) return all;
    final id = _effectiveRoomId(rooms);
    if (id.isEmpty) return [];
    HouseRoom? room;
    for (final r in rooms) {
      if (r.id == id) {
        room = r;
        break;
      }
    }
    if (room == null) return [];
    return all.where((d) => HouseRoom.deviceBelongsToRoom(d, room!)).toList();
  }

  Future<void> _onDashboardPullRefresh() async {
    await FirestoreHomeRepository.instance.resetAndReload();
    if (mounted) setState(() {});
  }

  Future<void> _showRoomPicker(
    BuildContext context,
    List<HouseRoom> rooms,
  ) async {
    final sorted = [...rooms]..sort((a, b) => a.name.compareTo(b.name));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final l = ctx.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      context.smartColors.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.showDevices,
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          color: context.smartColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (sorted.isNotEmpty) ...[
                      ListTile(
                        leading:
                            Icon(Icons.home_work_outlined, color: accentColor),
                        title: Text(
                          l.wholeHouse,
                          style:
                              TextStyle(color: context.smartColors.textPrimary),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _allHouse = true;
                            _pickedRoomId = null;
                          });
                        },
                        trailing: _allHouse
                            ? Icon(Icons.check_rounded, color: accentColor)
                            : null,
                      ),
                      const Divider(height: 1),
                    ],
                    if (sorted.isEmpty && _canAddRoom)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l.noRoomsAddFirst,
                          style: TextStyle(
                            color: context.smartColors.textSecondary,
                          ),
                        ),
                      ),
                    ...sorted.map(
                      (r) => ListTile(
                        leading: Icon(
                          roomIconFromName(r.name),
                          color: context.smartColors.textSecondary,
                        ),
                        title: Text(
                          r.name,
                          style:
                              TextStyle(color: context.smartColors.textPrimary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_allHouse && _effectiveRoomId(rooms) == r.id)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: accentColor,
                                ),
                              ),
                            if (_canAddRoom)
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: context.smartColors.textSecondary,
                                  size: 22,
                                ),
                                tooltip: l.renameRoomTooltip,
                                onPressed: () async {
                                  await _promptRenameRoom(
                                    context,
                                    room: r,
                                    sheetContext: ctx,
                                  );
                                },
                              ),
                            if (_canAddDevices)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: errorColor.withValues(alpha: 0.9),
                                  size: 22,
                                ),
                                tooltip: l.deleteRoomTooltip,
                                onPressed: () async {
                                  await _confirmDeleteRoom(
                                    sheetContext: ctx,
                                    messengerContext: context,
                                    room: r,
                                  );
                                },
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _allHouse = false;
                            _pickedRoomId = r.id;
                          });
                        },
                      ),
                    ),
                    if (_canAddRoom) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            Icon(Icons.add_circle_outline, color: accentColor),
                        title: Text(
                          l.addRoom,
                          style:
                              TextStyle(color: context.smartColors.textPrimary),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _promptAddRoom(context);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptAddRoom(BuildContext context) async {
    final l = context.l10n;
    final controller = TextEditingController();
    String? name;
    try {
      name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            l.newRoomTitle,
            style: TextStyle(color: context.smartColors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: context.smartColors.textPrimary),
            decoration: InputDecoration(
              hintText: l.roomNameHint,
              hintStyle: TextStyle(color: context.smartColors.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                Navigator.pop(ctx, t.isEmpty ? null : t);
              },
              child: Text(l.add),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (name == null || name.isEmpty) return;
    try {
      final id = await _repo.addRoom(name);
      if (context.mounted) {
        final suffix = id.isEmpty ? '' : ' (id: $id)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.roomAdded(name, suffix))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(FirestoreHomeRepository.describeFirebaseError(e)),
          ),
        );
      }
    }
  }

  Future<void> _promptRenameRoom(
    BuildContext context, {
    required HouseRoom room,
    BuildContext? sheetContext,
  }) async {
    final l = context.l10n;
    final controller = TextEditingController(text: room.name);
    String? name;
    try {
      name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            l.renameRoomTitle,
            style: TextStyle(color: context.smartColors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: context.smartColors.textPrimary),
            decoration: InputDecoration(
              hintText: l.newNameHint,
              hintStyle: TextStyle(color: context.smartColors.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                Navigator.pop(ctx, t.isEmpty ? null : t);
              },
              child: Text(l.save),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (name == null || name.isEmpty || name == room.name) return;
    try {
      await _repo.renameRoom(room.id, name);
      if (!context.mounted) return;
      if (sheetContext?.mounted == true) {
        Navigator.pop(sheetContext!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.roomRenamed(name))),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(FirestoreHomeRepository.describeFirebaseError(e)),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteDevice(BuildContext context, Device device) async {
    if (!Firebase.apps.isNotEmpty) return;
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.deleteDeviceTitle(device.name),
          style: TextStyle(color: context.smartColors.textPrimary),
        ),
        content: Text(
          l.deleteDeviceBody,
          style: TextStyle(color: context.smartColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      if (device.isMergedDhtPair) {
        await _repo.deleteDhtSensorPair(device.id);
      } else {
        await _repo.deleteDevice(device.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.deviceDeleted(device.name))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.failureMessage(e))),
        );
      }
    }
  }

  Future<void> _confirmDeleteRoom({
    required BuildContext sheetContext,
    required BuildContext messengerContext,
    required HouseRoom room,
  }) async {
    if (!Firebase.apps.isNotEmpty) return;
    final l = messengerContext.l10n;
    final ok = await showDialog<bool>(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.deleteRoomTitle(room.name),
          style: TextStyle(color: context.smartColors.textPrimary),
        ),
        content: Text(
          l.deleteRoomBody,
          style: TextStyle(color: context.smartColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteRoom(room.id);
      if (!messengerContext.mounted) return;
      if (sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
      setState(() {
        if (_pickedRoomId == room.id) _pickedRoomId = null;
      });
      ScaffoldMessenger.of(messengerContext).showSnackBar(
        SnackBar(content: Text(l.roomDeleted(room.name))),
      );
    } catch (e) {
      if (messengerContext.mounted) {
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(content: Text(l.failureMessage(e))),
        );
      }
    }
  }

  Future<String?> _pickRoomForDevice(
    BuildContext context,
    List<HouseRoom> rooms,
  ) async {
    final sorted = [...rooms]..sort((a, b) => a.name.compareTo(b.name));
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    context.smartColors.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ctx.l10n.pickRoomForDevice,
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        color: context.smartColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.45,
              ),
              child: ListView(
                shrinkWrap: true,
                children: sorted
                    .map(
                      (r) => ListTile(
                        leading: Icon(
                          roomIconFromName(r.name),
                          color: context.smartColors.textSecondary,
                        ),
                        title: Text(
                          r.name,
                          style:
                              TextStyle(color: context.smartColors.textPrimary),
                        ),
                        onTap: () => Navigator.pop(ctx, r.id),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<String?> _resolveTargetRoomId(
    BuildContext context,
    List<HouseRoom> rooms,
  ) async {
    if (rooms.isEmpty) return null;
    if (!_allHouse) return _effectiveRoomId(rooms);
    return _pickRoomForDevice(context, rooms);
  }

  /// Demande une broche GPIO avant création (obligatoire pour actionneurs).
  Future<int?> _resolvePinForNewDevice(
    BuildContext context, {
    required String type,
    required String deviceLabel,
  }) async {
    final needsPin = AppareilSpec.requiresPin(type);
    final l = context.l10n;
    return showPinPickerDialog(
      context,
      repo: _repo,
      required: needsPin,
      deviceType: type,
      title: needsPin ? l.gpioPinRequired : l.gpioPinOptional,
      subtitle:
          '$deviceLabel — ${l.gpioPinRange(AppareilSpec.minPin, AppareilSpec.maxPin)}',
    );
  }

  Future<void> _moveDeviceToRoom(
    BuildContext context,
    Device device,
    List<HouseRoom> rooms,
  ) async {
    final l = context.l10n;
    if (rooms.isEmpty) return;
    final roomId = await _pickRoomForDevice(context, rooms);
    if (roomId == null || !context.mounted) return;

    final target = rooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => HouseRoom(id: roomId, name: roomId),
    );
    if (HouseRoom.deviceBelongsToRoom(device, target)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.deviceAlreadyInRoom)),
      );
      return;
    }

    try {
      await _repo.updateDevicePiece(device.id, roomId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.deviceMoved(device.name, target.name))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describePinError(e))),
      );
    }
  }

  Future<void> _editDevicePin(BuildContext context, Device device) async {
    final l = context.l10n;
    final pin = await showPinPickerDialog(
      context,
      repo: _repo,
      required: device.expectsPin,
      currentPin: device.pin,
      deviceType: device.type,
      title: l.editPinTitle,
      subtitle: device.name,
    );
    if (pin == null || !context.mounted) return;
    try {
      await _repo.updateDevicePin(device.id, pin);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pinAssigned(pin, device.name))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describePinError(e))),
      );
    }
  }

  Future<void> _addRfidReader(
    BuildContext context,
    List<HouseRoom> rooms,
  ) async {
    await _addQuickDevice(
      context,
      rooms,
      name: 'Lecteur RFID',
      type: 'RFID',
      initialState: const {'valeur': '0'},
    );
  }

  Future<void> _addServoDoor(
    BuildContext context,
    List<HouseRoom> rooms,
  ) async {
    final readers = await _repo.listRfidReaders();
    if (!context.mounted) return;

    final roomId = await _resolveTargetRoomId(context, rooms);
    if (roomId == null || !context.mounted) return;

    String? rfidId;
    final l = context.l10n;
    if (readers.isNotEmpty) {
      rfidId = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(
            l.rfidReaderOptional,
            style: TextStyle(color: context.smartColors.textPrimary),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, ''),
              child: Text(l.noReader),
            ),
            for (final r in readers)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, r.id),
                child: Text('${r.name} (${r.id})'),
              ),
          ],
        ),
      );
      if (!context.mounted) return;
    }

    final pin = await showPinPickerDialog(
      context,
      repo: _repo,
      required: true,
      deviceType: 'SERVO',
      title: l.servoPinTitle,
      subtitle: rfidId != null && rfidId.isNotEmpty
          ? 'rfid_cible → $rfidId'
          : 'Sans lecteur RFID lié',
    );
    if (pin == null || !context.mounted) return;

    try {
      await _repo.addDevice(
        roomId: roomId,
        name: 'Servomoteur Portail',
        type: 'SERVO',
        pin: pin,
        rfidCible: rfidId != null && rfidId.isNotEmpty ? rfidId : null,
      );
      if (!context.mounted) return;
      final rfidNote =
          rfidId != null && rfidId.isNotEmpty ? ' (rfid_cible: $rfidId)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Servo ajouté$rfidNote, broche $pin.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describePinError(e))),
      );
    }
  }

  Future<void> _addDhtSensor(
    BuildContext context,
    List<HouseRoom> rooms,
  ) async {
    final l = context.l10n;
    final roomId = await _resolveTargetRoomId(context, rooms);
    if (roomId == null || !context.mounted) return;

    final pin = await showPinPickerDialog(
      context,
      repo: _repo,
      required: true,
      deviceType: 'DHT',
      title: l.dhtPinTitle,
      subtitle: l.dhtPinSubtitle,
    );
    if (pin == null || !context.mounted) return;

    try {
      await _repo.addDhtSensor(roomId: roomId, pin: pin);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.dhtAdded(pin)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(describePinError(e))),
      );
    }
  }

  Future<void> _addQuickDevice(
    BuildContext context,
    List<HouseRoom> rooms, {
    required String name,
    required String type,
    Map<String, dynamic>? initialState,
  }) async {
    final roomId = await _resolveTargetRoomId(context, rooms);
    if (roomId == null || !context.mounted) return;

    final pin = await _resolvePinForNewDevice(
      context,
      type: type,
      deviceLabel: name,
    );
    if (!context.mounted) return;
    if (AppareilSpec.requiresPin(type) && pin == null) return;

    try {
      final devId = await _repo.addDevice(
        roomId: roomId,
        name: name,
        type: type,
        pin: pin,
        initialState: initialState,
      );
      if (context.mounted) {
        final pinNote = pin != null ? ', broche $pin' : '';
        final suffix = devId.isEmpty ? '' : ' (id: $devId)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('« $name » ajouté$pinNote.$suffix')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describePinError(e))),
        );
      }
    }
  }

  Future<void> _showAddDeviceSheet(
    BuildContext context,
    List<HouseRoom> rooms,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final sheetL = ctx.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      context.smartColors.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    sheetL.addDeviceSheetTitle,
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          color: context.smartColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              if (_allHouse)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      sheetL.allHouseAddHint,
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: context.smartColors.textSecondary,
                          ),
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        sheetL.typesUppercaseHint,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: context.smartColors.textSecondary,
                            ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        sheetL.sensorsSection,
                        style: TextStyle(
                          color: context.smartColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.device_thermostat_rounded,
                          color: accentColor),
                      title: Text(
                        'Capteur DHT',
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type DHT — valeur « 24.5/60.2 » — unit celsius/%',
                        style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addDhtSensor(context, rooms);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.sensors_rounded, color: accentColor),
                      title: Text(
                        'Détecteur PIR',
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type: PIR — mouvement 0/1',
                        style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addQuickDevice(context, rooms,
                            name: 'Détecteur PIR', type: 'PIR');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.nfc_rounded, color: accentColor),
                      title: Text(
                        'Lecteur RFID',
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type RFID — unit uid — pousse l’UID scanné',
                        style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addRfidReader(context, rooms);
                      },
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.straighten_rounded, color: accentColor),
                      title: Text(
                        'Capteur ultrason',
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type ULTRA — unit cm — Trigger=pin, Echo=pin+1',
                        style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addQuickDevice(context, rooms,
                            name: 'Capteur de Distance',
                            type: 'ULTRA',
                            initialState: const {'valeur': '0'});
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        sheetL.actuatorsSection,
                        style: TextStyle(
                          color: context.smartColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.lightbulb_outline, color: accentColor),
                      title: Text(
                        'Lampe',
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type LAMPE — unit booleen',
                        style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addQuickDevice(context, rooms,
                            name: 'Lampe', type: 'LAMPE');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.power_rounded, color: accentColor),
                      title: Text(
                        'Relais',
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type RELAIS — ON/OFF',
                        style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addQuickDevice(context, rooms,
                            name: 'Relais', type: 'RELAIS');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.grid_on_rounded, color: accentColor),
                      title: Text(
                        'Matrice LED MAX7219',
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type MAX — broche CS — unit booleen',
                        style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addQuickDevice(context, rooms,
                            name: 'Matrice LED', type: 'MAX');
                      },
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.door_sliding_rounded, color: accentColor),
                      title: Text(
                        'Servo porte',
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type SERVO — unit booleen — rfid_cible optionnel',
                        style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addServoDoor(context, rooms);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.tune_rounded, color: accentColor),
                      title: Text(
                        sheetL.customDevice,
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        sheetL.customDeviceSubtitle,
                        style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _promptCustomDevice(context, rooms);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptCustomDevice(
    BuildContext context,
    List<HouseRoom> rooms,
  ) async {
    final l = context.l10n;
    final nameCtrl = TextEditingController();
    var type = 'RELAIS';
    var roomId = _effectiveRoomId(rooms);
    final sorted = [...rooms]..sort((a, b) => a.name.compareTo(b.name));

    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: Text(
                l.customDeviceTitle,
                style: TextStyle(color: context.smartColors.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      style: TextStyle(color: context.smartColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l.nameLabel,
                        labelStyle:
                            TextStyle(color: context.smartColors.textSecondary),
                        hintText: l.nameExampleHint,
                        hintStyle:
                            TextStyle(color: context.smartColors.textSecondary),
                      ),
                    ),
                    Text(
                      l.typeLabel,
                      style: TextStyle(
                          color: context.smartColors.textSecondary,
                          fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: type,
                      isExpanded: true,
                      dropdownColor: context.smartColors.card,
                      style: TextStyle(color: context.smartColors.textPrimary),
                      items: [
                        ...AppareilSpec.uiSensorTypes.entries.map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        ),
                        ...AppareilSpec.uiActuatorTypes.entries.map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setSt(() => type = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.roomLabel,
                      style: TextStyle(
                          color: context.smartColors.textSecondary,
                          fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    DropdownButton<String>(
                      value: sorted.any((r) => r.id == roomId)
                          ? roomId
                          : sorted.first.id,
                      isExpanded: true,
                      dropdownColor: context.smartColors.card,
                      style: TextStyle(color: context.smartColors.textPrimary),
                      items: sorted
                          .map(
                            (r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSt(() => roomId = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(l.add),
                ),
              ],
            );
          },
        ),
      );
      if (ok != true || !context.mounted) return;
      final name = nameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.enterName)),
        );
        return;
      }

      final pin = await _resolvePinForNewDevice(
        context,
        type: type,
        deviceLabel: name,
      );
      if (!context.mounted) return;
      if (AppareilSpec.requiresPin(type) && pin == null) return;

      try {
        final devId = await _repo.addDevice(
          roomId: roomId,
          name: name,
          type: type,
          pin: pin,
        );
        if (context.mounted) {
          final pinNote = pin != null ? ', broche $pin' : '';
          final suffix = devId.isEmpty ? '' : ' (id: $devId)';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('« $name » ajouté$pinNote.$suffix')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(describePinError(e))),
          );
        }
      }
    } finally {
      nameCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = Firebase.apps.isNotEmpty;
    final l = context.l10n;

    final body = AdaptiveContent(
      padding: context.responsive.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            const _DashboardHeader(),
            const SizedBox(height: 10),
          ],
          Text(
            widget.houseTitlePrefix ?? l.myHouse,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.smartColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<bool>(
            stream: firebaseReady
                ? FirestoreHomeRepository.instance.watchHouseOnline()
                : null,
            initialData: false,
            builder: (context, onlineSnap) {
              final houseOnline = onlineSnap.data == true;
              final label = !firebaseReady
                  ? l.notConnected
                  : houseOnline
                      ? l.houseOnline
                      : l.houseOffline;
              final icon = !firebaseReady
                  ? Icons.wifi_off_rounded
                  : houseOnline
                      ? Icons.home_rounded
                      : Icons.home_outlined;
              final color = !firebaseReady
                  ? textSecondary
                  : houseOnline
                      ? successColor
                      : textSecondary;
              return Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          if (AuthService.instance.isMember)
            Text(
              l.memberModeHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.smartColors.textSecondary,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
          else if (_canAddDevices)
            Text(
              l.ownerHintAddDevices,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.smartColors.textSecondary,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              l.connectToControl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.smartColors.textSecondary,
                  ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: !firebaseReady
                ? RefreshIndicator(
                    onRefresh: _onDashboardPullRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.sizeOf(context).height - 320,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_off_outlined,
                                  size: 56,
                                  color: context.smartColors.textSecondary
                                      .withValues(alpha: 0.85),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l.firebaseNotInitialized,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          color:
                                              context.smartColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l.firebaseConfigureHint,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: context
                                              .smartColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : StreamBuilder<List<HouseRoom>>(
                    stream: _repo.watchRooms(),
                    initialData: const <HouseRoom>[],
                    builder: (context, roomSnap) {
                      if (roomSnap.hasError) {
                        return LoadErrorView(
                          message: '${roomSnap.error}',
                          onRetry: () => setState(() {}),
                        );
                      }
                      if (roomSnap.connectionState == ConnectionState.waiting &&
                          !roomSnap.hasData) {
                        return RefreshIndicator(
                          onRefresh: _onDashboardPullRefresh,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.only(top: 28),
                                    child: DeviceGridSkeleton(itemCount: 4),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }

                      return StreamBuilder<List<Device>>(
                        stream: _repo.watchDevices(),
                        initialData: const <Device>[],
                        builder: (context, devSnap) {
                          if (devSnap.hasError) {
                            return LoadErrorView(
                              message: '${devSnap.error}',
                              onRetry: () => setState(() {}),
                            );
                          }
                          final rooms = roomSnap.data ?? const <HouseRoom>[];
                          final devices = devSnap.data ?? const <Device>[];

                          if (rooms.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: _onDashboardPullRefresh,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight:
                                        MediaQuery.sizeOf(context).height - 320,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.meeting_room_outlined,
                                            size: 56,
                                            color: context
                                                .smartColors.textSecondary
                                                .withValues(alpha: 0.9),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            l.noRoomsYet,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: context
                                                      .smartColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            !_canAddRoom
                                                ? l.connectToAddRooms
                                                : '${l.addRoomFromMenu}'
                                                    '${_canFullManageDevices ? l.orLoadDemo : '.'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: context.smartColors
                                                      .textSecondary,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 22),
                                          if (_canFullManageDevices)
                                            FilledButton.tonal(
                                              onPressed: firebaseReady
                                                  ? () async {
                                                      try {
                                                        await FirestoreHomeRepository
                                                            .seedDemoHome();
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                context.l10n
                                                                    .demoDataAdded,
                                                              ),
                                                            ),
                                                          );
                                                        }
                                                      } catch (e) {
                                                        if (!context.mounted) {
                                                          return;
                                                        }
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                context.l10n
                                                                    .failureMessage(
                                                                        e)),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  : null,
                                              child: Text(
                                                l.createDemoData,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final waitingDevices = devSnap.connectionState ==
                                  ConnectionState.waiting &&
                              !devSnap.hasData;
                          if (waitingDevices) {
                            return RefreshIndicator(
                              onRefresh: _onDashboardPullRefresh,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.only(top: 28),
                                        child: DeviceGridSkeleton(itemCount: 4),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }

                          final filtered = _filteredDevices(devices, rooms);
                          if (filtered.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: _onDashboardPullRefresh,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight:
                                        MediaQuery.sizeOf(context).height - 320,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.devices_other_rounded,
                                            size: 52,
                                            color: context
                                                .smartColors.textSecondary
                                                .withValues(alpha: 0.85),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _allHouse
                                                ? l.noDevicesInHouse
                                                : l.noDevicesInRoom,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: context
                                                      .smartColors.textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _canAddDevices
                                                ? l.usePlusToAdd
                                                : l.noDevicesInRoom,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: context.smartColors
                                                      .textSecondary,
                                                ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: _onDashboardPullRefresh,
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: DashboardStatsPanel(
                                    stats: HomeDashboardStats.fromDevices(
                                      filtered,
                                    ),
                                    scopeLabel: _allHouse
                                        ? l.wholeHouse
                                        : _appBarTitle(context, rooms, firebaseReady),
                                  ),
                                ),
                                SliverPadding(
                                  padding: EdgeInsets.only(
                                    bottom: context.responsive.verticalPadding,
                                  ),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        context.responsive.deviceGridDelegate,
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final d = filtered[index];
                                        return DeviceCard(
                                          device: d,
                                          onCommand: (patch) async {
                                            try {
                                              await _repo.sendDeviceCommand(
                                                d.id,
                                                patch,
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    FirestoreHomeRepository
                                                        .describeFirebaseError(
                                                            e),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          onDelete: firebaseReady &&
                                                  _canFullManageDevices
                                              ? () => _confirmDeleteDevice(
                                                    context,
                                                    d,
                                                  )
                                              : null,
                                          onPinEdit: firebaseReady &&
                                                  _canAddDevices &&
                                                  (d.expectsPin ||
                                                      d.pin != null)
                                              ? () => _editDevicePin(context, d)
                                              : null,
                                          onMoveRoom: firebaseReady &&
                                                  _canAssignDevicesToRooms &&
                                                  rooms.isNotEmpty
                                              ? () => _moveDeviceToRoom(
                                                    context,
                                                    d,
                                                    rooms,
                                                  )
                                              : null,
                                        );
                                      },
                                      childCount: filtered.length,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    final appBarActions = <Widget>[
      if (!widget.embedded) const ThemeToggleButton(),
      if (_canAddDevices)
        StreamBuilder<List<HouseRoom>>(
          stream: firebaseReady
              ? _repo.watchRooms()
              : Stream.value(const <HouseRoom>[]),
          initialData: const <HouseRoom>[],
          builder: (context, snap) {
            final rooms = snap.data ?? const <HouseRoom>[];
            return IconButton(
              tooltip: l.addDevice,
              icon: Icon(Icons.add_rounded,
                  color: context.smartColors.textSecondary),
              onPressed: !firebaseReady || rooms.isEmpty
                  ? null
                  : () => _showAddDeviceSheet(context, rooms),
            );
          },
        ),
      StreamBuilder<List<HouseRoom>>(
        stream: firebaseReady
            ? _repo.watchRooms()
            : Stream.value(const <HouseRoom>[]),
        initialData: const <HouseRoom>[],
        builder: (context, snap) {
          final rooms = snap.data ?? const <HouseRoom>[];
          return IconButton(
            tooltip: l.pickRoomTooltip,
            icon: Icon(Icons.more_vert_rounded,
                color: context.smartColors.textSecondary),
            onPressed:
                !firebaseReady ? null : () => _showRoomPicker(context, rooms),
          );
        },
      ),
      if (!widget.embedded)
        IconButton(
          tooltip: l.logoutTooltip,
          icon: Icon(Icons.logout_rounded,
              color: context.smartColors.textSecondary),
          onPressed: () async {
            await AuthService.instance.clearSession();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            );
          },
        ),
    ];

    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<HouseRoom>>(
                    stream: firebaseReady
                        ? _repo.watchRooms()
                        : Stream.value(const <HouseRoom>[]),
                    initialData: const <HouseRoom>[],
                    builder: (context, snap) {
                      final rooms = snap.data ?? const <HouseRoom>[];
                      return Text(
                        _appBarTitle(context, rooms, firebaseReady),
                        style: TextStyle(
                          color: context.smartColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                ...appBarActions,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: StreamBuilder<List<HouseRoom>>(
          stream: firebaseReady
              ? _repo.watchRooms()
              : Stream.value(const <HouseRoom>[]),
          initialData: const <HouseRoom>[],
          builder: (context, snap) {
            final rooms = snap.data ?? const <HouseRoom>[];
            return Text(
              _appBarTitle(context, rooms, firebaseReady),
              style: TextStyle(
                color: context.smartColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        actions: appBarActions,
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: body,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StreamBuilder<String?>(
      stream: AuthService.instance.userNameStream(),
      builder: (context, snap) {
        final raw = snap.data?.trim();
        final name = (raw == null || raw.isEmpty) ? l.userDefault : raw;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.hello,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.smartColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: context.smartColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    Color.lerp(primaryColor, Colors.black, 0.18)!,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
