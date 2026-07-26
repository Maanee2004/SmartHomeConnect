import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/sensor_threshold_config.dart';
import 'package:smart_home/services/user_preferences_service.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Réglages alertes capteurs (Paramètres).
class AlertSettingsSection extends StatelessWidget {
  const AlertSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserPreferencesService.instance.notifier,
      builder: (context, _) {
        final prefs = UserPreferencesService.instance.prefs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: Text(
                'Alertes maison',
                style: TextStyle(color: context.smartColors.textPrimary),
              ),
              subtitle: Text(
                'Pop-up + enregistrement Firestore',
                style: TextStyle(
                  color: context.smartColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              secondary:
                  Icon(Icons.notifications_active_outlined, color: accentColor),
              value: prefs.notificationsEnabled,
              activeThumbColor: accentColor,
              onChanged: (v) =>
                  UserPreferencesService.instance.setNotificationsEnabled(v),
            ),
            if (prefs.notificationsEnabled) ...[
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                title: Text(
                  'Alertes mouvement (PIR)',
                  style: TextStyle(color: context.smartColors.textPrimary),
                ),
                subtitle: Text(
                  'Intrusion quand le détecteur passe à « détecté »',
                  style: TextStyle(
                    color: context.smartColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                secondary: Icon(Icons.sensors_rounded, color: accentColor),
                value: prefs.pirAlertsEnabled,
                activeThumbColor: accentColor,
                onChanged: (v) =>
                    UserPreferencesService.instance.setPirAlertsEnabled(v),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ThresholdTile(
                label: 'Température (DHT)',
                icon: Icons.device_thermostat_outlined,
                config: prefs.sensorThreshold('DHT'),
                unit: '°C',
                onChanged: (c) => UserPreferencesService.instance
                    .setSensorThreshold('DHT', c),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ThresholdTile(
                label: 'Distance (ULTRA)',
                icon: Icons.straighten_rounded,
                config: prefs.sensorThreshold('ULTRA'),
                unit: 'cm',
                onChanged: (c) => UserPreferencesService.instance
                    .setSensorThreshold('ULTRA', c),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ThresholdTile extends StatefulWidget {
  const _ThresholdTile({
    required this.label,
    required this.icon,
    required this.config,
    required this.unit,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final SensorThresholdConfig config;
  final String unit;
  final ValueChanged<SensorThresholdConfig> onChanged;

  @override
  State<_ThresholdTile> createState() => _ThresholdTileState();
}

class _ThresholdTileState extends State<_ThresholdTile> {
  late TextEditingController _thresholdCtrl;

  @override
  void initState() {
    super.initState();
    _thresholdCtrl = TextEditingController(
      text: widget.config.threshold.toStringAsFixed(
        widget.unit == '°C' ? 1 : 0,
      ),
    );
  }

  @override
  void didUpdateWidget(_ThresholdTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.threshold != widget.config.threshold) {
      _thresholdCtrl.text = widget.config.threshold.toStringAsFixed(
        widget.unit == '°C' ? 1 : 0,
      );
    }
  }

  @override
  void dispose() {
    _thresholdCtrl.dispose();
    super.dispose();
  }

  void _applyThreshold() {
    final v = double.tryParse(_thresholdCtrl.text.replaceAll(',', '.'));
    if (v == null) return;
    widget.onChanged(widget.config.copyWith(threshold: v));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final cfg = widget.config;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(widget.label, style: TextStyle(color: c.textPrimary)),
            subtitle: Text(
              cfg.enabled
                  ? 'Alerte si ${cfg.alertAbove ? 'au-dessus' : 'en dessous'} du seuil'
                  : 'Désactivé',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
            secondary: Icon(widget.icon, color: accentColor),
            value: cfg.enabled,
            activeThumbColor: accentColor,
            onChanged: (v) => widget.onChanged(cfg.copyWith(enabled: v)),
          ),
          if (cfg.enabled) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _thresholdCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: c.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Seuil (${widget.unit})',
                      labelStyle: TextStyle(color: c.textSecondary),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyThreshold(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Appliquer seuil',
                  onPressed: _applyThreshold,
                  icon: Icon(Icons.check_rounded, color: accentColor),
                ),
              ],
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Au-dessus'),
                  icon: Icon(Icons.arrow_upward_rounded, size: 16),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('En dessous'),
                  icon: Icon(Icons.arrow_downward_rounded, size: 16),
                ),
              ],
              selected: {cfg.alertAbove},
              onSelectionChanged: (s) =>
                  widget.onChanged(cfg.copyWith(alertAbove: s.first)),
            ),
          ],
        ],
      ),
    );
  }
}
