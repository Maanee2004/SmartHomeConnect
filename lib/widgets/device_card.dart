import 'package:flutter/material.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

class DeviceCard extends StatelessWidget {
  final String name;
  final bool state;
  final VoidCallback onTap;

  const DeviceCard({
    super.key,
    required this.name,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final onBg = c.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: state ? c.card : c.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.textSecondary.withValues(alpha: 0.2)),
          boxShadow: state
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.35),
                    blurRadius: 15,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb,
              size: 40,
              color: state ? Colors.amber : c.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(color: onBg),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state ? 'ON' : 'OFF',
              style: TextStyle(
                color: state ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
