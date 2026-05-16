import 'package:flutter/material.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/widgets/device_card.dart';

/// Ancienne démo grille — préférer [DashboardScreen] (liste pièces).
class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  static final List<Device> devices = [
    Device(
      id: 'd1',
      name: 'Lampe salon',
      roomId: 'r1',
      type: 'LIGHT',
      state: const {'isOn': true},
    ),
    Device(
      id: 'd2',
      name: 'Ventilateur',
      roomId: 'r1',
      type: 'FAN',
      state: const {'isOn': false, 'speed': 0},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Smart Home (démo)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: devices
            .map(
              (d) => DeviceCard(
                device: d,
                onCommand: (_) async {},
              ),
            )
            .toList(),
      ),
    );
  }
}
