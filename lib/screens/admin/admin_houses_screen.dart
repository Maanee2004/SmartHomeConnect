import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/house_summary.dart';
import 'package:smart_home/screens/admin/admin_house_detail_screen.dart';
import 'package:smart_home/services/admin_repository.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/load_error_view.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class AdminHousesScreen extends StatelessWidget {
  const AdminHousesScreen({super.key, required this.bottomNavigationBar});

  final Widget bottomNavigationBar;

  Future<void> _createHouse(BuildContext context) async {
    final nameCtrl = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nouvelle maison'),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nom de la maison',
              hintText: 'Ex. Résidence A, Villa Nord…',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Créer'),
            ),
          ],
        ),
      );
      if (ok != true) return;

      await AdminRepository.instance.createHouseWithoutOwner(
        name: nameCtrl.text,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maison créée.')),
      );
    } on AdminFailure catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec : $e')),
      );
    } finally {
      nameCtrl.dispose();
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
          'Maisons',
          style: TextStyle(
            color: context.smartColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [ThemeToggleButton()],
      ),
      floatingActionButton: firebaseReady
          ? FloatingActionButton.extended(
              onPressed: () => _createHouse(context),
              backgroundColor: accentColor,
              icon: const Icon(Icons.add_home_work_rounded),
              label: const Text('Nouvelle maison'),
            )
          : null,
      bottomNavigationBar: bottomNavigationBar,
      body: !firebaseReady
          ? Center(
              child: Text(
                'Firebase non initialisé.',
                style: TextStyle(color: context.smartColors.textSecondary),
              ),
            )
          : StreamBuilder<List<HouseSummary>>(
              stream: AdminRepository.instance.watchHouses(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return LoadErrorView(
                    message: '${snap.error}',
                    onRetry: () {},
                  );
                }
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final houses = snap.data ?? const <HouseSummary>[];
                if (houses.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 56,
                            color: context.smartColors.textSecondary
                                .withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune maison',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: context.smartColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Créez une maison sans utilisateur, puis assignez un propriétaire ou des invités.',
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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: houses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final h = houses[index];
                    return Material(
                      color: context.smartColors.card,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Icon(
                          h.hasOwner
                              ? Icons.home_rounded
                              : Icons.home_outlined,
                          color: h.hasOwner ? accentColor : Colors.orange,
                        ),
                        title: Text(
                          h.displayTitle,
                          style: TextStyle(
                            color: context.smartColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${h.ownerLabel} · ${h.roomCount} pièce(s) · ${h.deviceCount} appareil(s)'
                          '${h.memberUserIds.isEmpty ? '' : ' · ${h.memberUserIds.length} invité(s)'}',
                          style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: context.smartColors.textSecondary,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AdminHouseDetailScreen(
                                house: h,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
