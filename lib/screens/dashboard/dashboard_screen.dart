import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/models/appareil_spec.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';
import 'package:smart_home/screens/auth/login_screen.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/services/home_repository.dart';
import 'package:smart_home/theme/room_icons.dart';
import 'package:smart_home/widgets/device_card.dart';
import 'package:smart_home/widgets/device_grid_skeleton.dart';
import 'package:smart_home/widgets/load_error_view.dart';
import 'package:smart_home/widgets/pin_picker_dialog.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

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
  });

  final Widget? bottomNavigationBar;
  final VoidCallback? onGoHome;

  /// `false` par défaut pour admin ; `true` pour utilisateurs standards.
  final bool? readOnly;

  final bool showHeader;
  final String? houseTitlePrefix;
  final bool embedded;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static final HomeRepository _repo = FirestoreHomeRepository();

  bool get _devicesReadOnly =>
      widget.readOnly ?? !AuthService.instance.canManageDevices;

  bool get _canAddRoom =>
      AuthService.instance.canAddRooms && Firebase.apps.isNotEmpty;

  /// `true` = afficher tous les appareils, titre « Toute la maison ».
  bool _allHouse = false;

  /// Pièce explicitement choisie dans le menu ; `null` = règle par défaut (Salon ou 1ʳᵉ pièce).
  String? _pickedRoomId;

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

  String _appBarTitle(List<HouseRoom> rooms, bool firebaseReady) {
    if (!firebaseReady) return 'Smart Home';
    if (rooms.isEmpty) return 'Ma maison';
    if (_allHouse) return 'Toute la maison';
    final id = _effectiveRoomId(rooms);
    for (final r in rooms) {
      if (r.id == id) return r.name;
    }
    return 'Salon';
  }

  List<Device> _filteredDevices(List<Device> all, List<HouseRoom> rooms) {
    if (_allHouse) return all;
    final id = _effectiveRoomId(rooms);
    if (id.isEmpty) return [];
    return all.where((d) => d.roomId == id).toList();
  }

  Future<void> _onDashboardPullRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
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
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.smartColors.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Afficher les appareils',
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
                    ListTile(
                      leading:
                          Icon(Icons.home_work_outlined, color: accentColor),
                      title: Text(
                        'Toute la maison',
                        style: TextStyle(color: context.smartColors.textPrimary),
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
                    ...sorted.map(
                      (r) => ListTile(
                        leading: Icon(
                          roomIconFromName(r.name),
                          color: context.smartColors.textSecondary,
                        ),
                        title: Text(
                          r.name,
                          style: TextStyle(color: context.smartColors.textPrimary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_allHouse &&
                                _effectiveRoomId(rooms) == r.id)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: accentColor,
                                ),
                              ),
                            if (!_devicesReadOnly)
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: errorColor.withValues(alpha: 0.9),
                                  size: 22,
                                ),
                                tooltip: 'Supprimer la pièce',
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
                          'Ajouter une pièce',
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
    final controller = TextEditingController();
    String? name;
    try {
      name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Nouvelle pièce',
            style: TextStyle(color: context.smartColors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: context.smartColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Nom de la pièce',
              hintStyle: TextStyle(color: context.smartColors.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                Navigator.pop(ctx, t.isEmpty ? null : t);
              },
              child: Text('Ajouter'),
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
          SnackBar(content: Text('Pièce « $name » ajoutée.$suffix')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteDevice(BuildContext context, Device device) async {
    if (!Firebase.apps.isNotEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Supprimer « ${device.name} » ?',
          style: TextStyle(color: context.smartColors.textPrimary),
        ),
        content: Text(
          'L’appareil sera retiré de Firestore.',
          style: TextStyle(color: context.smartColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer'),
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
          SnackBar(content: Text('« ${device.name} » supprimé.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec: $e')),
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
    final ok = await showDialog<bool>(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Supprimer « ${room.name} » ?',
          style: TextStyle(color: context.smartColors.textPrimary),
        ),
        content: Text(
          'La pièce et tous ses appareils seront retirés de Firestore.',
          style: TextStyle(color: context.smartColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer'),
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
        SnackBar(content: Text('Pièce « ${room.name} » supprimée.')),
      );
    } catch (e) {
      if (messengerContext.mounted) {
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(content: Text('Échec: $e')),
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
                color: context.smartColors.textSecondary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Placer dans quelle pièce ?',
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
                          style: TextStyle(color: context.smartColors.textPrimary),
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
    return showPinPickerDialog(
      context,
      repo: _repo,
      required: needsPin,
      title: needsPin ? 'Broche GPIO (obligatoire)' : 'Broche GPIO (optionnel)',
      subtitle:
          '$deviceLabel — broches ${AppareilSpec.minPin}–${AppareilSpec.maxPin}',
    );
  }

  Future<void> _editDevicePin(BuildContext context, Device device) async {
    final pin = await showPinPickerDialog(
      context,
      repo: _repo,
      required: device.expectsPin,
      currentPin: device.pin,
      title: 'Modifier la broche',
      subtitle: device.name,
    );
    if (pin == null || !context.mounted) return;
    try {
      await _repo.updateDevicePin(device.id, pin);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Broche $pin assignée à « ${device.name} ».')),
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
    if (readers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoute d’abord un lecteur RFID (type RFID).'),
        ),
      );
      return;
    }

    final roomId = await _resolveTargetRoomId(context, rooms);
    if (roomId == null || !context.mounted) return;

    final rfidId = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(
          'Lecteur RFID lié',
          style: TextStyle(color: context.smartColors.textPrimary),
        ),
        children: [
          for (final r in readers)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, r.id),
              child: Text('${r.name} (${r.id})'),
            ),
        ],
      ),
    );
    if (rfidId == null || !context.mounted) return;

    final pin = await showPinPickerDialog(
      context,
      repo: _repo,
      required: true,
      title: 'Broche du servomoteur',
      subtitle: 'rfid_cible → $rfidId',
    );
    if (pin == null || !context.mounted) return;

    try {
      await _repo.addDevice(
        roomId: roomId,
        name: 'Servo porte',
        type: 'SERVO',
        pin: pin,
        rfidCible: rfidId,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Servo ajouté (rfid_cible: $rfidId, broche $pin).'),
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
    final roomId = await _resolveTargetRoomId(context, rooms);
    if (roomId == null || !context.mounted) return;

    final pin = await showPinPickerDialog(
      context,
      repo: _repo,
      required: true,
      title: 'Broche du capteur DHT',
      subtitle:
          'Un doc : température et humidité dans valeur (ex. 24.5/60)',
    );
    if (pin == null || !context.mounted) return;

    try {
      await _repo.addDhtSensor(roomId: roomId, pin: pin);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Capteur DHT ajouté (valeur temp./hum., broche $pin).',
          ),
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
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.smartColors.textSecondary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Ajouter un appareil',
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
                      'Tu affiches « Toute la maison » : on te demandera la pièce pour chaque ajout.',
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
                        'Types enregistrés en MAJUSCULES (Arduino CONFIG).',
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: context.smartColors.textSecondary,
                            ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Capteurs',
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
                        style: TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type DHT22 — temp. et humidité dans valeur',
                        style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
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
                        style: TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type: PIR — mouvement 0/1',
                        style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
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
                        style: TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type: RFID — unit: string',
                        style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addRfidReader(context, rooms);
                      },
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Actionneurs',
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
                        'Lampe / prise',
                        style: TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type: RELAIS — enregistré RELAIS en base',
                        style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addQuickDevice(context, rooms,
                            name: 'Lampe', type: 'RELAIS');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.air_rounded, color: accentColor),
                      title: Text(
                        'Ventilateur',
                        style: TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type: RELAIS — relais ON/OFF',
                        style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addQuickDevice(context, rooms,
                            name: 'Ventilateur', type: 'RELAIS');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.highlight_rounded, color: accentColor),
                      title: Text(
                        'LED',
                        style: TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type: LED — broche directe',
                        style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _addQuickDevice(context, rooms,
                            name: 'LED', type: 'LED');
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.door_sliding_rounded, color: accentColor),
                      title: Text(
                        'Servo porte',
                        style: TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'type: SERVO — rfid_cible obligatoire',
                        style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
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
                        'Ajouter un appareil personnalisé…',
                        style: TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        'Nom, type et pièce au choix',
                        style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
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
                'Appareil personnalisé',
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
                        labelText: 'Nom',
                        labelStyle: TextStyle(color: context.smartColors.textSecondary),
                        hintText: 'ex. Lampe bureau',
                        hintStyle: TextStyle(color: context.smartColors.textSecondary),
                      ),
                    ),
                    Text(
                      'Type',
                      style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
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
                      'Pièce',
                      style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
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
                  child: Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Ajouter'),
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
          const SnackBar(content: Text('Indique un nom.')),
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

    final body = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader) ...[
              const _DashboardHeader(),
              const SizedBox(height: 10),
            ],
            Text(
              widget.houseTitlePrefix ?? 'Ma maison',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.smartColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  firebaseReady ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: firebaseReady ? accentColor : textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  firebaseReady ? 'Connecté' : 'Non connecté',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: firebaseReady ? accentColor : textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_devicesReadOnly)
              Text(
                'Utilise le menu ⋮ pour choisir la pièce et le bouton + pour les appareils',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.smartColors.textSecondary,
                    ),
              )
            else if (_canAddRoom)
              Text(
                'Ajoute des pièces via le menu ⋮. Les appareils sont gérés par l’admin.',
              )
            else
              Text(
                'Mode consultation : allume/éteins les appareils.',
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
                                    color: context.smartColors.textSecondary.withValues(alpha: 0.85),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Firebase n’est pas initialisé.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: context.smartColors.textPrimary),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Configure le projet (flutterfire configure) puis relance l’app.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: context.smartColors.textSecondary),
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
                      builder: (context, roomSnap) {
                        if (roomSnap.hasError) {
                          return LoadErrorView(
                            message: '${roomSnap.error}',
                            onRetry: () => setState(() {}),
                          );
                        }
                        if (roomSnap.connectionState ==
                                ConnectionState.waiting &&
                            !roomSnap.hasData) {
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

                        return StreamBuilder<List<Device>>(
                          stream: _repo.watchDevices(),
                          builder: (context, devSnap) {
                            if (devSnap.hasError) {
                              return LoadErrorView(
                                message: '${devSnap.error}',
                                onRetry: () => setState(() {}),
                              );
                            }
                            final rooms =
                                roomSnap.data ?? const <HouseRoom>[];
                            final devices =
                                devSnap.data ?? const <Device>[];

                            if (rooms.isEmpty) {
                              return RefreshIndicator(
                                onRefresh: _onDashboardPullRefresh,
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight:
                                          MediaQuery.sizeOf(context).height -
                                              320,
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
                                              color: context.smartColors.textSecondary
                                                  .withValues(alpha: 0.9),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Aucune pièce pour l’instant.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: context.smartColors.textPrimary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              !_canAddRoom
                                                  ? 'Connecte-toi pour ajouter des pièces.'
                                                  : 'Ajoute une pièce depuis le menu ⋮'
                                                      '${_devicesReadOnly ? '.' : ' ou charge les données de démo.'}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: context.smartColors.textSecondary,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 22),
                                            if (!_devicesReadOnly)
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
                                                            const SnackBar(
                                                              content: Text(
                                                                'Données de démo ajoutées.',
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
                                                                'Échec: $e'),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  : null,
                                              child: Text(
                                                'Créer des données de démo (Firestore)',
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
                                devSnap.data == null;
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
                                          child:
                                              DeviceGridSkeleton(itemCount: 4),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }

                            final filtered =
                                _filteredDevices(devices, rooms);
                            if (filtered.isEmpty) {
                              return RefreshIndicator(
                                onRefresh: _onDashboardPullRefresh,
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight:
                                          MediaQuery.sizeOf(context).height -
                                              320,
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
                                              color: context.smartColors.textSecondary
                                                  .withValues(alpha: 0.85),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _allHouse
                                                  ? 'Aucun appareil dans la maison.'
                                                  : 'Aucun appareil dans cette pièce.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    color: context.smartColors.textPrimary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _devicesReadOnly
                                                  ? 'Aucun appareil dans cette pièce.'
                                                  : 'Utilise le bouton + pour en ajouter un.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: context.smartColors.textSecondary,
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
                              child: GridView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemBuilder: (context, index) {
                                  final d = filtered[index];
                                  return DeviceCard(
                                    device: d,
                                    onCommand: (patch) => _repo
                                        .sendDeviceCommand(d.id, patch),
                                    onDelete: firebaseReady && !_devicesReadOnly
                                        ? () =>
                                            _confirmDeleteDevice(context, d)
                                        : null,
                                    onPinEdit: firebaseReady &&
                                            !_devicesReadOnly &&
                                            (d.expectsPin || d.pin != null)
                                        ? () => _editDevicePin(context, d)
                                        : null,
                                  );
                                },
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
      if (!_devicesReadOnly)
        StreamBuilder<List<HouseRoom>>(
          stream: firebaseReady
              ? _repo.watchRooms()
              : Stream.value(const <HouseRoom>[]),
          initialData: const <HouseRoom>[],
          builder: (context, snap) {
            final rooms = snap.data ?? const <HouseRoom>[];
            return IconButton(
              tooltip: 'Ajouter un appareil',
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
            tooltip: 'Choisir la pièce',
            icon: Icon(Icons.more_vert_rounded,
                color: context.smartColors.textSecondary),
            onPressed: !firebaseReady || rooms.isEmpty
                ? null
                : () => _showRoomPicker(context, rooms),
          );
        },
      ),
      if (!widget.embedded)
        IconButton(
          tooltip: 'Se déconnecter',
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
                        _appBarTitle(rooms, firebaseReady),
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
              _appBarTitle(rooms, firebaseReady),
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
    return StreamBuilder<String?>(
      stream: AuthService.instance.userNameStream(),
      builder: (context, snap) {
        final raw = snap.data?.trim();
        final name = (raw == null || raw.isEmpty) ? 'Utilisateur' : raw;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour',
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
