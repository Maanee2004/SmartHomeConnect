import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/models/house_room.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/theme/room_icons.dart';
import 'package:smart_home/widgets/load_error_view.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class PiecesScreen extends StatefulWidget {
  const PiecesScreen({
    super.key,
    required this.bottomNavigationBar,
    this.onOpenDashboard,
  });

  final Widget bottomNavigationBar;
  final VoidCallback? onOpenDashboard;

  @override
  State<PiecesScreen> createState() => _PiecesScreenState();
}

class _PiecesScreenState extends State<PiecesScreen> {
  static final _repo = FirestoreHomeRepository();

  bool get _canAddRoom =>
      Firebase.apps.isNotEmpty && AuthService.instance.canAddRooms;

  Future<void> _promptAddRoom() async {
    final controller = TextEditingController();
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Nouvelle pièce',
            style: TextStyle(color: context.smartColors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: context.smartColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'ex. Garage, Entrée…',
              hintStyle: TextStyle(color: context.smartColors.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final t = controller.text.trim();
                Navigator.pop(ctx, t.isEmpty ? null : t);
              },
              child: Text('Ajouter'),
            ),
          ],
        ),
      );
      if (name == null || name.isEmpty || !mounted) return;
      await _repo.addRoom(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pièce « $name » ajoutée.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec: $e')),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = Firebase.apps.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Pièces',
          style: TextStyle(color: context.smartColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Ajouter une pièce',
            icon: Icon(Icons.add_rounded, color: context.smartColors.textSecondary),
            onPressed: !_canAddRoom ? null : _promptAddRoom,
          ),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: !firebaseReady
          ? Center(
              child: Text(
                'Firebase non initialisé.',
                style: TextStyle(color: context.smartColors.textSecondary),
              ),
            )
          : StreamBuilder<List<HouseRoom>>(
              stream: _repo.watchRooms(),
              initialData: const <HouseRoom>[],
              builder: (context, snap) {
                if (snap.hasError) {
                  return LoadErrorView(
                    message: FirestoreHomeRepository.describeFirebaseError(
                      snap.error!,
                    ),
                    onRetry: () async => FirestoreHomeRepository.bootstrap(),
                  );
                }
                final rooms = [...(snap.data ?? const <HouseRoom>[])]
                  ..sort((a, b) => a.name.compareTo(b.name));

                if (rooms.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.meeting_room_outlined,
                            size: 56,
                            color: context.smartColors.textSecondary.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune pièce',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: context.smartColors.textPrimary),
                          ),
                          const SizedBox(height: 12),
                          if (_canAddRoom)
                            FilledButton(
                              onPressed: _promptAddRoom,
                              child: Text('Ajouter une pièce'),
                            )
                          else
                            Text(
                              'Contactez votre administrateur pour ajouter des pièces.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.smartColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return Material(
                      color: context.smartColors.card,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Icon(
                          roomIconFromName(room.name),
                          color: accentColor,
                        ),
                        title: Text(
                          room.name,
                          style: TextStyle(
                            color: context.smartColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'id: ${room.id}',
                          style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: context.smartColors.textSecondary,
                        ),
                        onTap: widget.onOpenDashboard,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
