import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/models/device.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_house_paths.dart';
import 'package:smart_home/widgets/device_card.dart';

class LedRealtimeScreen extends StatefulWidget {
  const LedRealtimeScreen({super.key});

  @override
  State<LedRealtimeScreen> createState() => _LedRealtimeScreenState();
}

class _LedRealtimeScreenState extends State<LedRealtimeScreen> {
  bool _isSending = false;

  DocumentReference<Map<String, dynamic>>? get _ledDoc {
    final houseId = AuthService.instance.activeHouseId ??
        AuthService.instance.houseOwnerUserId ??
        AuthService.instance.currentUserId;
    if (houseId == null || houseId.isEmpty || Firebase.apps.isEmpty) {
      return null;
    }
    return FirestoreHousePaths.appareils(
      FirebaseFirestore.instance,
      houseId,
    ).doc('led_status');
  }

  Future<void> _setEtat(int nextEtat) async {
    final ref = _ledDoc;
    if (ref == null || _isSending) return;
    setState(() => _isSending = true);
    try {
      await ref.set({'etat': nextEtat}, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextEtat == 1 ? 'Commande envoyée: ON' : 'Commande envoyée: OFF',
          ),
          duration: const Duration(milliseconds: 900),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec écriture Firestore: ${e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec commande: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseOk = Firebase.apps.isNotEmpty;
    final ledRef = _ledDoc;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('LED'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: firebaseOk && ledRef != null
              ? ledRef.snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            final etat = (snapshot.data?.data()?['etat'] as int?) ?? 0;
            final isOn = etat == 1;
            return Center(
              child: DeviceCard(
                device: Device(
                  id: 'led_status',
                  name: 'Lampe salon',
                  roomId: '',
                  type: 'LIGHT',
                  state: {'isOn': isOn},
                  isOnline: firebaseOk,
                ),
                onCommand: !firebaseOk || _isSending || ledRef == null
                    ? (_) async {}
                    : (patch) async {
                        final wantOn = patch['isOn'] == true;
                        await _setEtat(wantOn ? 1 : 0);
                      },
              ),
            );
          },
        ),
      ),
    );
  }
}
