import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceService {
  const DeviceService();

  Stream<List<Map<String, dynamic>>> getDevicesStream() {
    return FirebaseFirestore.instance.collection('devices').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => {"id": doc.id, ...doc.data()})
              .toList(),
        );
  }

  Future<void> toggleDevice(String id, bool currentState) {
    return FirebaseFirestore.instance.collection('devices').doc(id).set(
      {'state': !currentState},
      SetOptions(merge: true),
    );
  }
}

