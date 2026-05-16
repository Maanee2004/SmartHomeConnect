import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/services/home_repository.dart';
import 'package:smart_home/widgets/device_card.dart';

/// Liste des appareils d’une pièce.
class RoomDetailScreen extends StatelessWidget {
  RoomDetailScreen({
    super.key,
    required this.room,
    HomeRepository? repository,
  }) : repository = repository ?? FirestoreHomeRepository();

  final HouseRoom room;
  final HomeRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          room.name,
          style: const TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: textSecondary),
      ),
      body: StreamBuilder<List<Device>>(
        stream: repository.watchDevices(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur: ${snapshot.error}',
                style: const TextStyle(color: errorColor),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? const [];
          final inRoom =
              all.where((d) => d.roomId == room.id).toList(growable: false);

          if (inRoom.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucun appareil dans cette pièce.\n'
                  'Ajoute des documents dans la collection `devices` avec le champ `roomId` = "${room.id}".',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: inRoom.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) {
              final d = inRoom[i];
              return DeviceCard(
                device: d,
                onCommand: (patch) => repository.sendDeviceCommand(d.id, patch),
              );
            },
          );
        },
      ),
    );
  }
}
