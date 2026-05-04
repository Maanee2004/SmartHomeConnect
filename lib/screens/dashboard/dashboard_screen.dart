import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/screens/auth/login_screen.dart';
import 'package:smart_home/screens/floor_plan/floor_plan_editor_screen.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/device_service.dart';
import 'package:smart_home/widgets/device_card.dart';

/// Tableau de bord : en-tête avec le nom via [AuthService], grille devices Firestore.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _service = DeviceService();

  @override
  Widget build(BuildContext context) {
    final firebaseReady = Firebase.apps.isNotEmpty;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_rounded,
              color: accentColor,
              size: 26,
            ),
            const SizedBox(width: 8),
            const Text(
              'Smart Home',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Plan 2D de la maison',
            icon: const Icon(Icons.home_work_outlined, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FloorPlanEditorScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DashboardHeader(),
            const SizedBox(height: 6),
            Text(
              'Tes appareils en temps réel',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            if (!firebaseReady) ...[
              Text(
                "Firebase n'est pas initialisé. Les devices ne peuvent pas se charger.",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              Text(
                'Vérifie `lib/firebase_options.dart` et `Firebase.initializeApp(...)`.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.getDevicesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Erreur Firestore: ${snapshot.error}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final devices = snapshot.data ?? const [];

                  if (devices.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aucun device dans Firestore.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.tonal(
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('devices')
                                    .add({
                                  'name': 'Lampe salon',
                                  'state': false,
                                });
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Échec ajout device: $e'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Ajouter un device de test'),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    itemCount: devices.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final d = devices[index];
                      final id = d['id'] as String;
                      final name = (d['name'] as String?) ?? 'Device';
                      final state = (d['state'] as bool?) ?? false;
                      return DeviceCard(
                        name: name,
                        state: state,
                        onTap: () => _service.toggleDevice(id, state),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// En-tête : « Bonjour [nom] » depuis [AuthService] (prefs après login / inscription).
class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: AuthService.instance.userNameStream(),
      builder: (context, snap) {
        final raw = snap.data?.trim();
        final name =
            (raw == null || raw.isEmpty) ? 'Utilisateur' : raw;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [accentColor, primaryColor],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
