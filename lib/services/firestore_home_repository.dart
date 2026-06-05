import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_home/exceptions/home_data_exception.dart';
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

  String _requireUserId() {
    final id = _currentUserId;
    if (id == null || id.isEmpty) {
      throw StateError('Utilisateur non connecté.');
    }
    return id;
  }

  bool _docBelongsToUser(Map<String, dynamic> data) {
    final owner = (data[FirestoreFieldNames.fieldUserId] as String?)?.trim();
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return false;
    return owner == uid;
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
    final userId = _currentUserId;
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
          _cachedDevices =
              s.docs.map((d) => Device.fromFirestore(d.id, d.data())).toList();
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

  Future<List<HouseRoom>> _loadPreferenceRooms() async {
    final userId = _requireUserId();
    final snap = await _preferencesSettingsRef(userId).get();
    return _piecesFromPreferencesData(snap.data());
  }

  Future<void> _writePreferenceRooms(List<HouseRoom> rooms) async {
    final userId = _requireUserId();
    await _preferencesSettingsRef(userId).set(
      {
        FirestoreSchema.fieldUserId: userId,
        FirestoreSchema.fieldPieces: [
          for (final r in rooms) {'id': r.id, 'name': r.name},
        ],
      },
      SetOptions(merge: true),
    );
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

  Future<void> _assertRoomNameUnique(String displayName) async {
    final userId = _requireUserId();
    final target = _normalizeRoomName(displayName);
    for (final r in await _loadPreferenceRooms()) {
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

  Future<void> _assertPinAvailable(int pin, {String? excludeDeviceId}) async {
    final userId = _requireUserId();
    AppareilSpec.validatePin(pin);
    final snap = await _devices.where('userId', isEqualTo: userId).get();
    for (final doc in snap.docs) {
      if (excludeDeviceId != null && doc.id == excludeDeviceId) continue;
      final p = doc.data()[AppareilSpec.fieldPin];
      if (p is num && p.toInt() == pin) {
        throw PinAlreadyAssignedException(pin, existingDeviceId: doc.id);
      }
    }
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

  Future<String> _allocateUniqueRoomDocId(String baseSlug) async {
    final ids = (await _loadPreferenceRooms()).map((r) => r.id).toSet();
    if (!ids.contains(baseSlug)) return baseSlug;
    for (var i = 2; i < 10000; i++) {
      final c = '${baseSlug}_$i';
      if (!ids.contains(c)) return c;
    }
    return '${baseSlug}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<String> addRoom(String name) async {
    await ensureLayoutResolved();
    final t = name.trim();
    if (t.isEmpty) return '';
    await _assertRoomNameUnique(t);
    final id = await _allocateUniqueRoomDocId(slugifyRoomDocumentId(t));
    final rooms = await _loadPreferenceRooms();
    rooms.add(HouseRoom(id: id, name: t));
    await _writePreferenceRooms(rooms);
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

  static String _sensorTypeCode(String type) {
    switch (type.toUpperCase()) {
      case 'DHT22':
      case 'SENSOR_TEMP':
        return 'DHT_TEMP';
      case 'DHT_HUM':
        return 'DHT_HUM';
      case 'PIR':
        return 'PIR';
      case 'ULTRASON':
        return 'ULTRASON';
      case 'RFID':
        return 'RFID';
      default:
        return type.toUpperCase();
    }
  }

  static String _unitForSensorType(String type) {
    switch (_sensorTypeCode(type)) {
      case 'DHT_TEMP':
        return '°C';
      case 'DHT_HUM':
        return '%';
      case 'PIR':
        return 'booléen';
      case 'ULTRASON':
        return 'cm';
      default:
        return '';
    }
  }

  static String _actuatorTypeCode(String type) {
    final t = type.toUpperCase();
    if (t == 'LIGHT' || t == 'LAMPE') return 'RELAIS';
    return t.isEmpty ? 'RELAIS' : t;
  }

  @override
  Future<String> addDevice({
    required String roomId,
    required String name,
    required String type,
    int? pin,
    String? categorie,
    Map<String, dynamic>? initialState,
  }) async {
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
        num v = 0;
        if (initialState != null) {
          final t = initialState['temperature'] ?? initialState['valeur'];
          if (t is num) v = t;
        }
        final sensorType = _sensorTypeCode(ty);
        if (pin != null) await _assertPinAvailable(pin);
        payload = AppareilSpec.sensorPayload(
          appareilId: id,
          piece: piece,
          type: sensorType,
          label: n,
          valeur: v,
          unit: _unitForSensorType(sensorType),
          userId: userId,
          pin: pin,
        );
      } else {
        if (pin == null) {
          throw AppareilValidationException(
            'pin obligatoire pour un actionneur (${AppareilSpec.minPin}–${AppareilSpec.maxPin}).',
          );
        }
        await _assertPinAvailable(pin);
        payload = AppareilSpec.actuatorPayload(
          appareilId: id,
          piece: piece,
          type: _actuatorTypeCode(ty),
          label: n,
          pin: pin,
          valeur: 0,
          userId: userId,
          changedBy: userId,
        );
      }
    } on ArgumentError catch (e) {
      throw AppareilValidationException(e.message?.toString() ?? '$e');
    }

    await _devices.doc(id).set(payload);
    return id;
  }

  @override
  Future<void> updateDevicePin(String deviceId, int pin) async {
    await ensureLayoutResolved();
    final id = deviceId.trim();
    if (id.isEmpty) return;

    AppareilSpec.validatePin(pin);
    await _assertPinAvailable(pin, excludeDeviceId: id);

    final ref = _devices.doc(id);
    final snap = await ref.get();
    if (!snap.exists || !_docBelongsToUser(snap.data()!)) return;

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
    if (error is FirebaseException && error.code == 'permission-denied') {
      return 'Accès refusé (${instance.layoutDebugLabel ?? '?'}). '
          '${FirestorePaths.allPathsHint}';
    }
    return error.toString();
  }

  /// Exemples alignés sur la spec hardware (`appareils/*` + champ `piece`).
  static Future<void> seedDemoHome() async {
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
      required num valeur,
      required String unit,
    }) async {
      await instance._devices.doc(docId).set(
            AppareilSpec.sensorPayload(
              appareilId: docId,
              piece: piece,
              type: type,
              label: label,
              valeur: valeur,
              unit: unit,
              userId: userId,
            ),
          );
    }

    await setSensor(
      'dht_temp_salon',
      piece: 'Salon',
      type: 'DHT_TEMP',
      label: 'Température Salon',
      valeur: 24.5,
      unit: '°C',
    );
    await setSensor(
      'dht_hum_salon',
      piece: 'Salon',
      type: 'DHT_HUM',
      label: 'Humidité Salon',
      valeur: 60.0,
      unit: '%',
    );
    await setSensor(
      'pir_chambre',
      piece: 'Chambre',
      type: 'PIR',
      label: 'Détecteur de Mouvement Chambre',
      valeur: 1,
      unit: 'booléen',
    );
    await setSensor(
      'pir_couloir',
      piece: 'Couloir',
      type: 'PIR',
      label: 'Détecteur Couloir',
      valeur: 0,
      unit: 'booléen',
    );
    await setSensor(
      'ultrason_garage',
      piece: 'Garage',
      type: 'ULTRASON',
      label: 'Distance Garage',
      valeur: 120,
      unit: 'cm',
    );
    await setSensor(
      'rfid_portail',
      piece: 'Entree',
      type: 'RFID',
      label: 'Lecteur RFID Portail',
      valeur: 0,
      unit: 'booléen',
    );

    await setActuator(
      'lampe_salon',
      piece: 'Salon',
      label: 'Éclairage Principal',
      type: 'RELAIS',
      pin: 2,
      valeur: 1,
    );
    await setActuator(
      'lampe_chambre',
      piece: 'Chambre',
      label: 'Lampe Chambre',
      type: 'RELAIS',
      pin: 3,
    );
    await setActuator(
      'lampe_cuisine',
      piece: 'Cuisine',
      label: 'Lampe Cuisine',
      type: 'RELAIS',
      pin: 5,
    );
    await setActuator(
      'moteur_portail',
      piece: 'Entree',
      label: 'Moteur Portail',
      type: 'RELAIS',
      pin: 6,
    );
    await setActuator(
      'buzzer_alarme',
      piece: 'Securite',
      label: 'Alarme Sécurité',
      type: 'RELAIS',
      pin: 7,
    );
  }
}
