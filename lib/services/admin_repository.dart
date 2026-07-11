import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/house_summary.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/firestore_house_paths.dart';
import 'package:smart_home/services/firestore_schema.dart';

/// Opérations réservées aux administrateurs (liste users / maisons).
class AdminRepository {
  AdminRepository._();
  static final AdminRepository instance = AdminRepository._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreSchema.usersCollection);

  DocumentReference<Map<String, dynamic>> _preferencesRef(String userId) =>
      _users
          .doc(userId)
          .collection(FirestoreSchema.preferencesSubcollection)
          .doc(FirestoreSchema.preferencesDocId);

  Future<int> _countRoomsForUser(String userId) async {
    final snap = await FirestoreHousePaths.pieces(_db, userId).get();
    return snap.docs.length;
  }

  Future<int> _countDevicesForUser(String userId) async {
    final snap = await FirestoreHousePaths.appareils(_db, userId).get();
    return snap.docs.length;
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

  /// Une maison par propriétaire (`role: owner` ou `user` legacy, pas membre).
  Future<List<HouseSummary>> fetchHouses() async {
    final users = await _users.orderBy('name').get();

    final houses = <HouseSummary>[];
    for (final userDoc in users.docs) {
      final user = AppUser.fromFirestore(userDoc.id, userDoc.data());
      if (UserRole.isAdmin(user.role)) continue;
      if (!UserRole.isOwner(user.role)) continue;
      if (user.isMemberOfAnotherHouse) continue;

      await FirestoreHousePaths.ensureInitialized(_db, user.userId);

      final prefsSnap = await _preferencesRef(user.userId).get();
      final prefs = prefsSnap.data();
      final roomCount = await _countRoomsForUser(user.userId);
      final deviceCount = await _countDevicesForUser(user.userId);
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
