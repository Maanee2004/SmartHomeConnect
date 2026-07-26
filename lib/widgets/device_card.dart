import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/l10n/app_localizations.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Carte appareil : nom [label], type Arduino, lecture capteur ou commande actionneur.
class DeviceCard extends StatefulWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.onCommand,
    this.onDelete,
    this.onPinEdit,
    this.onMoveRoom,
  });

  final Device device;
  final Future<void> Function(Map<String, dynamic> patch) onCommand;
  final VoidCallback? onDelete;
  final VoidCallback? onPinEdit;
  final VoidCallback? onMoveRoom;

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool? _optimisticOn;

  @override
  void didUpdateWidget(DeviceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_optimisticOn != null && widget.device.isOn == _optimisticOn) {
      _optimisticOn = null;
    }
  }

  bool _actuatorOn(Device d) => _optimisticOn ?? d.isOn;

  void _sendActuatorCommand(bool on) {
    setState(() => _optimisticOn = on);
    widget.onCommand({'isOn': on}).catchError((_) {
      if (mounted) setState(() => _optimisticOn = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = context.responsive;
        final tight = constraints.maxWidth < 210 || constraints.maxHeight < 300;
        return _buildCard(context, r, tight: tight);
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    ResponsiveLayout r, {
    required bool tight,
  }) {
    final c = context.smartColors;
    final d = widget.device;
    final online = d.isOnline;
    final t = d.normalizedType;
    final isSensor = d.isCapteur;
    final highlight = !isSensor && online && _actuatorOn(d);
    final padH = tight ? r.scale(10) : r.scale(14);
    final padV = tight ? r.scale(10) : r.scale(12);
    final titleSize = tight ? r.fontSize(14) : r.fontSize(16);
    final metaSize = tight ? r.fontSize(10) : r.fontSize(11);

    final brightness = Theme.of(context).brightness;

    return Opacity(
      opacity: online ? 1 : 0.55,
      child: AnimatedContainer(
        key: ValueKey(brightness),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(vertical: tight ? 2 : r.scale(4)),
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _iconForType(t),
                  color: accentColor,
                  size: tight ? r.iconSize(22) : r.iconSize(26),
                ),
                if (!online) ...[
                  SizedBox(width: tight ? 4 : 6),
                  Icon(
                    Icons.cloud_off_outlined,
                    color: errorColor,
                    size: tight ? r.iconSize(16) : r.iconSize(18),
                    semanticLabel: context.l10n.offline,
                  ),
                ],
                SizedBox(width: tight ? 8 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: titleSize,
                        ),
                        maxLines: tight ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: tight ? 1 : 2),
                      Text(
                        _metaLine(context, d),
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: metaSize,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: tight ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!online && !tight)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            context.l10n.offline,
                            style: TextStyle(
                              color: errorColor,
                              fontSize: r.fontSize(11),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (d.pin != null ||
                          d.expectsPin ||
                          widget.onPinEdit != null)
                        _PinBadge(
                          pin: d.pin,
                          required: d.expectsPin,
                          onEdit: widget.onPinEdit,
                          compact: tight,
                        ),
                    ],
                  ),
                ),
                if (widget.onMoveRoom != null || widget.onDelete != null)
                  _ActionButtons(
                    tight: tight,
                    onMoveRoom: widget.onMoveRoom,
                    onDelete: widget.onDelete,
                    textSecondary: c.textSecondary,
                  ),
              ],
            ),
            SizedBox(height: tight ? 8 : 10),
            _buildControls(
              context,
              online,
              isSensor,
              tight: tight,
            ),
          ],
        ),
      ),
    );
  }

  static String _metaLine(BuildContext context, Device d) {
    final l = context.l10n;
    final parts = <String>[];
    if (d.isMergedDhtPair) {
      parts.addAll(['DHT_TEMP', 'DHT_HUM']);
    } else {
      parts.add(d.type);
    }
    final piece = d.piece?.trim();
    if (piece != null && piece.isNotEmpty) parts.add(piece);
    parts.add(d.isCapteur ? l.sensorMeta : l.actuatorMeta);
    return parts.join(' · ');
  }

  Widget _buildControls(
    BuildContext context,
    bool online,
    bool isSensor, {
    required bool tight,
  }) {
    final d = widget.device;
    final c = context.smartColors;
    final r = context.responsive;
    final labelSize = tight ? r.fontSize(12) : r.fontSize(14);

    if (isSensor) {
      return _buildSensorPanel(context, d, c, tight: tight);
    }

    if (d.normalizedType == 'SERVO') {
      return _buildServoPanel(context, d, c, tight: tight);
    }

    final l = context.l10n;
    final stateLabel = d.normalizedType == 'MAX'
        ? (_actuatorOn(d) ? l.stateActive : l.stateOff)
        : (_actuatorOn(d) ? l.stateOn : l.stateOff);

    return _LabeledSwitchRow(
      label: stateLabel,
      value: _actuatorOn(d),
      labelSize: labelSize,
      textColor: c.textSecondary,
      onChanged: _sendActuatorCommand,
      compact: tight,
    );
  }

  Widget _buildSensorPanel(
    BuildContext context,
    Device d,
    SmartHomeColors c, {
    required bool tight,
  }) {
    final t = d.normalizedType;

    if (d.isDhtDisplay) {
      return _buildDhtPanel(context, d, c, tight: tight);
    }
    final l = context.l10n;
    if (t == 'PIR') {
      final motion = (d.valeur ?? 0) != 0;
      return _buildMetricPanel(
        c: c,
        label: l.motion,
        value: motion ? l.motionDetected : l.motionNone,
        icon: Icons.sensors_rounded,
        highlight: motion,
        compact: tight,
      );
    }
    if (t == 'RFID') {
      final badge = d.rfidBadgeUid;
      return _buildMetricPanel(
        c: c,
        label: l.badgeUid,
        value: badge ?? l.waiting,
        icon: Icons.nfc_rounded,
        highlight: badge != null,
        compact: tight,
      );
    }
    if (t == 'ULTRA') {
      final dist = d.distanceCm;
      return _buildMetricPanel(
        c: c,
        label: l.distance,
        value: dist != null ? '${dist.toStringAsFixed(0)} cm' : '— cm',
        icon: Icons.straighten_rounded,
        highlight: dist != null && dist < 30,
        compact: tight,
      );
    }
    if (t == 'DHT_TEMP') {
      final temp = d.temperatureCelsius;
      return _buildMetricPanel(
        c: c,
        label: l.temperature,
        value: temp != null ? '${temp.toStringAsFixed(1)} °C' : '— °C',
        icon: Icons.device_thermostat_outlined,
        compact: tight,
      );
    }
    if (t == 'DHT_HUM') {
      final hum = d.humidityPercent;
      return _buildMetricPanel(
        c: c,
        label: l.humidity,
        value: hum != null ? '${hum.round()} %' : '— %',
        icon: Icons.water_drop_outlined,
        compact: tight,
      );
    }

    final raw = d.valeur;
    final u = d.unit?.trim();
    final text =
        raw is num ? (u != null && u.isNotEmpty ? '$raw $u' : '$raw') : '—';
    return _buildMetricPanel(
      c: c,
      label: l.measurement,
      value: text,
      icon: Icons.sensors_outlined,
      compact: tight,
    );
  }

  Widget _buildServoPanel(
    BuildContext context,
    Device d,
    SmartHomeColors c, {
    required bool tight,
  }) {
    final l = context.l10n;
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (d.rfidCible != null && d.rfidCible!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l.rfidTarget(d.rfidCible!),
              style:
                  TextStyle(color: c.textSecondary, fontSize: r.fontSize(10)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        _LabeledSwitchRow(
          label: _actuatorOn(d) ? l.doorOpen : l.doorClosed,
          value: _actuatorOn(d),
          labelSize: tight ? r.fontSize(12) : r.fontSize(14),
          textColor: c.textPrimary,
          onChanged: _sendActuatorCommand,
          compact: tight,
          bold: true,
        ),
      ],
    );
  }

  Widget _buildDhtPanel(
    BuildContext context,
    Device d,
    SmartHomeColors c, {
    required bool tight,
  }) {
    final l = context.l10n;
    final temp = d.temperatureCelsius;
    final hum = d.humidityPercent;
    final waiting = temp == null && hum == null;
    final r = context.responsive;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tight ? 6 : 10,
        vertical: tight ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: waiting
          ? Text(
              l.waitingDht,
              style:
                  TextStyle(color: c.textSecondary, fontSize: r.fontSize(12)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Row(
              children: [
                Expanded(
                  child: _dhtMetric(
                    c: c,
                    icon: Icons.device_thermostat_outlined,
                    label: 'Temp.',
                    value:
                        temp != null ? '${temp.toStringAsFixed(1)} °C' : '— °C',
                    compact: tight,
                  ),
                ),
                Container(
                  width: 1,
                  height: tight ? 28 : 36,
                  color: c.planBorder.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _dhtMetric(
                    c: c,
                    icon: Icons.water_drop_outlined,
                    label: 'Hum.',
                    value: hum != null ? '${hum.round()} %' : '— %',
                    compact: tight,
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
    required bool compact,
  }) {
    final r = context.responsive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 16 : 20, color: accentColor),
        SizedBox(height: compact ? 2 : 4),
        Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: r.fontSize(compact ? 9 : 10),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: r.fontSize(compact ? 14 : 18),
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
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
    required bool compact,
  }) {
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: c.inputFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: compact ? 18 : 22,
            color: highlight ? accentColor : c.textSecondary,
          ),
          SizedBox(width: compact ? 6 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: r.fontSize(compact ? 10 : 11),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: r.fontSize(compact ? 14 : 18),
                      fontWeight: FontWeight.w600,
                      color: highlight ? accentColor : c.textPrimary,
                    ),
                    maxLines: 1,
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
      case 'DHT':
      case 'DHT22':
      case 'DHT_TEMP':
        return Icons.device_thermostat_outlined;
      case 'DHT_HUM':
        return Icons.water_drop_outlined;
      case 'PIR':
        return Icons.sensors_rounded;
      case 'RFID':
        return Icons.nfc_rounded;
      case 'ULTRA':
        return Icons.straighten_rounded;
      case 'SERVO':
        return Icons.door_sliding_rounded;
      case 'MAX':
        return Icons.grid_on_rounded;
      case 'LAMPE':
        return Icons.lightbulb_outline;
      case 'MOTEUR':
        return Icons.precision_manufacturing_outlined;
      case 'LED':
        return Icons.highlight_rounded;
      case 'RELAIS':
        return Icons.power_settings_new_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.tight,
    this.onMoveRoom,
    this.onDelete,
    required this.textSecondary,
  });

  final bool tight;
  final VoidCallback? onMoveRoom;
  final VoidCallback? onDelete;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final size = tight ? 18.0 : 20.0;
    final min = tight ? 28.0 : 32.0;

    if (tight && onMoveRoom != null && onDelete != null) {
      return PopupMenuButton<String>(
        icon: Icon(Icons.more_vert_rounded, color: textSecondary, size: size),
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(minWidth: min, minHeight: min),
        onSelected: (v) {
          if (v == 'move') onMoveRoom?.call();
          if (v == 'delete') onDelete?.call();
        },
        itemBuilder: (ctx) => [
          if (onMoveRoom != null)
            PopupMenuItem(
              value: 'move',
              child: Text(ctx.l10n.changeRoom),
            ),
          if (onDelete != null)
            PopupMenuItem(
              value: 'delete',
              child: Text(ctx.l10n.delete),
            ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onMoveRoom != null)
          IconButton(
            tooltip: context.l10n.changeRoomTooltip,
            icon: Icon(Icons.move_up_rounded, color: textSecondary, size: size),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: min, minHeight: min),
            onPressed: onMoveRoom,
          ),
        if (onDelete != null)
          IconButton(
            tooltip: context.l10n.deleteDeviceTooltip,
            icon: Icon(Icons.delete_outline_rounded,
                color: errorColor.withValues(alpha: 0.9), size: size),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: min, minHeight: min),
            onPressed: onDelete,
          ),
      ],
    );
  }
}

class _LabeledSwitchRow extends StatelessWidget {
  const _LabeledSwitchRow({
    required this.label,
    required this.value,
    required this.labelSize,
    required this.textColor,
    required this.onChanged,
    this.compact = false,
    this.bold = false,
  });

  final String label;
  final bool value;
  final double labelSize;
  final Color textColor;
  final ValueChanged<bool> onChanged;
  final bool compact;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: labelSize,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Transform.scale(
          scale: compact ? 0.85 : 1,
          child: Switch.adaptive(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _PinBadge extends StatelessWidget {
  const _PinBadge({
    required this.pin,
    required this.required,
    this.onEdit,
    this.compact = false,
  });

  final int? pin;
  final bool required;
  final VoidCallback? onEdit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final missing = pin == null && required;
    final label = context.l10n.pinBadge(pin, required: required);
    final color = missing ? warningColor : c.textSecondary;

    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.memory_rounded, size: compact ? 12 : 14, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onEdit != null && !compact) ...[
          const SizedBox(width: 2),
          Icon(Icons.edit_outlined, size: 12, color: accentColor),
        ],
      ],
    );

    final child = onEdit == null
        ? chip
        : InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: chip,
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: child,
    );
  }
}
