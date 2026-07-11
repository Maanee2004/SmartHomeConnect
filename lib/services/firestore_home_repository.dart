import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/exceptions/home_data_exception.dart';
import 'package:smart_home/exceptions/home_permission_exception.dart';
import 'package:smart_home/models/appareil_spec.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/models/house_room.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firebase_anonymous_auth.dart';
import 'package:smart_home/services/firestore_house_paths.dart';
import 'package:smart_home/services/firestore_layout.dart';
import 'package:smart_home/services/firestore_schema.dart';
import 'package:smart_home/services/home_repository.dart';

class FirestoreHomeRepository implements HomeRepository {
  FirestoreHomeRepository._();
  static final FirestoreHomeRepository instance = FirestoreHomeRepository._();

  factory FirestoreHomeRepository() => instance;

  FirestorePaths? _paths;
  Future<void>? _detecting;
  String? _lastBootstrapNote;
  StreamController<List<HouseRoom>>? _roomsController;
  StreamController<List<Device>>? _devicesController;
  StreamController<bool>? _houseOnlineController;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _devicesFirestoreSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _piecesFirestoreSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _isonlineFirestoreSub;
  String? _streamsUserId;
  String? _adminTargetUserId;
  List<HouseRoom> _cachedRooms = const [];
  List<Device> _cachedDevices = const [];
  bool _cachedHouseOnline = false;
  Future<void>? _bindUserStreamsTask;

  /// Valeur ON/OFF en attente de confirmation Firestore (évite le switch qui rebondit).
  final Map<String, bool> _pendingActuatorStates = {};

  static Future<void> bootstrap() async {
    if (Firebase.apps.isEmpty) {
      instance._lastBootstrapNote = 'Firebase non initialisé';
      return;
    }
    try {
      await FirebaseAnonymousAuth.trySignIn();
      instance._lastBootstrapNote =
          'uid=${FirebaseAuth.instance.currentUser?.uid}';
    } on FirebaseAuthException catch (e) {
      instance._lastBootstrapNote = 'Auth: ${e.code}';
    } on TimeoutException {
      instance._lastBootstrapNote = 'Auth: timeout';
    }
    await instance.resetAndReload();
  }

  String? get lastBootstrapNote => _lastBootstrapNote;

  @override
  bool get usesCanonicalSchema => true;

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
    _paths = await FirestorePaths.detectWritable(FirebaseFirestore.instance);
    // ignore: avoid_print
    print('[Firestore] ${_paths?.debugLabel}');
  }

  Future<void> _ensureFirebaseAuth() async {
    if (Firebase.apps.isEmpty) return;
    try {
      await FirebaseAnonymousAuth.trySignIn();
    } on FirebaseAuthException catch (e) {
      // ignore: avoid_print
      print('[Firestore] auth anonyme: ${e.code}');
    } on TimeoutException {
      // ignore: avoid_print
      print('[Firestore] auth anonyme: timeout');
    }
  }

  Future<void> resetAndReload() async {
    _paths = null;
    _detecting = null;
    _streamsUserId = null;
    await _cancelFirestoreSubscriptions();
    await _ensureFirebaseAuth();
    await ensureLayoutResolved();
    await _bindUserStreams();
  }

  Future<void> _cancelFirestoreSubscriptions() async {
    await _devicesFirestoreSub?.cancel();
    await _piecesFirestoreSub?.cancel();
    await _isonlineFirestoreSub?.cancel();
    _devicesFirestoreSub = null;
    _piecesFirestoreSub = null;
    _isonlineFirestoreSub = null;
    _cachedRooms = const [];
    _cachedDevices = const [];
    _cachedHouseOnline = false;
    _pendingActuatorStates.clear();
  }

  String? get _currentUserId => AuthService.instance.currentUserId;

  String? get adminTargetUserId => _adminTargetUserId;

  /// Admin : cible la maison d’un utilisateur pour CRUD / streams.
  void setAdminTargetUser(String? userId) {
    final t = userId?.trim();
    _adminTargetUserId = t != null && t.isNotEmpty ? t : null;
    unawaited(resetAndReload());
  }

  CollectionReference<Map<String, dynamic>> get devicesCollection =>
      _houseAppareils(_scopeUserId());

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _houseAppareils(String userId) {
    final p = _paths ?? FirestorePaths.fallbackWithoutFirebase();
    return p.devicesRef(_db, userId);
  }

  CollectionReference<Map<String, dynamic>> _housePieces(String userId) =>
      FirestoreHousePaths.pieces(_db, userId);

  DocumentReference<Map<String, dynamic>> _houseIsonlineRef(String userId) =>
      FirestoreHousePaths.isonlineDoc(_db, userId);

  String? _streamUserId() {
    if (AuthService.instance.isAdmin) return _adminTargetUserId;
    final owner = AuthService.instance.houseOwnerUserId;
    if (owner != null && owner.isNotEmpty) return owner;
    return _currentUserId;
  }

  String _scopeUserId() {
    final id = _streamUserId();
    if (id == null || id.isEmpty) {
      throw StateError('Utilisateur non connecté.');
    }
    return id;
  }

  String _requireUserId() => _scopeUserId();

  void _requireHomeManagePermission() {
    if (!AuthService.instance.canManageHome) {
      throw const HomePermissionDeniedException();
    }
  }

  bool _docBelongsToUser(Map<String, dynamic> data, String userId) {
    final owner = (data[FirestoreFieldNames.fieldUserId] as String?)?.trim();
    return owner == null || owner.isEmpty || owner == userId;
  }

  Future<void> disposeLiveStreams() async {
    await _cancelFirestoreSubscriptions();
    await _roomsController?.close();
    await _devicesController?.close();
    await _houseOnlineController?.close();
    _roomsController = null;
    _devicesController = null;
    _houseOnlineController = null;
    _streamsUserId = null;
  }

  String? get layoutDebugLabel => _paths?.debugLabel;

  static List<HouseRoom> _piecesFromSubcollectionDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final rooms = <HouseRoom>[];
    for (final doc in docs) {
      final data = doc.data();
      final id = (data['id'] as String?)?.trim() ?? doc.id;
      final name = (data['name'] as String?)?.trim() ??
          (data['nom'] as String?)?.trim();
      if (id.isNotEmpty && name != null && name.isNotEmpty) {
        rooms.add(HouseRoom(id: id, name: name));
      }
    }
    rooms.sort((a, b) => a.name.compareTo(b.name));
    return rooms;
  }

  void _refreshRoomsStream() {
    final ctrl = _roomsController;
    if (ctrl == null || ctrl.isClosed) return;
    ctrl.add(
      HouseRoom.mergeWithDevicePieces(_cachedRooms, _cachedDevices),
    );
  }

  void _emitHouseOnline() {
    final ctrl = _houseOnlineController;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(_cachedHouseOnline);
    }
  }

  void _emitCachedStreams() {
    final roomsCtrl = _roomsController;
    if (roomsCtrl != null && !roomsCtrl.isClosed) {
      roomsCtrl.add(
        HouseRoom.mergeWithDevicePieces(_cachedRooms, _cachedDevices),
      );
    }
    final devCtrl = _devicesController;
    if (devCtrl != null && !devCtrl.isClosed) {
      devCtrl.add(_devicesWithPendingOverrides(_cachedDevices));
    }
    _emitHouseOnline();
  }

  List<Device> _devicesWithPendingOverrides(List<Device> devices) {
    if (_pendingActuatorStates.isEmpty) return devices;
    return [
      for (final d in devices)
        _pendingActuatorStates.containsKey(d.id)
            ? d.withActuatorOn(_pendingActuatorStates[d.id]!)
            : d,
    ];
  }

  void _clearSettledPendingActuators() {
    _pendingActuatorStates.removeWhere((id, pendingOn) {
      for (final d in _cachedDevices) {
        if (d.id == id) return d.isOn == pendingOn;
      }
      return false;
    });
  }

  void _emitDevicesStream() {
    final ctrl = _devicesController;
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.add(_devicesWithPendingOverrides(_cachedDevices));
    }
    _refreshRoomsStream();
  }

  @override
  Stream<List<HouseRoom>> watchRooms() {
    _roomsController ??= StreamController<List<HouseRoom>>.broadcast();
    _ensureUserStreams();
    _emitCachedStreams();
    return _roomsController!.stream;
  }

  @override
  Stream<List<Device>> watchDevices() {
    _devicesController ??= StreamController<List<Device>>.broadcast();
    _ensureUserStreams();
    _emitCachedStreams();
    return _devicesController!.stream;
  }

  /// `true` si l’ESP32 a signalé la maison en ligne (`isonline`).
  @override
  Stream<bool> watchHouseOnline() {
    _houseOnlineController ??= StreamController<bool>.broadcast();
    _ensureUserStreams();
    _emitHouseOnline();
    return _houseOnlineController!.stream;
  }

  void _ensureUserStreams() {
    _roomsController ??= StreamController<List<HouseRoom>>.broadcast();
    _devicesController ??= StreamController<List<Device>>.broadcast();
    unawaited(_bindUserStreams());
  }

  Future<void> _bindUserStreams() {
    final pending = _bindUserStreamsTask;
    final task = (pending != null ? pending.then((_) => _runBindUserStreams()) : _runBindUserStreams());
    _bindUserStreamsTask = task;
    return task.whenComplete(() {
      if (identical(_bindUserStreamsTask, task)) {
        _bindUserStreamsTask = null;
      }
    });
  }

  Future<void> _runBindUserStreams() async {
    final userId = _streamUserId();
    if (_streamsUserId == userId &&
        _piecesFirestoreSub != null &&
        _devicesFirestoreSub != null &&
        _isonlineFirestoreSub != null) {
      return;
    }

    await _devicesFirestoreSub?.cancel();
    await _piecesFirestoreSub?.cancel();
    await _isonlineFirestoreSub?.cancel();
    _devicesFirestoreSub = null;
    _piecesFirestoreSub = null;
    _isonlineFirestoreSub = null;
    _streamsUserId = userId;
    _cachedRooms = const [];
    _cachedDevices = const [];
    _cachedHouseOnline = false;
    _pendingActuatorStates.clear();

    _roomsController ??= StreamController<List<HouseRoom>>.broadcast();
    _devicesController ??= StreamController<List<Device>>.broadcast();
    _houseOnlineController ??= StreamController<bool>.broadcast();

    if (userId == null || userId.isEmpty) {
      _emitCachedStreams();
      return;
    }

    _emitCachedStreams();

    try {
      await _ensureFirebaseAuth();
      await ensureLayoutResolved();
      await FirestoreHousePaths.ensureInitialized(_db, userId);

      // ignore: avoid_print
      print(
        '[Firestore] écoute maisons/$userId (${_paths?.debugLabel})',
      );

      _piecesFirestoreSub = _housePieces(userId).snapshots().listen(
        (s) {
          _cachedRooms = _piecesFromSubcollectionDocs(s.docs);
          _refreshRoomsStream();
        },
        onError: (e, st) => _roomsController?.addError(e, st),
        cancelOnError: false,
      );

      _devicesFirestoreSub = _houseAppareils(userId).snapshots().listen(
        (s) {
          final raw =
              s.docs.map((d) => Device.fromFirestore(d.id, d.data())).toList();
          _cachedDevices = _mergeDhtLegacyPairs(raw);
          _clearSettledPendingActuators();
          _emitDevicesStream();
        },
        onError: (e, st) {
          _devicesController?.addError(e, st);
          _roomsController?.addError(e, st);
        },
        cancelOnError: false,
      );

      _isonlineFirestoreSub = _houseIsonlineRef(userId).snapshots().listen(
        (s) {
          _cachedHouseOnline =
              s.data()?[FirestoreSchema.fieldIsonline] == true;
          _emitHouseOnline();
        },
        onError: (e, st) => _houseOnlineController?.addError(e, st),
        cancelOnError: false,
      );
    } catch (e, st) {
      _roomsController?.addError(e, st);
      _devicesController?.addError(e, st);
      _houseOnlineController?.addError(e, st);
    }
  }

  static String _normalizeRoomName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// Regroupe dht_temp_* + dht_hum_* (même pièce + broche) en une carte DHT22.
  static List<Device> _mergeDhtLegacyPairs(List<Device> devices) {
    final temps = <String, Device>{};
    final hums = <String, Device>{};
    final others = <Device>[];

    String key(Device d) {
      final slug = Device.dhtSlugFromId(d.id);
      if (slug != null) return 'slug:$slug';
      return '${(d.piece ?? '').trim().toLowerCase()}|${d.pin ?? -1}';
    }

    for (final d in devices) {
      switch (d.normalizedType) {
        case 'DHT':
        case 'DHT22':
        case 'DHT_TEMP':
          temps[key(d)] = d;
        case 'DHT_HUM':
          hums[key(d)] = d;
        default:
          others.add(d);
      }
    }

    final mergedHumKeys = <String>{};
    for (final entry in temps.entries) {
      final hum = hums[entry.key];
      if (hum != null) {
        final m = Device.mergeDhtPair(entry.value, hum);
        if (m != null) {
          others.add(m);
          mergedHumKeys.add(entry.key);
          continue;
        }
      }
      others.add(entry.value);
    }
    for (final entry in hums.entries) {
      if (!mergedHumKeys.contains(entry.key)) {
        others.add(entry.value);
      }
    }
    return others;
  }

  String _roomOwnerUserId() {
    if (AuthService.instance.isAdmin && _adminTargetUserId != null) {
      return _adminTargetUserId!;
    }
    final linkedOwner = AuthService.instance.houseOwnerUserId;
    if (linkedOwner != null && linkedOwner.isNotEmpty) {
      return linkedOwner;
    }
    final id = _currentUserId;
    if (id == null || id.isEmpty) {
      throw StateError('Utilisateur non connecté.');
    }
    return id;
  }

  void _requireLoggedIn() {
    if (!AuthService.instance.isLoggedIn) {
      throw StateError('Utilisateur non connecté.');
    }
  }

  Future<List<HouseRoom>> _loadRoomsFor(String userId) async {
    await FirestoreHousePaths.ensureInitialized(_db, userId);
    final snap = await _housePieces(userId).get();
    return _piecesFromSubcollectionDocs(snap.docs);
  }

  Future<List<HouseRoom>> _loadRooms() async {
    return _loadRoomsFor(_requireUserId());
  }

  Future<void> _upsertPieceDoc(String userId, HouseRoom room) async {
    await _housePieces(userId).doc(room.id).set({
      'id': room.id,
      'name': room.name,
      FirestoreSchema.fieldUserId: userId,
    });
    if (userId == _streamUserId()) {
      final idx = _cachedRooms.indexWhere((r) => r.id == room.id);
      final updated = [..._cachedRooms];
      if (idx >= 0) {
        updated[idx] = room;
      } else {
        updated.add(room);
      }
      _cachedRooms = updated;
      _refreshRoomsStream();
    }
  }

  Future<void> _deletePieceDoc(String userId, String roomId) async {
    await _housePieces(userId).doc(roomId).delete();
    if (userId == _streamUserId()) {
      _cachedRooms = _cachedRooms.where((r) => r.id != roomId).toList();
      _refreshRoomsStream();
    }
  }

  Future<String> _pieceLabelForRoomId(String roomId) async {
    final prefRooms = await _loadRooms();
    for (final r in prefRooms) {
      if (r.id == roomId) return r.name;
    }
    final rid = roomId.trim().toLowerCase();
    final userId = _requireUserId();
    final devicesSnap = await _houseAppareils(userId).get();
    for (final doc in devicesSnap.docs) {
      final piece = (doc.data()[AppareilSpec.fieldPiece] as String?)?.trim();
      if (piece == null || piece.isEmpty) continue;
      final slug = slugifyRoomDocumentId(piece);
      if (slug == rid) return piece;
    }
    return roomId.trim().replaceAll('_', ' ');
  }

  Future<void> _assertRoomNameUnique(
    String displayName,
    String userId, {
    String? excludeRoomId,
    String? excludePieceLabel,
  }) async {
    final target = _normalizeRoomName(displayName);
    final skipPiece = excludePieceLabel?.trim();
    for (final r in await _loadRoomsFor(userId)) {
      if (excludeRoomId != null && r.id == excludeRoomId) continue;
      if (_normalizeRoomName(r.name) == target) {
        throw DuplicateRoomNameException(displayName.trim());
      }
    }
    final snap = await _houseAppareils(userId).get();
    for (final doc in snap.docs) {
      final piece = (doc.data()[AppareilSpec.fieldPiece] as String?)?.trim();
      if (piece == null || piece.isEmpty) continue;
      if (skipPiece != null &&
          _normalizeRoomName(piece) == _normalizeRoomName(skipPiece)) {
        continue;
      }
      if (_normalizeRoomName(piece) == target) {
        throw DuplicateRoomNameException(displayName.trim());
      }
    }
  }

  static bool _dhtPinShareAllowed(String incomingType, String existingType) {
    final a = incomingType.toUpperCase();
    final b = existingType.toUpperCase();
    if (a == 'DHT' || a == 'DHT22') {
      return b == 'DHT_HUM' || b == 'DHT_TEMP';
    }
    if (b == 'DHT' || b == 'DHT22') {
      return a == 'DHT_HUM' || a == 'DHT_TEMP';
    }
    return (a == 'DHT_TEMP' && b == 'DHT_HUM') ||
        (a == 'DHT_HUM' && b == 'DHT_TEMP');
  }

  Future<void> _assertPinAvailable(
    int pin, {
    String? excludeDeviceId,
    String? newDeviceType,
  }) async {
    final userId = _requireUserId();
    AppareilSpec.validatePin(pin);
    final snap = await _houseAppareils(userId).get();
    for (final doc in snap.docs) {
      if (excludeDeviceId != null && doc.id == excludeDeviceId) continue;
      final p = doc.data()[AppareilSpec.fieldPin];
      if (p is num && p.toInt() == pin) {
        if (newDeviceType != null &&
            _dhtPinShareAllowed(
              newDeviceType,
              AppareilSpec.typeFromData(doc.data(), doc.id),
            )) {
          continue;
        }
        throw PinAlreadyAssignedException(pin, existingDeviceId: doc.id);
      }
    }
  }

  @override
  Future<List<Device>> listRfidReaders() async {
    await ensureLayoutResolved();
    final userId = _requireUserId();
    final snap = await _houseAppareils(userId).get();
    return snap.docs
        .map((d) => Device.fromFirestore(d.id, d.data()))
        .where((d) => d.normalizedType == 'RFID')
        .toList();
  }

  @override
  Future<List<int>> availablePins() async {
    await ensureLayoutResolved();
    final userId = _requireUserId();
    final used = <int>{};
    final snap = await _houseAppareils(userId).get();
    for (final doc in snap.docs) {
      final p = doc.data()[AppareilSpec.fieldPin];
      if (p is num) used.add(p.toInt());
    }
    return [
      for (var i = AppareilSpec.minPin; i <= AppareilSpec.maxPin; i++)
        if (!used.contains(i)) i,
    ];
  }

  @override
  Future<void> sendDeviceCommand(
    String deviceId,
    Map<String, dynamic> patch,
  ) async {
    await ensureLayoutResolved();
    final userId = _scopeUserId();
    final ref = _houseAppareils(userId).doc(deviceId);

    Device? cached;
    for (final d in _cachedDevices) {
      if (d.id == deviceId) {
        cached = d;
        break;
      }
    }

    if (cached != null && !cached.isCapteur && patch.containsKey('isOn')) {
      Map<String, dynamic> payload;
      try {
        payload = AppareilSpec.commandPayload(
          categorie: cached.categorie ?? 'actionneur',
          patch: patch,
          changedBy: AuthService.instance.currentUserId,
        );
      } on ArgumentError catch (e) {
        throw AppareilValidationException(e.message?.toString() ?? '$e');
      }
      final on = patch['isOn'] == true || patch['isOn'] == 1;
      _pendingActuatorStates[deviceId] = on;
      _emitDevicesStream();
      try {
        await ref.set(payload, SetOptions(merge: true));
      } catch (e) {
        _pendingActuatorStates.remove(deviceId);
        _emitDevicesStream();
        rethrow;
      }
      return;
    }

    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    if (!_docBelongsToUser(data, _scopeUserId())) return;

    if (AppareilSpec.isAppareilDocument(data)) {
      final cat = AppareilSpec.categorieFromData(data, deviceId);
      try {
        final payload = AppareilSpec.commandPayload(
          categorie: cat,
          patch: patch,
          changedBy: AuthService.instance.currentUserId,
        );
        await ref.set(payload, SetOptions(merge: true));
      } on ArgumentError catch (e) {
        throw AppareilValidationException(e.message?.toString() ?? '$e');
      }
      return;
    }

    return FirebaseFirestore.instance.runTransaction((tx) async {
      final s = await tx.get(ref);
      if (!s.exists) return;
      final prev = _readLegacyStateMap(s.data()!);
      tx.set(
          ref,
          {
            'state': {...prev, ...patch}
          },
          SetOptions(merge: true));
    });
  }

  static String slugifyRoomDocumentId(String rawName) {
    var s = rawName.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    if (s.isEmpty) s = 'piece';
    return s.length > 120 ? s.substring(0, 120) : s;
  }

  Future<String> _allocateUniqueRoomDocId(
      String baseSlug, String userId) async {
    final ids =
        (await _loadRoomsFor(userId)).map((r) => r.id).toSet();
    if (!ids.contains(baseSlug)) return baseSlug;
    for (var i = 2; i < 10000; i++) {
      final c = '${baseSlug}_$i';
      if (!ids.contains(c)) return c;
    }
    return '${baseSlug}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> addRoom(String name) async {
    _requireLoggedIn();
    await ensureLayoutResolved();
    final t = name.trim();
    if (t.isEmpty) return '';
    final userId = _roomOwnerUserId();
    await _assertRoomNameUnique(t, userId);
    final id = await _allocateUniqueRoomDocId(slugifyRoomDocumentId(t), userId);
    await _upsertPieceDoc(userId, HouseRoom(id: id, name: t));
    return id;
  }

  @override
  Future<void> renameRoom(String roomId, String newName) async {
    _requireLoggedIn();
    await ensureLayoutResolved();
    final id = roomId.trim();
    final t = newName.trim();
    if (id.isEmpty || t.isEmpty) return;

    final userId = _roomOwnerUserId();
    final scopeUserId = _scopeUserId();
    final prefRooms = await _loadRoomsFor(userId);
    final idx = prefRooms.indexWhere((r) => r.id == id);
    final oldLabel =
        idx >= 0 ? prefRooms[idx].name : await _pieceLabelForRoomId(id);

    if (_normalizeRoomName(oldLabel) == _normalizeRoomName(t)) return;

    await _assertRoomNameUnique(
      t,
      userId,
      excludeRoomId: id,
      excludePieceLabel: oldLabel,
    );

    await _upsertPieceDoc(userId, HouseRoom(id: id, name: t));

    final userDevices = await _houseAppareils(scopeUserId).get();
    final batch = FirebaseFirestore.instance.batch();
    final changedBy = _currentUserId;
    var updatedDevices = 0;
    for (final doc in userDevices.docs) {
      final piece = (doc.data()[AppareilSpec.fieldPiece] as String?)?.trim();
      if (piece == oldLabel) {
        batch.update(doc.reference, {
          AppareilSpec.fieldPiece: t,
          AppareilSpec.fieldLastChanged: FieldValue.serverTimestamp(),
          if (changedBy != null && changedBy.isNotEmpty)
            AppareilSpec.fieldChangedBy: changedBy,
        });
        updatedDevices++;
      }
    }
    if (updatedDevices > 0) {
      await batch.commit();
    }
  }

  static String slugifyDeviceName(String rawName) =>
      slugifyRoomDocumentId(rawName);

  String _deviceDocIdBase(String roomId, String deviceName) {
    final r = slugifyRoomDocumentId(roomId);
    var n = slugifyDeviceName(deviceName);
    if (n.isEmpty) n = 'device';
    return '${r}_$n'.length > 120 ? '${r}_${n.substring(0, 56)}' : '${r}_$n';
  }

  Future<String> _allocateUniqueDeviceDocId(String baseSlug, String userId) async {
    final col = _houseAppareils(userId);
    if (!(await col.doc(baseSlug).get()).exists) return baseSlug;
    for (var i = 2; i < 10000; i++) {
      final c = '${baseSlug}_$i';
      if (!(await col.doc(c).get()).exists) return c;
    }
    return '${baseSlug}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static bool _isSensorType(String type) => AppareilSpec.isSensorType(type);

  Future<void> _assertRfidReaderExists(String rfidDocId, String userId) async {
    final id = rfidDocId.trim();
    if (id.isEmpty) {
      throw AppareilValidationException('rfid_cible vide.');
    }
    final snap = await _houseAppareils(userId).doc(id).get();
    if (!snap.exists) {
      throw AppareilValidationException('Lecteur RFID « $id » introuvable.');
    }
    final data = snap.data()!;
    if ((data[FirestoreFieldNames.fieldUserId] as String?)?.trim() != userId) {
      throw AppareilValidationException(
          'Le lecteur RFID n’appartient pas à cet utilisateur.');
    }
    if (AppareilSpec.typeFromData(data, id) != 'RFID') {
      throw AppareilValidationException('« $id » n’est pas un capteur RFID.');
    }
  }

  @override
  Future<String> addDevice({
    required String roomId,
    required String name,
    required String type,
    int? pin,
    String? categorie,
    Map<String, dynamic>? initialState,
    String? rfidCible,
  }) async {
    _requireHomeManagePermission();
    await ensureLayoutResolved();
    final n = name.trim();
    final rid = roomId.trim();
    if (n.isEmpty || rid.isEmpty) return '';

    final userId = _requireUserId();

    final piece = await _pieceLabelForRoomId(rid);
    final ty = type.trim();
    final cat = categorie?.trim().isNotEmpty == true
        ? categorie!.trim()
        : (_isSensorType(ty) ? 'capteur' : 'actionneur');

    final id = await _allocateUniqueDeviceDocId(_deviceDocIdBase(rid, n), userId);
    Map<String, dynamic> payload;
    try {
      if (cat == 'capteur') {
        Object v = 0;
        num? temp;
        num? hum;
        if (initialState != null) {
          final t = initialState['temperature'] ?? initialState['valeur'];
          if (t is num) {
            v = t;
            temp = t;
          }
          final h = initialState['humidity'];
          if (h is num) hum = h;
        }
        final sensorType = AppareilSpec.canonicalSensorType(ty);
        if (AppareilSpec.isDhtType(sensorType)) {
          temp ??= 22.0;
          hum ??= 50.0;
          v = AppareilSpec.formatDhtValeur(temp, hum);
        } else if (sensorType == 'RFID') {
          final raw = initialState?['valeur'];
          v = raw is String ? raw : '0';
        } else if (sensorType == 'ULTRA') {
          final raw = initialState?['valeur'];
          v = raw is String ? raw : (raw is num ? '$raw' : '0');
        } else if (sensorType == 'PIR') {
          v = '0';
        }
        if (pin == null) {
          throw AppareilValidationException(
            'pin obligatoire pour $sensorType (${AppareilSpec.minPin}–${AppareilSpec.maxPin}).',
          );
        }
        await _assertPinAvailable(pin, newDeviceType: sensorType);
        payload = AppareilSpec.sensorPayload(
          appareilId: id,
          piece: piece,
          type: sensorType,
          label: n,
          valeur: v,
          unit: AppareilSpec.unitForSensorType(sensorType),
          userId: userId,
          pin: pin,
          temperature: temp,
          humidity: hum,
        );
      } else {
        if (pin == null) {
          throw AppareilValidationException(
            'pin obligatoire pour un actionneur (${AppareilSpec.minPin}–${AppareilSpec.maxPin}).',
          );
        }
        final actuatorType = AppareilSpec.canonicalActuatorType(ty);
        await _assertPinAvailable(pin, newDeviceType: actuatorType);
        final linkedRfid = (rfidCible ??
                initialState?['rfid_cible'] as String? ??
                initialState?['rfidCible'] as String?)
            ?.trim();
        if (linkedRfid != null && linkedRfid.isNotEmpty) {
          await _assertRfidReaderExists(linkedRfid, userId);
        }
        payload = AppareilSpec.actuatorPayload(
          appareilId: id,
          piece: piece,
          type: actuatorType,
          label: n,
          pin: pin,
          valeur: '0',
          userId: userId,
          changedBy: userId,
          rfidCible: linkedRfid,
        );
      }
    } on ArgumentError catch (e) {
      throw AppareilValidationException(e.message?.toString() ?? '$e');
    }

    await _houseAppareils(userId).doc(id).set(payload);
    return id;
  }

  /// Un doc DHT : `valeur` = « température/humidité » (ex. `24.5/60`).
  @override
  Future<void> addDhtSensor({
    required String roomId,
    required int pin,
    double? temperature,
    double? humidity,
  }) async {
    _requireHomeManagePermission();
    final temp = temperature ?? 24.5;
    final hum = humidity ?? 60.0;
    await ensureLayoutResolved();
    final userId = _requireUserId();
    final piece = await _pieceLabelForRoomId(roomId);
    final slug = slugifyRoomDocumentId(piece);
    final docId = 'dht_$slug';

    await _assertPinAvailable(pin, newDeviceType: 'DHT');

    await _houseAppareils(userId).doc(docId).set(
          AppareilSpec.sensorPayload(
            appareilId: docId,
            piece: piece,
            type: 'DHT',
            label: 'Capteur Température/Humidité $piece',
            valeur: AppareilSpec.formatDhtValeur(temp, hum),
            unit: AppareilSpec.unitCelsiusPercent,
            userId: userId,
            pin: pin,
            temperature: temp,
            humidity: hum,
          ),
        );
  }

  @override
  Future<void> deleteDhtSensorPair(String tempDocId) async {
    await deleteDevice(tempDocId);
    final humId = tempDocId.replaceFirst(
      RegExp(r'dht_temp', caseSensitive: false),
      'dht_hum',
    );
    if (humId != tempDocId) {
      await deleteDevice(humId);
    }
  }

  @override
  Future<void> updateDevicePiece(String deviceId, String roomId) async {
    _requireHomeManagePermission();
    await ensureLayoutResolved();
    final id = deviceId.trim();
    final rid = roomId.trim();
    if (id.isEmpty || rid.isEmpty) return;

    final pieceLabel = await _pieceLabelForRoomId(rid);
    final scopeUserId = _scopeUserId();
    final ref = _houseAppareils(scopeUserId).doc(id);
    final snap = await ref.get();
    if (!snap.exists || !_docBelongsToUser(snap.data()!, scopeUserId)) return;

    final userId = AuthService.instance.currentUserId;
    await ref.set(
      {
        AppareilSpec.fieldPiece: pieceLabel,
        AppareilSpec.fieldLastChanged: FieldValue.serverTimestamp(),
        if (userId != null && userId.isNotEmpty)
          AppareilSpec.fieldChangedBy: userId,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> updateDevicePin(String deviceId, int pin) async {
    _requireHomeManagePermission();
    await ensureLayoutResolved();
    final id = deviceId.trim();
    if (id.isEmpty) return;

    AppareilSpec.validatePin(pin);
    final scopeUserId = _scopeUserId();
    final ref = _houseAppareils(scopeUserId).doc(id);
    final snap = await ref.get();
    if (!snap.exists || !_docBelongsToUser(snap.data()!, scopeUserId)) return;

    final deviceType = AppareilSpec.typeFromData(snap.data()!, id);
    await _assertPinAvailable(
      pin,
      excludeDeviceId: id,
      newDeviceType: deviceType,
    );

    final userId = AuthService.instance.currentUserId;
    await ref.set(
      {
        AppareilSpec.fieldPin: pin,
        AppareilSpec.fieldLastChanged: FieldValue.serverTimestamp(),
        if (userId != null && userId.isNotEmpty)
          AppareilSpec.fieldChangedBy: userId,
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    _requireHomeManagePermission();
    await ensureLayoutResolved();
    final userId = _requireUserId();
    final id = roomId.trim();
    if (id.isEmpty) return;

    final prefRooms = await _loadRooms();
    final knownRoom = prefRooms.any((r) => r.id == id);
    final pieceLabel = await _pieceLabelForRoomId(id);

    final userDevices = await _houseAppareils(userId).get();
    final batch = _db.batch();
    var deletedDevices = 0;
    for (final doc in userDevices.docs) {
      final data = doc.data();
      final piece = (data[AppareilSpec.fieldPiece] as String?)?.trim();
      if (piece == pieceLabel) {
        batch.delete(doc.reference);
        deletedDevices++;
      }
    }
    if (!knownRoom && deletedDevices == 0) return;

    if (deletedDevices > 0) {
      await batch.commit();
    }
    if (knownRoom) {
      await _deletePieceDoc(userId, id);
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    _requireHomeManagePermission();
    await ensureLayoutResolved();
    final id = deviceId.trim();
    if (id.isEmpty) return;
    final userId = _scopeUserId();
    final snap = await _houseAppareils(userId).doc(id).get();
    if (!snap.exists || !_docBelongsToUser(snap.data()!, userId)) return;
    await _houseAppareils(userId).doc(id).delete();
  }

  Map<String, dynamic> _readLegacyStateMap(Map<String, dynamic> data) {
    final raw = data['state'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is bool) return {'isOn': raw};
    return {};
  }

  static String describeFirebaseError(Object error) {
    if (error is DuplicateRoomNameException ||
        error is PinAlreadyAssignedException ||
        error is AppareilValidationException ||
        error is AppareilImmutableFieldException) {
      return error.toString();
    }
    if (error is HomePermissionDeniedException) {
      return error.message;
    }
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Accès refusé (${instance.layoutDebugLabel ?? '?'}). '
          '${FirestorePaths.allPathsHint}';
    }
    return error.toString();
  }

  /// Exemples alignés sur la spec hardware (`appareils/*` + champ `piece`).
  static Future<void> seedDemoHome() async {
    instance._requireHomeManagePermission();
    await bootstrap();
    final userId = instance._requireUserId();

    for (final piece in [
      'Salon',
      'Chambre',
      'Couloir',
      'Garage',
      'Entree',
      'Cuisine',
      'Securite',
    ]) {
      try {
        await instance.addRoom(piece);
      } on DuplicateRoomNameException {
        // déjà présente pour cet utilisateur
      }
    }

    Future<void> setActuator(
      String docId, {
      required String piece,
      required String label,
      required String type,
      required int pin,
      String valeur = '0',
    }) async {
      await instance._assertPinAvailable(pin);
      await instance._houseAppareils(userId).doc(docId).set(
            AppareilSpec.actuatorPayload(
              appareilId: docId,
              piece: piece,
              type: type,
              label: label,
              pin: pin,
              valeur: valeur,
              userId: userId,
            ),
          );
    }

    Future<void> setSensor(
      String docId, {
      required String piece,
      required String type,
      required String label,
      required Object valeur,
      required String unit,
      required int pin,
      num? temperature,
      num? humidity,
    }) async {
      await instance._assertPinAvailable(pin, newDeviceType: type);
      await instance._houseAppareils(userId).doc(docId).set(
            AppareilSpec.sensorPayload(
              appareilId: docId,
              piece: piece,
              type: type,
              label: label,
              valeur: valeur,
              unit: unit,
              userId: userId,
              pin: pin,
              temperature: temperature,
              humidity: humidity,
            ),
          );
    }

    await setSensor(
      'dht_salon',
      piece: 'Salon',
      type: 'DHT',
      label: 'Capteur Température/Humidité',
      valeur: AppareilSpec.formatDhtValeur(24.5, 60.2),
      unit: AppareilSpec.unitCelsiusPercent,
      pin: 2,
      temperature: 24.5,
      humidity: 60.2,
    );
    await setSensor(
      'pir_chambre',
      piece: 'Chambre',
      type: 'PIR',
      label: 'Détecteur PIR',
      valeur: '0',
      unit: AppareilSpec.unitBooleen,
      pin: 4,
    );
    await setSensor(
      'rfid_entree',
      piece: 'Garage',
      type: 'RFID',
      label: 'Lecteur Badge RFID',
      valeur: '0',
      unit: AppareilSpec.unitUid,
      pin: 10,
    );
    await setSensor(
      'ultra_garage',
      piece: 'Garage',
      type: 'ULTRA',
      label: 'Capteur de Distance',
      valeur: '45',
      unit: AppareilSpec.unitCm,
      pin: 5,
    );

    await setActuator(
      'relais_salon',
      piece: 'Salon',
      label: 'Relais',
      type: 'RELAIS',
      pin: 3,
      valeur: '0',
    );
    await setActuator(
      'lampe_salon',
      piece: 'Salon',
      label: 'Lampe Salon',
      type: 'LAMPE',
      pin: 7,
      valeur: '1',
    );
    await setActuator(
      'servo_porte',
      piece: 'Garage',
      label: 'Servomoteur Portail',
      type: 'SERVO',
      pin: 9,
      valeur: '0',
    );
    await instance._houseAppareils(userId).doc('servo_porte').set(
          {
            AppareilSpec.fieldRfidCible: 'rfid_entree',
          },
          SetOptions(merge: true),
        );
    await setActuator(
      'matrice_max',
      piece: 'Salon',
      label: 'Matrice LED Notification',
      type: 'MAX',
      pin: 8,
      valeur: '1',
    );
  }
}
