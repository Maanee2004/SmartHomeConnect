import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Carte appareil : UI selon [Device.normalizedType] (LIGHT, SENSOR_TEMP, FAN…).
class DeviceCard extends StatefulWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.onCommand,
    this.onDelete,
  });

  final Device device;
  final Future<void> Function(Map<String, dynamic> patch) onCommand;

  /// Si non null, affiche une action pour retirer l’appareil (ex. Firestore).
  final VoidCallback? onDelete;

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  double _fanSpeedDraft = 0;

  @override
  void initState() {
    super.initState();
    _fanSpeedDraft = widget.device.fanSpeed.toDouble();
  }

  @override
  void didUpdateWidget(DeviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.id != widget.device.id ||
        oldWidget.device.fanSpeed != widget.device.fanSpeed) {
      _fanSpeedDraft = widget.device.fanSpeed.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final d = widget.device;
    final online = d.isOnline;
    final t = d.normalizedType;
    final highlight =
        online && d.isActuatorOn && t != 'SENSOR_TEMP';

    return Opacity(
      opacity: online ? 1 : 0.55,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? accentColor.withValues(alpha: 0.5)
                : borderSubtle.withValues(alpha: 0.65),
            width: highlight ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_iconForType(t), color: c.textSecondary, size: 28),
                if (!online) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.cloud_off_outlined,
                    color: errorColor,
                    size: 22,
                    semanticLabel: 'Hors ligne',
                  ),
                ],
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!online)
                        Text(
                          'Hors ligne',
                          style: TextStyle(
                            color: errorColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    tooltip: 'Supprimer l’appareil',
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: errorColor.withValues(alpha: 0.9),
                      size: 22,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildControls(context, t, online),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, String t, bool online) {
    final d = widget.device;
    final c = context.smartColors;

    switch (t) {
      case 'SENSOR_TEMP':
        final temp = d.temperatureCelsius;
        final hum = d.humidityPercent;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat_rounded,
                    size: 22, color: c.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    temp != null ? '${temp.toStringAsFixed(1)} °C' : '— °C',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.water_drop_outlined,
                    size: 22, color: c.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hum != null ? '${hum.round()} % HR' : '— % HR',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case 'FAN':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Alimentation',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
                Switch.adaptive(
                  value: d.isOn,
                  onChanged: !online
                      ? null
                      : (v) => widget.onCommand({'isOn': v}),
                ),
              ],
            ),
            Text(
              'Vitesse',
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Slider(
              value: _fanSpeedDraft.clamp(0, 3),
              min: 0,
              max: 3,
              divisions: 3,
              label: _speedLabel(_fanSpeedDraft.round()),
              onChanged: !online || !d.isOn
                  ? null
                  : (v) => setState(() => _fanSpeedDraft = v),
              onChangeEnd: !online || !d.isOn
                  ? null
                  : (v) {
                      final n = v.round().clamp(0, 3);
                      widget.onCommand({'speed': n});
                    },
            ),
          ],
        );
      case 'CAMERA':
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              d.isOn ? 'Flux actif' : 'Flux coupé',
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
            Switch.adaptive(
              value: d.isOn,
              onChanged: !online
                  ? null
                  : (v) => widget.onCommand({'isOn': v}),
            ),
          ],
        );
      case 'OUTLET':
      case 'LIGHT':
      default:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              d.isOn ? 'Allumé' : 'Éteint',
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
            Switch.adaptive(
              value: d.isOn,
              onChanged: !online
                  ? null
                  : (v) => widget.onCommand({'isOn': v}),
            ),
          ],
        );
    }
  }

  static String _speedLabel(int s) {
    return switch (s) {
      0 => 'Arrêt',
      1 => '1',
      2 => '2',
      _ => '3',
    };
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'FAN':
        return Icons.air_rounded;
      case 'SENSOR_TEMP':
        return Icons.device_thermostat_outlined;
      case 'OUTLET':
        return Icons.power_rounded;
      case 'CAMERA':
        return Icons.videocam_rounded;
      case 'LIGHT':
        return Icons.lightbulb_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }
}
