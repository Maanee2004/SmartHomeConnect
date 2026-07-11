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
                            'Chaque utilisateur possède une maison (même vide).',
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
                          Icons.home_rounded,
                          color: accentColor,
                        ),
                        title: Text(
                          h.ownerName,
                          style: TextStyle(
                            color: context.smartColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${h.roomCount} pièce(s) · ${h.deviceCount} appareil(s)'
                          '${h.memberUserIds.isEmpty ? '' : ' · ${h.memberUserIds.length} membre(s)'}',
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
