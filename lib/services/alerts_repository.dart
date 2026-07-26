import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/models/house_alert.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firebase_anonymous_auth.dart';
import 'package:smart_home/services/firestore_house_paths.dart';

class AlertsRepository {
  AlertsRepository._();
  static final AlertsRepository instance = AlertsRepository._();

  String? _houseId() {
    final active = AuthService.instance.activeHouseId;
    if (active != null && active.isNotEmpty) return active;
    final owner = AuthService.instance.houseOwnerUserId;
    if (owner != null && owner.isNotEmpty) return owner;
    return AuthService.instance.currentUserId;
  }

  Future<void> _ensureAuth() async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseAnonymousAuth.trySignIn();
  }

  CollectionReference<Map<String, dynamic>>? _alertsCol() {
    if (Firebase.apps.isEmpty) return null;
    final userId = _houseId();
    if (userId == null || userId.isEmpty) return null;
    return FirestoreHousePaths.alerts(FirebaseFirestore.instance, userId);
  }

  Stream<List<HouseAlert>> watchAlerts() {
    final col = _alertsCol();
    if (col == null) return const Stream.empty();
    return col
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => HouseAlert.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> createAlert(HouseAlert alert) async {
    await _ensureAuth();
    final col = _alertsCol();
    final userId = _houseId();
    if (col == null || userId == null) return;
    await col.add(alert.toCreatePayload(userId: userId));
  }

  Future<void> markAsRead(String alertId) async {
    final col = _alertsCol();
    if (col == null) return;
    await col.doc(alertId).set({'read': true}, SetOptions(merge: true));
  }
}
