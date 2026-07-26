import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/house_alert.dart';
import 'package:smart_home/services/alert_engine_service.dart';
import 'package:smart_home/services/alerts_repository.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Écoute les alertes Firestore et affiche un popup pour chaque nouvelle alerte.
class AlertListener extends StatefulWidget {
  const AlertListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AlertListener> createState() => _AlertListenerState();
}

class _AlertListenerState extends State<AlertListener> {
  StreamSubscription<List<HouseAlert>>? _sub;
  final Set<String> _shownAlertIds = {};
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    AuthService.instance.authNotifier.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  @override
  void dispose() {
    AuthService.instance.authNotifier.removeListener(_onAuthChanged);
    _sub?.cancel();
    AlertEngineService.instance.stop();
    super.dispose();
  }

  void _onAuthChanged() {
    _sub?.cancel();
    _sub = null;
    if (!AuthService.instance.isLoggedIn) {
      AlertEngineService.instance.stop();
      return;
    }
    AlertEngineService.instance.start();
    _sub = AlertsRepository.instance.watchAlerts().listen(_onAlerts);
  }

  void _onAlerts(List<HouseAlert> alerts) {
    if (_dialogOpen || alerts.isEmpty) return;
    for (final alert in alerts) {
      if (alert.read || _shownAlertIds.contains(alert.alertId)) continue;
      _shownAlertIds.add(alert.alertId);
      unawaited(_showAlertDialog(alert));
      break;
    }
  }

  Future<void> _showAlertDialog(HouseAlert alert) async {
    final nav = widget.navigatorKey.currentState;
    if (nav == null || !nav.mounted) return;
    _dialogOpen = true;
    try {
      await showDialog<void>(
        context: nav.context,
        barrierDismissible: false,
        builder: (ctx) {
          final c = ctx.smartColors;
          return AlertDialog(
            icon: Icon(
              _iconForType(alert.type),
              color: _colorForSeverity(alert.severity),
              size: 32,
            ),
            title: Text(
              alert.title,
              style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w700),
            ),
            content: Text(
              alert.message,
              style: TextStyle(color: c.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
              FilledButton(
                onPressed: () async {
                  await AlertsRepository.instance.markAsRead(alert.alertId);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Marquer lu'),
              ),
            ],
          );
        },
      );
    } finally {
      _dialogOpen = false;
    }
  }

  IconData _iconForType(String type) => switch (type) {
        'intrusion' => Icons.sensors_rounded,
        'temperature' => Icons.device_thermostat_outlined,
        'rfid_denied' => Icons.nfc_rounded,
        'distance' => Icons.straighten_rounded,
        _ => Icons.notifications_active_outlined,
      };

  Color _colorForSeverity(String severity) => switch (severity) {
        'high' => errorColor,
        'low' => infoColor,
        _ => warningColor,
      };

  @override
  Widget build(BuildContext context) => widget.child;
}
