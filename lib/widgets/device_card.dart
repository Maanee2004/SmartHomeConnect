import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Carte appareil : nom [label], type Arduino, lecture capteur ou commande actionneur.
class DeviceCard extends StatefulWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.onCommand,
    this.onDelete,
    this.onPinEdit,
  });

  final Device device;
  final Future<void> Function(Map<String, dynamic> patch) onCommand;
  final VoidCallback? onDelete;
  final VoidCallback? onPinEdit;

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final d = widget.device;
    final online = d.isOnline;
    final t = d.normalizedType;
    final isSensor = d.isCapteur;
    final highlight = !isSensor && online && d.isActuatorOn;

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
                : c.planBorder.withValues(alpha: 0.65),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconForType(t), color: accentColor, size: 28),
                if (!online) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.cloud_off_outlined,
                    color: errorColor,
                    size: 20,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _metaLine(d),
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!online)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Hors ligne',
                            style: TextStyle(color: errorColor, fontSize: 12),
                          ),
                        ),
                      if (d.pin != null || d.expectsPin || widget.onPinEdit != null)
                        _PinBadge(
                          pin: d.pin,
                          required: d.expectsPin,
                          onEdit: widget.onPinEdit,
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
            _buildControls(context, online, isSensor),
          ],
        ),
      ),
    );
  }

  static String _metaLine(Device d) {
    final parts = <String>[];
    if (d.isMergedDhtPair) {
      parts.addAll(['DHT_TEMP', 'DHT_HUM']);
    } else {
      parts.add(d.type);
    }
    final piece = d.piece?.trim();
    if (piece != null && piece.isNotEmpty) parts.add(piece);
    parts.add(d.isCapteur ? 'capteur' : 'actionneur');
    return parts.join(' · ');
  }

  Widget _buildControls(BuildContext context, bool online, bool isSensor) {
    final d = widget.device;
    final c = context.smartColors;

    if (isSensor) {
      return _buildSensorPanel(context, d, c);
    }

    if (d.normalizedType == 'SERVO') {
      return _buildServoPanel(d, c, online);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          d.isOn ? 'Allumé' : 'Éteint',
          style: TextStyle(color: c.textSecondary, fontSize: 14),
        ),
        Switch.adaptive(
          value: d.isOn,
          onChanged:
              !online ? null : (v) => widget.onCommand({'isOn': v}),
        ),
      ],
    );
  }

  Widget _buildSensorPanel(BuildContext context, Device d, SmartHomeColors c) {
    final t = d.normalizedType;

    if (d.isDhtDisplay) {
      return _buildDhtPanel(d, c);
    }
    if (t == 'PIR') {
      final motion = (d.valeur ?? 0) != 0;
      return _buildMetricPanel(
        c: c,
        label: 'Mouvement',
        value: motion ? 'Détecté' : 'Aucun',
        icon: Icons.sensors_rounded,
        highlight: motion,
      );
    }
    if (t == 'RFID') {
      final badge = d.rfidBadgeUid;
      return _buildMetricPanel(
        c: c,
        label: 'Badge RFID',
        value: badge ?? 'En attente',
        icon: Icons.nfc_rounded,
        highlight: badge != null,
      );
    }
    if (t == 'DHT_TEMP') {
      final temp = d.temperatureCelsius;
      return _buildMetricPanel(
        c: c,
        label: 'Température',
        value: temp != null ? '${temp.toStringAsFixed(1)} °C' : '— °C',
        icon: Icons.device_thermostat_outlined,
      );
    }
    if (t == 'DHT_HUM') {
      final hum = d.humidityPercent;
      return _buildMetricPanel(
        c: c,
        label: 'Humidité',
        value: hum != null ? '${hum.round()} %' : '— %',
        icon: Icons.water_drop_outlined,
      );
    }

    final raw = d.valeur;
    final u = d.unit?.trim();
    final text = raw is num
        ? (u != null && u.isNotEmpty ? '$raw $u' : '$raw')
        : '—';
    return _buildMetricPanel(
      c: c,
      label: 'Mesure',
      value: text,
      icon: Icons.sensors_outlined,
    );
  }

  Widget _buildServoPanel(Device d, SmartHomeColors c, bool online) {
    final angle = d.servoAngle.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (d.rfidCible != null && d.rfidCible!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'rfid_cible: ${d.rfidCible}',
              style: TextStyle(color: c.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        Text(
          'Angle : ${angle.round()}°',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
        ),
        Slider(
          value: angle.clamp(0, 180),
          min: 0,
          max: 180,
          divisions: 18,
          label: '${angle.round()}°',
          onChanged: !online
              ? null
              : (v) => widget.onCommand({'angle': v.round()}),
        ),
      ],
    );
  }

  Widget _buildDhtPanel(Device d, SmartHomeColors c) {
    final temp = d.temperatureCelsius;
    final hum = d.humidityPercent;
    final waiting = temp == null && hum == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: waiting
          ? Text(
              'En attente de mesures DHT…',
              style: TextStyle(color: c.textSecondary, fontSize: 13),
            )
          : Row(
              children: [
                Expanded(
                  child: _dhtMetric(
                    c: c,
                    icon: Icons.device_thermostat_outlined,
                    label: 'Temp.',
                    value: temp != null
                        ? '${temp.toStringAsFixed(1)} °C'
                        : '— °C',
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: c.planBorder.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _dhtMetric(
                    c: c,
                    icon: Icons.water_drop_outlined,
                    label: 'Hum.',
                    value:
                        hum != null ? '${hum.round()} %' : '— %',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _dhtMetric({
    required SmartHomeColors c,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricPanel({
    required SmartHomeColors c,
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: highlight ? accentColor : c.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: highlight ? accentColor : c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'DHT_PAIR':
      case 'DHT22':
      case 'DHT_TEMP':
        return Icons.device_thermostat_outlined;
      case 'DHT_HUM':
        return Icons.water_drop_outlined;
      case 'PIR':
        return Icons.sensors_rounded;
      case 'LED':
        return Icons.highlight_rounded;
      case 'RELAIS':
        return Icons.power_settings_new_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge({
    required this.pin,
    required this.required,
    this.onEdit,
  });

  final int? pin;
  final bool required;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final missing = pin == null && required;
    final label =
        pin != null ? 'Broche $pin' : (required ? 'Broche requise' : 'Broche —');
    final color = missing ? warningColor : c.textSecondary;

    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.memory_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (onEdit != null) ...[
          const SizedBox(width: 2),
          Icon(Icons.edit_outlined, size: 13, color: accentColor),
        ],
      ],
    );

    if (onEdit == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: chip,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: chip,
        ),
      ),
    );
  }
}
