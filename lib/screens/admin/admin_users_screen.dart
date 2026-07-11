import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/house_summary.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/admin_repository.dart';
import 'package:smart_home/services/firestore_auth_repository.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/screens/admin/admin_user_edit_sheet.dart';
import 'package:smart_home/widgets/load_error_view.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.bottomNavigationBar});

  final Widget bottomNavigationBar;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesSearch(AppUser u, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return u.userId.toLowerCase().contains(q) ||
        u.name.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q) ||
        u.phone.toLowerCase().contains(q);
  }

  Future<void> _showCreateUserSheet(List<HouseSummary> houses) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? selectedHouseId;

    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nouvel utilisateur',
                        style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                              color: context.smartColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _field(nameCtrl, 'Nom complet'),
                      _field(emailCtrl, 'Email', keyboard: TextInputType.emailAddress),
                      _field(phoneCtrl, 'Téléphone', keyboard: TextInputType.phone),
                      _field(passCtrl, 'Mot de passe', obscure: true),
                      const SizedBox(height: 8),
                      DropdownMenu<String?>(
                        label: Text(
                          'Rattacher à une maison (optionnel)',
                          style: TextStyle(color: context.smartColors.textSecondary),
                        ),
                        initialSelection: selectedHouseId,
                        dropdownMenuEntries: [
                          const DropdownMenuEntry(value: null, label: 'Aucune'),
                          for (final h in houses)
                            DropdownMenuEntry(
                              value: h.ownerUserId,
                              label: h.ownerName,
                            ),
                        ],
                        onSelected: (v) =>
                            setModalState(() => selectedHouseId = v),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Créer'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
      if (ok != true || !mounted) return;

      await FirestoreAuthRepository.instance.createUserByAdmin(
        name: nameCtrl.text,
        email: emailCtrl.text,
        phone: phoneCtrl.text,
        plainPassword: passCtrl.text,
        houseOwnerUserId: selectedHouseId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur créé.')),
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec: $e')),
      );
    } finally {
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      passCtrl.dispose();
    }
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        obscureText: obscure,
        style: TextStyle(color: context.smartColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: context.smartColors.textSecondary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseReady = Firebase.apps.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Utilisateurs',
          style: TextStyle(
            color: context.smartColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          const ThemeToggleButton(),
          StreamBuilder<List<HouseSummary>>(
            stream: AdminRepository.instance.watchHouses(),
            builder: (context, houseSnap) {
              final houses = houseSnap.data ?? const <HouseSummary>[];
              return IconButton(
                tooltip: 'Créer un utilisateur',
                icon: Icon(Icons.person_add_rounded,
                    color: context.smartColors.textSecondary),
                onPressed: !firebaseReady
                    ? null
                    : () => _showCreateUserSheet(houses),
              );
            },
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(color: context.smartColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Rechercher (nom, email, téléphone, id)…',
                      hintStyle:
                          TextStyle(color: context.smartColors.textSecondary),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: context.smartColors.textSecondary,
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: context.smartColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                      filled: true,
                      fillColor: context.smartColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<AppUser>>(
                    stream: FirestoreAuthRepository.instance.watchAllUsers(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return LoadErrorView(
                          message: '${snap.error}',
                          onRetry: () => setState(() {}),
                        );
                      }
                      if (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final users = (snap.data ?? const <AppUser>[])
                          .where((u) => _matchesSearch(u, _searchQuery))
                          .toList();
                      return StreamBuilder<List<HouseSummary>>(
                        stream: AdminRepository.instance.watchHouses(),
                        builder: (context, houseSnap) {
                          final houses = houseSnap.data ?? const <HouseSummary>[];
                          if (users.isEmpty) {
                            return Center(
                              child: Text(
                                _searchQuery.isEmpty
                                    ? 'Aucun utilisateur.'
                                    : 'Aucun résultat pour « $_searchQuery ».',
                                style: TextStyle(
                                  color: context.smartColors.textSecondary,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: users.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final u = users[index];
                              final isAdmin = UserRole.isAdmin(u.role);
                              final isOwner = UserRole.isOwner(u.role);
                              return Material(
                                color: context.smartColors.card,
                                borderRadius: BorderRadius.circular(14),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        accentColor.withValues(alpha: 0.15),
                                    child: Icon(
                                      isAdmin
                                          ? Icons.admin_panel_settings_rounded
                                          : isOwner
                                              ? Icons.home_work_rounded
                                              : Icons.person_rounded,
                                      color: accentColor,
                                    ),
                                  ),
                                  title: Text(
                                    u.name.isEmpty ? u.userId : u.name,
                                    style: TextStyle(
                                      color: context.smartColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${u.email}\n${UserRole.label(u.role)}'
                                    '${u.houseOwnerUserId != null ? ' · maison: ${u.houseOwnerUserId}' : ''}',
                                    style: TextStyle(
                                      color: context.smartColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  isThreeLine: u.houseOwnerUserId != null,
                                  trailing: Icon(
                                    Icons.chevron_right_rounded,
                                    color: context.smartColors.textSecondary,
                                  ),
                                  onTap: () => showAdminUserEditSheet(
                                    context,
                                    user: u,
                                    houses: houses,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
