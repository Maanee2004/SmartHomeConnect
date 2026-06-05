
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_home/models/floor_plan.dart';

/// Persistance Firestore du plan 2D (`floor_plans/{docId}`).
class FloorPlanService {
  FloorPlanService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Document unique : utilisateur Firebase si connecté, sinon `local`.
  String get _documentId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return (uid != null && uid.isNotEmpty) ? uid : 'local';
  }

  DocumentReference<Map<String, dynamic>> get _ref =>
      _db.collection('floor_plans').doc(_documentId);

  /// Flux temps réel (même plan édité sur un autre écran / appareil).
  Stream<FloorPlan> watchPlan() {
    return _ref.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return FloorPlan.empty();
      }
      return FloorPlan.fromFirestoreMap(snap.data());
    });
  }

  Future<FloorPlan> loadOnce() async {
    final snap = await _ref.get();
    if (!snap.exists || snap.data() == null) return FloorPlan.empty();
    return FloorPlan.fromFirestoreMap(snap.data());
  }

  Future<void> save(FloorPlan plan) async {
    await _ref.set({
      ...plan.toFirestoreMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
