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
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _preferencesFirestoreSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _devicesFirestoreSub;
  String? _streamsUserId;
  String? _adminTargetUserId;
  List<HouseRoom> _cachedPrefRooms = const [];
  List<Device> _cachedDevices = const [];

  static Future<void> bootstrap() async {
    if (Firebase.apps.isEmpty) {
      instance._lastBootstrapNote = 'Firebase non initialisé';
      return;
    }
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      instance._lastBootstrapNote =
          'uid=${FirebaseAuth.instance.currentUser?.uid}';
    } on FirebaseAuthException catch (e) {
      instance._lastBootstrapNote = 'Auth: ${e.code}';
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

  Future<void> resetAndReload() async {
    _paths = null;
    _detecting = null;
    _streamsUserId = null;
    await _cancelFirestoreSubscriptions();
    await ensureLayoutResolved();
    await _bindUserStreams();
  }

  Future<void> _cancelFirestoreSubscriptions() async {
    await _preferencesFirestoreSub?.cancel();
    await _devicesFirestoreSub?.cancel();
    _preferencesFirestoreSub = null;
    _devicesFirestoreSub = null;
    _cachedPrefRooms = const [];
    _cachedDevices = const [];
  }

  String? get _currentUserId => AuthService.instance.currentUserId;

  String? get adminTargetUserId => _adminTargetUserId;

  /// Admin : cible la maison d’un utilisateur pour CRUD / streams.
  void setAdminTargetUser(String? userId) {
    final t = userId?.trim();
    _adminTargetUserId = t != null && t.isNotEmpty ? t : null;
    unawaited(resetAndReload());
  }

  CollectionReference<Map<String, dynamic>> get devicesCollection => _devices;

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

  bool _docBelongsToUser(Map<String, dynamic> data) {
    final owner = (data[FirestoreFieldNames.fieldUserId] as String?)?.trim();
    try {
      return owner == _scopeUserId();
    } catch (_) {
      return false;
    }
  }

  Future<void> disposeLiveStreams() async {
    await _cancelFirestoreSubscriptions();
    await _roomsController?.close();
    await _devicesController?.close();
    _roomsController = null;
    _devicesController = null;
    _streamsUserId = null;
  }

  String? get layoutDebugLabel => _paths?.debugLabel;

  DocumentReference<Map<String, dynamic>> _preferencesSettingsRef(
    String userId,
  ) =>
      FirebaseFirestore.instance
          .collection(FirestoreSchema.usersCollection)
          .doc(userId)
          .collection(FirestoreSchema.preferencesSubcollection)
          .doc(FirestoreSchema.preferencesDocId);

  CollectionReference<Map<String, dynamic>> get _devices {
    final p = _paths ?? FirestorePaths.fallbackWithoutFirebase();
    return p.devicesRef(FirebaseFirestore.instance);
  }

  static List<HouseRoom> _piecesFromPreferencesData(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return [];
    final raw = data[FirestoreSchema.fieldPieces];
    if (raw is! List) return [];
    final rooms = <HouseRoom>[];
    for (final item in raw) {
      if (item is Map) {
        final id = (item['id'] as String?)?.trim();
        final name = (item['name'] as String?)?.trim() ??
            (item['nom'] as String?)?.trim();
        if (id != null &&
            id.isNotEmpty &&
            name != null &&
            name.isNotEmpty) {
          rooms.add(HouseRoom(id: id, name: name));
        }
      } else if (item is String && item.trim().isNotEmpty) {
        final name = item.trim();
        rooms.add(
          HouseRoom(id: slugifyRoomDocumentId(name), name: name),
        );
      }
    }
    return rooms;
  }

  void _refreshRoomsStream() {
    final ctrl = _roomsController;
    if (ctrl == null || ctrl.isClosed) return;
    ctrl.add(
      HouseRoom.mergeWithDevicePieces(_cachedPrefRooms, _cachedDevices),
    );
  }

  @override
  Stream<List<HouseRoom>> watchRooms() {
    _roomsController ??= StreamController<List<HouseRoom>>.broadcast();
    _ensureUserStreams();
    return _roomsController!.stream;
  }

  @override
  Stream<List<Device>> watchDevices() {
    _devicesController ??= StreamController<List<Device>>.broadcast();
    _ensureUserStreams();
    return _devicesController!.stream;
  }

  void _ensureUserStreams() {
    _roomsController ??= StreamController<List<HouseRoom>>.broadcast();
    _devicesController ??= StreamController<List<Device>>.broadcast();
    unawaited(_bindUserStreams());
  }

  Future<void> _bindUserStreams() async {
    final userId = _streamUserId();
    if (_streamsUserId == userId &&
        _preferencesFirestoreSub != null &&
        _devicesFirestoreSub != null) {
      return;
    }

    await _preferencesFirestoreSub?.cancel();
    await _devicesFirestoreSub?.cancel();
    _preferencesFirestoreSub = null;
    _devicesFirestoreSub = null;
    _streamsUserId = userId;
    _cachedPrefRooms = const [];
    _cachedDevices = const [];

    _roomsController ??= StreamController<List<HouseRoom>>.broadcast();
    _devicesController ??= StreamController<List<Device>>.broadcast();

    if (userId == null || userId.isEmpty) {
      if (!_roomsController!.isClosed) _roomsController!.add(const []);
      if (!_devicesController!.isClosed) _devicesController!.add(const []);
      return;
    }

    try {
      await ensureLayoutResolved();
      // ignore: avoid_print
      print(
        '[Firestore] écoute preferences/appareils userId=$userId (${_paths?.debugLabel})',
      );
      _preferencesFirestoreSub =
          _preferencesSettingsRef(userId).snapshots().listen(
        (s) {
          _cachedPrefRooms = _piecesFromPreferencesData(s.data());
          _refreshRoomsStream();
        },
        onError: (e, st) => _roomsController?.addError(e, st),
        cancelOnError: false,
      );
      _devicesFirestoreSub =
          _devices.where('userId', isEqualTo: userId).snapshots().listen(
        (s) {
          final raw =
              s.docs.map((d) => Device.fromFirestore(d.id, d.data())).toList();
          _cachedDevices = _mergeDhtLegacyPairs(raw);
          final ctrl = _devicesController;
          if (ctrl != null && !ctrl.isClosed) {
            ctrl.add(_cachedDevices);
          }
          _refreshRoomsStream();
        },
        onError: (e, st) {
          _devicesController?.addError(e, st);
          _roomsController?.addError(e, st);
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      _roomsController?.addError(e, st);
      _devicesController?.addError(e, st);
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

  Future<List<HouseRoom>> _loadPreferenceRoomsFor(String userId) async {
    final snap = await _preferencesSettingsRef(userId).get();
    return _piecesFromPreferencesData(snap.data());
  }

  Future<List<HouseRoom>> _loadPreferenceRooms() async {
    return _loadPreferenceRoomsFor(_requireUserId());
  }

  Future<void> _writePreferenceRoomsFor(
    String userId,
    List<HouseRoom> rooms,
  ) async {
    await _preferencesSettingsRef(userId).set(
      {
        FirestoreSchema.fieldUserId: userId,
        FirestoreSchema.fieldPieces: [
          for (final r in rooms) {'id': r.id, 'name': r.name},
        ],
      },
      SetOptions(merge: true),
    );
    if (userId == _streamUserId()) {
      _cachedPrefRooms = rooms;
      _refreshRoomsStream();
    }
  }

  Future<void> _writePreferenceRooms(List<HouseRoom> rooms) async {
    await _writePreferenceRoomsFor(_requireUserId(), rooms);
  }

  Future<String> _pieceLabelForRoomId(String roomId) async {
    final prefRooms = await _loadPreferenceRooms();
    for (final r in prefRooms) {
      if (r.id == roomId) return r.name;
    }
    final rid = roomId.trim().toLowerCase();
    final userId = _requireUserId();
    final devicesSnap = await _devices.where('userId', isEqualTo: userId).get();
    for (final doc in devicesSnap.docs) {
      final piece = (doc.data()[AppareilSpec.fieldPiece] as String?)?.trim();
      if (piece == null || piece.isEmpty) continue;
      final slug = slugifyRoomDocumentId(piece);
      if (slug == rid) return piece;
    }
    return roomId.trim().replaceAll('_', ' ');
  }

  Future<void> _assertRoomNameUnique(String displayName, String userId) async {
    final target = _normalizeRoomName(displayName);
    for (final r in await _loadPreferenceRoomsFor(userId)) {
      if (_normalizeRoomName(r.name) == target) {
        throw DuplicateRoomNameException(displayName.trim());
      }
    }
    final snap = await _devices.where('userId', isEqualTo: userId).get();
    for (final doc in snap.docs) {
      final piece = (doc.data()[AppareilSpec.fieldPiece] as String?)?.trim();
      if (piece != null && _normalizeRoomName(piece) == target) {
        throw DuplicateRoomNameException(displayName.trim());
      }
    }
  }

  static bool _dhtPinShareAllowed(String incomingType, String existingType) {
    final a = incomingType.toUpperCase();
    final b = existingType.toUpperCase();
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
    final snap = await _devices.where('userId', isEqualTo: userId).get();
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
    final snap = await _devices.where('userId', isEqualTo: userId).get();
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
    final snap = await _devices.where('userId', isEqualTo: userId).get();
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
    final ref = _devices.doc(deviceId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final data = snap.data()!;
    if (!_docBelongsToUser(data)) return;

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
      tx.set(ref, {'state': {...prev, ...patch}}, SetOptions(merge: true));
    });
  }

  static String slugifyRoomDocumentId(String rawName) {
    var s = rawName.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    if (s.isEmpty) s = 'piece';
    return s.length > 120 ? s.substring(0, 120) : s;
  }

  Future<String> _allocateUniqueRoomDocId(String baseSlug, String userId) async {
    final ids = (await _loadPreferenceRoomsFor(userId)).map((r) => r.id).toSet();
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
    final rooms = await _loadPreferenceRoomsFor(userId);
    rooms.add(HouseRoom(id: id, name: t));
    await _writePreferenceRoomsFor(userId, rooms);
    return id;
  }

  static String slugifyDeviceName(String rawName) =>
      slugifyRoomDocumentId(rawName);

  String _deviceDocIdBase(String roomId, String deviceName) {
    final r = slugifyRoomDocumentId(roomId);
    var n = slugifyDeviceName(deviceName);
    if (n.isEmpty) n = 'device';
    return '${r}_$n'.length > 120 ? '${r}_${n.substring(0, 56)}' : '${r}_$n';
  }

  Future<String> _allocateUniqueDeviceDocId(String baseSlug) async {
    if (!(await _devices.doc(baseSlug).get()).exists) return baseSlug;
    for (var i = 2; i < 10000; i++) {
      final c = '${baseSlug}_$i';
      if (!(await _devices.doc(c).get()).exists) return c;
    }
    return '${baseSlug}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static bool _isSensorType(String type) => AppareilSpec.isSensorType(type);

  Future<void> _assertRfidReaderExists(String rfidDocId, String userId) async {
    final id = rfidDocId.trim();
    if (id.isEmpty) {
      throw AppareilValidationException('rfid_cible vide.');
    }
    final snap = await _devices.doc(id).get();
    if (!snap.exists) {
      throw AppareilValidationException('Lecteur RFID « $id » introuvable.');
    }
    final data = snap.data()!;
    if ((data[FirestoreFieldNames.fieldUserId] as String?)?.trim() != userId) {
      throw AppareilValidationException('Le lecteur RFID n’appartient pas à cet utilisateur.');
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

    final id = await _allocateUniqueDeviceDocId(_deviceDocIdBase(rid, n));
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
        if (sensorType == 'DHT22' || sensorType == 'DHT_TEMP') {
          temp ??= 22.0;
          hum ??= 50.0;
          v = AppareilSpec.formatDhtValeur(temp, hum);
        } else if (sensorType == 'RFID') {
          final raw = initialState?['valeur'];
          v = raw is String ? raw : '0';
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
        if (actuatorType == 'SERVO' && linkedRfid != null && linkedRfid.isNotEmpty) {
          await _assertRfidReaderExists(linkedRfid, userId);
        }
        payload = AppareilSpec.actuatorPayload(
          appareilId: id,
          piece: piece,
          type: actuatorType,
          label: n,
          pin: pin,
          valeur: actuatorType == 'SERVO' ? 0 : 0,
          userId: userId,
          changedBy: userId,
          rfidCible: linkedRfid,
        );
      }
    } on ArgumentError catch (e) {
      throw AppareilValidationException(e.message?.toString() ?? '$e');
    }

    await _devices.doc(id).set(payload);
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

    await _assertPinAvailable(pin, newDeviceType: 'DHT22');

    await _devices.doc(docId).set(
          AppareilSpec.sensorPayload(
            appareilId: docId,
            piece: piece,
            type: 'DHT22',
            label: 'Capteur DHT $piece',
            valeur: AppareilSpec.formatDhtValeur(temp, hum),
            unit: '°C/%',
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
  Future<void> updateDevicePin(String deviceId, int pin) async {
    _requireHomeManagePermission();
    await ensureLayoutResolved();
    final id = deviceId.trim();
    if (id.isEmpty) return;

    AppareilSpec.validatePin(pin);
    final ref = _devices.doc(id);
    final snap = await ref.get();
    if (!snap.exists || !_docBelongsToUser(snap.data()!)) return;

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

    final prefRooms = await _loadPreferenceRooms();
    final knownRoom = prefRooms.any((r) => r.id == id);
    final pieceLabel = await _pieceLabelForRoomId(id);

    final userDevices =
        await _devices.where('userId', isEqualTo: userId).get();
    final batch = FirebaseFirestore.instance.batch();
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
      await _writePreferenceRooms(
        prefRooms.where((r) => r.id != id).toList(),
      );
    }
  }

  @override
  Future<void> deleteDevice(String deviceId) async {
    _requireHomeManagePermission();
    await ensureLayoutResolved();
    final id = deviceId.trim();
    if (id.isEmpty) return;
    final snap = await _devices.doc(id).get();
    if (!snap.exists || !_docBelongsToUser(snap.data()!)) return;
    await _devices.doc(id).delete();
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
      int valeur = 0,
    }) async {
      await instance._assertPinAvailable(pin);
      await instance._devices.doc(docId).set(
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
      await instance._devices.doc(docId).set(
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
      type: 'DHT22',
      label: 'Capteur DHT Salon',
      valeur: AppareilSpec.formatDhtValeur(24.5, 60.0),
      unit: '°C/%',
      pin: 5,
      temperature: 24.5,
      humidity: 60.0,
    );
    await setSensor(
      'pir_chambre',
      piece: 'Chambre',
      type: 'PIR',
      label: 'Détecteur de Mouvement Chambre',
      valeur: 0,
      unit: AppareilSpec.unitBooleen,
      pin: 4,
    );

    await setActuator(
      'lampe_salon',
      piece: 'Salon',
      label: 'Éclairage Principal',
      type: 'RELAIS',
      pin: 3,
      valeur: 1,
    );
    await setActuator(
      'ventilateur_salon',
      piece: 'Salon',
      label: 'Ventilateur Salon',
      type: 'RELAIS',
      pin: 7,
    );
    await setActuator(
      'led_chambre',
      piece: 'Chambre',
      label: 'LED Chambre',
      type: 'LED',
      pin: 6,
    );
  }
}
