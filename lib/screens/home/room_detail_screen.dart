import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/l10n/app_localizations.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/services/home_repository.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/device_card.dart';

/// Appareils d’une pièce + déplacement vers une autre pièce.
class RoomDetailScreen extends StatefulWidget {
  RoomDetailScreen({
    super.key,
    required this.room,
    HomeRepository? repository,
    this.onBrowseOnDashboard,
  }) : repository = repository ?? FirestoreHomeRepository();

  final HouseRoom room;
  final HomeRepository repository;
  final void Function(String roomId)? onBrowseOnDashboard;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  bool get _canAssign =>
      AuthService.instance.canAssignDevicesToRooms;

  Future<void> _pickRoomAndMove(Device device, List<HouseRoom> rooms) async {
    final sorted = [...rooms]..sort((a, b) => a.name.compareTo(b.name));
    final roomId = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final l = ctx.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.pickRoomForDevice,
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
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
                          title: Text(r.name),
                          trailing: HouseRoom.deviceBelongsToRoom(device, r)
                              ? Icon(Icons.check_rounded, color: accentColor)
                              : null,
                          onTap: () => Navigator.pop(ctx, r.id),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (roomId == null || !mounted) return;
    if (HouseRoom.deviceBelongsToRoom(
      device,
      sorted.firstWhere((r) => r.id == roomId),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.deviceAlreadyInRoom)),
      );
      return;
    }
    try {
      await widget.repository.updateDevicePiece(device.id, roomId);
      if (!mounted) return;
      final label = sorted.firstWhere((r) => r.id == roomId).name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.deviceMoved(device.name, label))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(FirestoreHomeRepository.describeFirebaseError(e)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final l = context.l10n;

    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.room.name,
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (widget.onBrowseOnDashboard != null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onBrowseOnDashboard!(widget.room.id);
              },
              icon: Icon(Icons.dashboard_outlined, color: accentColor, size: 20),
              label: Text(
                l.navHome,
                style: TextStyle(color: accentColor),
              ),
            ),
        ],
      ),
      body: StreamBuilder<List<HouseRoom>>(
        stream: widget.repository.watchRooms(),
        initialData: const <HouseRoom>[],
        builder: (context, roomSnap) {
          final rooms = roomSnap.data ?? const <HouseRoom>[];
          return StreamBuilder<List<Device>>(
            stream: widget.repository.watchDevices(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    l.failureMessage(snapshot.error!),
                    style: TextStyle(color: errorColor),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snapshot.data ?? const [];
              final inRoom = all
                  .where(
                    (d) => HouseRoom.deviceBelongsToRoom(d, widget.room),
                  )
                  .toList(growable: false);

              if (inRoom.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.devices_other_outlined,
                          size: 48,
                          color: c.textSecondary.withValues(alpha: 0.85),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.noDevicesInRoom,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _canAssign
                              ? l.usePlusToAdd
                              : l.connectToControl,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: inRoom.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = inRoom[i];
                  return DeviceCard(
                    device: d,
                    onCommand: (patch) =>
                        widget.repository.sendDeviceCommand(d.id, patch),
                    onMoveRoom: _canAssign && rooms.isNotEmpty
                        ? () => _pickRoomAndMove(d, rooms)
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
