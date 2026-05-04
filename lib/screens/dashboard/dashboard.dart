import 'package:flutter/material.dart';
import 'package:smart_home/widgets/device_card.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  static const List<Map<String, dynamic>> devices = [
    {"name": "Lampe salon", "state": true},
    {"name": "Ventilateur", "state": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Smart Home"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1,
          children: devices.map((d) {
            return DeviceCard(
              name: d["name"] as String,
              state: d["state"] as bool,
              onTap: () {},
            );
          }).toList(),
        ),
      ),
    );
  }
}

