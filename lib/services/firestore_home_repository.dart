import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';
import 'package:smart_home/services/firestore_layout.dart';
import 'package:smart_home/services/home_repository.dart';

/// Persistance Firestore « pièces + appareils » : chemins [détectés](FirestorePaths.detect)
/// (`maison/_data/rooms` ou `/rooms` / `/devices` selon les données existantes).
class FirestoreHomeRepository implements HomeRepository {
  FirestoreHomeRepository._();
  static final FirestoreHomeRepository instance = FirestoreHomeRepository._();

  factory FirestoreHomeRepository() => instance;

  FirestorePaths? _paths;
  Future<void>? _detecting;

  Future<void> ensureLayoutResolved() async {
    if (_paths != null) return;
    if (Firebase.apps.isEmpty) {
      _paths = FirestorePaths.fallbackWithoutFirebase();
      return;
    }
    _detecting ??= _runDetect();
    await _detecting;
  }

  Future<void> _runDetect() async {
    _paths = await FirestorePaths.detect(FirebaseFirestore.instance);
  }

  CollectionReference<Map<String, dynamic>> get _rooms {
    final p = _paths;
    if (p == null) {
      throw StateError(
        'FirestoreHomeRepository: appelez ensureLayoutResolved() '
        'ou souscrivez à watchRooms / watchDevices.',
      );
    }
    return p.roomsRef(FirebaseFirestore.instance);
  }

  CollectionReference<Map<String, dynamic>> get _devices {
    final p = _paths;
    if (p == null) {
      throw StateError('FirestoreHomeRepository: chemins non résolus.');
    }
    return p.devicesRef(FirebaseFirestore.instance);
  }

  @override
  Stream<List<HouseRoom>> watchRooms() async* {
    await ensureLayoutResolved();
    yield* _rooms.snapshots().map(
          (s) => s.docs
              .map((d) => HouseRoom.fromFirestore(d.id, d.data()))
              .toList(),
        );
  }

  @override
  Stream<List<Device>> watchDevices() async* {
    await ensureLayoutResolved();
    yield* _devices.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Device.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> sendDeviceCommand(String deviceId, Map<String, dynamic> patch) async {
    await ensureLayoutResolved();
    final ref = _devices.doc(deviceId);
    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      final prev = _readStateMap(data);
      final merged = {...prev, ...patch};
      tx.set(ref, {'state': merged}, SetOptions(merge: true));
    });
  }

  /// ID de document Firestore lisible (Arduino / Node) : minuscules, `_`, chiffres.
  static String slugifyRoomDocumentId(String rawName) {
    var s = rawName.toLowerCase().trim();
    const accents = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae',
    };
    final b = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      b.write(accents[ch] ?? ch);
    }
    s = b.toString();
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_');
    s = s.replaceAll(RegExp(r'^_|_$'), '');
    if (s.isEmpty) s = 'piece';
    if (s.length > 120) s = s.substring(0, 120);
    return s;
  }

  Future<String> _allocateUniqueRoomDocId(String baseSlug) async {
    final coll = _rooms;
    final exists = await coll.doc(baseSlug).get();
    if (!exists.exists) return baseSlug;
    for (var i = 2; i < 10000; i++) {
      final candidate = '${baseSlug}_$i';
      final snap = await coll.doc(candidate).get();
      if (!snap.exists) return candidate;
    }
    return '${baseSlug}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> addRoom(String name) async {
    await ensureLayoutResolved();
    final t = name.trim();
    if (t.isEmpty) return '';
    final base = slugifyRoomDocumentId(t);
    final id = await _allocateUniqueRoomDocId(base);
    await _rooms.doc(id).set({'name': t});
    return id;
  }

  /// Même règles que [slugifyRoomDocumentId] (nom d’appareil ou segment).
  static String slugifyDeviceName(String rawName) =>
      slugifyRoomDocumentId(rawName);

  /// Préfixe dérivé de [roomId] (déjà souvent un slug `salon`, ou ancien id alphanum).
  static String roomSegmentForDeviceId(String roomId) {
    var seg = slugifyRoomDocumentId(roomId.trim());
    if (seg.isEmpty) seg = 'room';
    if (seg.length > 48) seg = seg.substring(0, 48);
    return seg;
  }

  String _deviceDocIdBase(String roomId, String deviceName) {
    final r = roomSegmentForDeviceId(roomId);
    var n = slugifyDeviceName(deviceName);
    if (n.isEmpty) n = 'device';
    if (n.length > 56) n = n.substring(0, 56);
    final joined = '${r}_$n';
    if (joined.length > 120) {
      var maxN = 120 - r.length - 1;
      if (maxN < 1) maxN = 1;
      n = n.length > maxN ? n.substring(0, maxN) : n;
      return '${r}_$n';
    }
    return joined;
  }

  Future<String> _allocateUniqueDeviceDocId(String baseSlug) async {
    final coll = _devices;
    final first = await coll.doc(baseSlug).get();
    if (!first.exists) return baseSlug;
    for (var i = 2; i < 10000; i++) {
      final candidate = '${baseSlug}_$i';
      final snap = await coll.doc(candidate).get();
      if (!snap.exists) return candidate;
    }
    return '${baseSlug}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> addDevice({
    required String roomId,
    required String name,
    required String type,
    Map<String, dynamic>? initialState,
  }) async {
    await ensureLayoutResolved();
    final n = name.trim();
    final rid = roomId.trim();
    if (n.isEmpty || rid.isEmpty) return '';
    final ty = type.trim().toUpperCase();
    Map<String, dynamic> state;
    if (initialState != null) {
      state = Map<String, dynamic>.from(initialState);
    } else {
      state = _defaultStateForType(ty);
    }
    final base = _deviceDocIdBase(rid, n);
    final id = await _allocateUniqueDeviceDocId(base);
    await _devices.doc(id).set({
      'name': n,
      'roomId': rid,
      'type': ty,
      'state': state,
      'online': true,
    });
    return id;
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await ensureLayoutResolved();
    final id = roomId.trim();
    if (id.isEmpty) return;
    const limit = 400;
    while (true) {
      final snap =
          await _devices.where('roomId', isEqualTo: id).limit(limit).get();
      if (snap.docs.isEmpty) break;
      final batch = FirebaseFirestore.instance.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await _rooms.doc(id).delete();
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    await ensureLayoutResolved();
    final id = deviceId.trim();
    if (id.isEmpty) return;
    await _devices.doc(id).delete();
  }

  Map<String, dynamic> _defaultStateForType(String t) {
    switch (t) {
      case 'SENSOR_TEMP':
        return {'temperature': 20.0};
      case 'FAN':
        return {'isOn': false, 'speed': 0};
      case 'CAMERA':
        return {'isOn': false};
      default:
        return {'isOn': false};
    }
  }

  Map<String, dynamic> _readStateMap(Map<String, dynamic> data) {
    final raw = data['state'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is bool) return {'isOn': raw};
    return {};
  }

  /// Données de démo (IDs de pièces = slugs : `salon`, `chambre`, …).
  static Future<void> seedDemoHome() async {
    await instance.ensureLayoutResolved();
    final rooms = instance._rooms;

    Future<DocumentReference<Map<String, dynamic>>> seedRoom(String name) async {
      final t = name.trim();
      final base = slugifyRoomDocumentId(t);
      final id = await instance._allocateUniqueRoomDocId(base);
      final ref = rooms.doc(id);
      await ref.set({'name': t});
      return ref;
    }

    final salon = await seedRoom('Salon');
    final chambre = await seedRoom('Chambre');
    final cuisine = await seedRoom('Cuisine');
    await seedRoom('Bureau');
    await seedRoom('Entrée');
    await seedRoom('Salle de bain');
    await seedRoom('Garage');
    await seedRoom('Dressing');

    Future<void> seedDevice({
      required String roomRefId,
      required String name,
      required String type,
      required Map<String, dynamic> state,
      bool online = true,
    }) async {
      final n = name.trim();
      final ty = type.trim().toUpperCase();
      final base = instance._deviceDocIdBase(roomRefId, n);
      final id = await instance._allocateUniqueDeviceDocId(base);
      await instance._devices.doc(id).set({
        'name': n,
        'roomId': roomRefId,
        'type': ty,
        'state': state,
        'online': online,
      });
    }

    await seedDevice(
      roomRefId: salon.id,
      name: 'Lampe',
      type: 'LIGHT',
      state: const {'isOn': false},
    );
    await seedDevice(
      roomRefId: salon.id,
      name: 'Thermomètre',
      type: 'SENSOR_TEMP',
      state: const {'temperature': 22.5},
    );
    await seedDevice(
      roomRefId: salon.id,
      name: 'Ventilateur',
      type: 'FAN',
      state: const {'isOn': false, 'speed': 1},
    );
    await seedDevice(
      roomRefId: chambre.id,
      name: 'Lampe chambre',
      type: 'LIGHT',
      state: const {'isOn': false},
    );
    await seedDevice(
      roomRefId: cuisine.id,
      name: 'Spot cuisine',
      type: 'LIGHT',
      state: const {'isOn': true},
    );
  }
}
