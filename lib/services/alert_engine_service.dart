import 'dart:async';

import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_alert.dart';
import 'package:smart_home/models/user_app_preferences.dart';
import 'package:smart_home/services/alerts_repository.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/services/user_preferences_service.dart';

/// Évalue les capteurs et crée des alertes Firestore (+ popup via [AlertListener]).
class AlertEngineService {
  AlertEngineService._();
  static final AlertEngineService instance = AlertEngineService._();

  StreamSubscription<List<Device>>? _devicesSub;
  final Map<String, String> _lastValeurByDevice = {};
  final Map<String, DateTime> _cooldownUntil = {};
  bool _initialLoad = true;

  static const _cooldown = Duration(seconds: 30);

  void start() {
    if (_devicesSub != null) return;
    _devicesSub = FirestoreHomeRepository.instance.watchDevices().listen(
      _onDevices,
      onError: (e) {
        // ignore: avoid_print
        print('[AlertEngine] $e');
      },
    );
  }

  void stop() {
    _devicesSub?.cancel();
    _devicesSub = null;
    _lastValeurByDevice.clear();
    _initialLoad = true;
  }

  void _onDevices(List<Device> devices) {
    if (!AuthService.instance.isLoggedIn) return;
    final prefs = UserPreferencesService.instance.prefs;
    if (!prefs.notificationsEnabled) return;

    if (_initialLoad) {
      for (final d in devices) {
        if (d.isCapteur && d.valeur != null) {
          _lastValeurByDevice[d.id] = _serialize(d.valeur);
        }
      }
      _initialLoad = false;
      return;
    }

    for (final d in devices) {
      if (!d.isCapteur) continue;
      final serialized = _serialize(d.valeur);
      final prev = _lastValeurByDevice[d.id];
      if (prev == serialized) continue;
      _lastValeurByDevice[d.id] = serialized;
      unawaited(_evaluate(d, prefs));
    }
  }

  String _serialize(num? v) => v?.toString() ?? '';

  bool _onCooldown(String key) {
    final until = _cooldownUntil[key];
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _cooldownUntil.remove(key);
    return false;
  }

  void _setCooldown(String key) {
    _cooldownUntil[key] = DateTime.now().add(_cooldown);
  }

  Future<void> _evaluate(Device d, UserAppPreferences prefs) async {
    final type = d.normalizedType;
    final piece = d.piece ?? '';
    final label = d.name;

    if (type == 'PIR') {
      if (!prefs.pirAlertsEnabled) return;
      if ((d.valeur ?? 0) == 0) return;
      final key = 'intrusion:${d.id}';
      if (_onCooldown(key)) return;
      _setCooldown(key);
      await AlertsRepository.instance.createAlert(
        HouseAlert(
          alertId: '',
          type: 'intrusion',
          severity: 'high',
          title: 'Mouvement détecté',
          message: '$label${piece.isNotEmpty ? ' ($piece)' : ''} — mouvement',
          piece: piece.isEmpty ? null : piece,
          appareilId: d.id,
          sourceValue: '${d.valeur}',
        ),
      );
      return;
    }

    if (type == 'DHT' ||
        type == 'DHT22' ||
        type == 'DHT_TEMP' ||
        type == 'DHT_HUM') {
      final cfg = prefs.sensorThreshold('DHT');
      if (!cfg.enabled) return;
      final temp = d.temperatureCelsius;
      if (temp == null) return;
      if (!cfg.triggers(temp)) return;
      final key = 'temperature:${d.id}';
      if (_onCooldown(key)) return;
      _setCooldown(key);
      final dir = cfg.alertAbove ? 'supérieure' : 'inférieure';
      await AlertsRepository.instance.createAlert(
        HouseAlert(
          alertId: '',
          type: 'temperature',
          severity: 'medium',
          title: 'Température ${cfg.alertAbove ? 'élevée' : 'basse'}',
          message:
              '$label : ${temp.toStringAsFixed(1)} °C (seuil $dir ${cfg.threshold} °C)',
          piece: piece.isEmpty ? null : piece,
          appareilId: d.id,
          sourceValue: '${d.valeur}',
        ),
      );
      return;
    }

    if (type == 'ULTRA') {
      final cfg = prefs.sensorThreshold('ULTRA');
      if (!cfg.enabled) return;
      final dist = d.distanceCm;
      if (dist == null) return;
      if (!cfg.triggers(dist)) return;
      final key = 'distance:${d.id}';
      if (_onCooldown(key)) return;
      _setCooldown(key);
      await AlertsRepository.instance.createAlert(
        HouseAlert(
          alertId: '',
          type: 'distance',
          severity: 'medium',
          title: 'Distance seuil',
          message:
              '$label : ${dist.toStringAsFixed(0)} cm (seuil ${cfg.threshold} cm)',
          piece: piece.isEmpty ? null : piece,
          appareilId: d.id,
          sourceValue: '${d.valeur}',
        ),
      );
      return;
    }

    if (type == 'RFID') {
      final cfg = prefs.sensorThreshold('RFID');
      if (!cfg.enabled) return;
      final uid = d.rfidBadgeUid;
      if (uid == null) return;
      // RFID : alerte gérée côté bridge / badges autorisés — skip ici si pas de liste.
    }
  }
}
