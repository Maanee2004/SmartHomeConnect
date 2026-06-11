import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/house_summary.dart';
import 'package:smart_home/services/firestore_schema.dart';
/// Opérations réservées aux administrateurs (liste users / maisons).
class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection(FirestoreSchema.usersCollection);

  CollectionReference<Map<String, dynamic>> get _devices =>
      FirebaseFirestore.instance.collection(FirestoreSchema.appareilsCollection);

  DocumentReference<Map<String, dynamic>> _preferencesRef(String userId) =>
      _users
          .doc(userId)
          .collection(FirestoreSchema.preferencesSubcollection)
          .doc(FirestoreSchema.preferencesDocId);

  int _countRooms(Map<String, dynamic>? prefs) {
    if (prefs == null) return 0;
    final raw = prefs[FirestoreSchema.fieldPieces];
    if (raw is! List) return 0;
    var n = 0;
    for (final item in raw) {
      if (item is Map) {
        final id = (item['id'] as String?)?.trim();
        final name = (item['name'] as String?)?.trim() ??
            (item['nom'] as String?)?.trim();
        if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
          n++;
        }
      } else if (item is String && item.trim().isNotEmpty) {
        n++;
      }
    }
    return n;
  }

  List<String> _memberIds(Map<String, dynamic>? prefs) {
    if (prefs == null) return const [];
    final raw = prefs['memberUserIds'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  /// Maison = au moins une pièce **ou** un appareil pour ce `userId`.
  Future<List<HouseSummary>> fetchHouses() async {
    final users = await FirebaseFirestore.instance
        .collection(FirestoreSchema.usersCollection)
        .orderBy('name')
        .get();
    final devicesSnap = await _devices.get();
    final deviceCountByUser = <String, int>{};
    for (final doc in devicesSnap.docs) {
      final uid =
          (doc.data()[FirestoreSchema.fieldUserId] as String?)?.trim();
      if (uid == null || uid.isEmpty) continue;
      deviceCountByUser[uid] = (deviceCountByUser[uid] ?? 0) + 1;
    }

    final houses = <HouseSummary>[];
    for (final userDoc in users.docs) {
      final user = AppUser.fromFirestore(userDoc.id, userDoc.data());
      final prefsSnap = await _preferencesRef(user.userId).get();
      final prefs = prefsSnap.data();
      final roomCount = _countRooms(prefs);
      final deviceCount = deviceCountByUser[user.userId] ?? 0;
      if (roomCount == 0 && deviceCount == 0) continue;
      houses.add(
        HouseSummary(
          ownerUserId: user.userId,
          ownerName: user.name.isEmpty ? user.userId : user.name,
          ownerEmail: user.email,
          roomCount: roomCount,
          deviceCount: deviceCount,
          memberUserIds: _memberIds(prefs),
        ),
      );
    }
    houses.sort((a, b) => a.ownerName.compareTo(b.ownerName));
    return houses;
  }

  Stream<List<HouseSummary>> watchHouses() async* {
    yield await fetchHouses();
    await for (final _ in _users.snapshots()) {
      yield await fetchHouses();
    }
  }
}
