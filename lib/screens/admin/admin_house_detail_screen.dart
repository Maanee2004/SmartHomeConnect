import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/house_summary.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/screens/dashboard/dashboard_screen.dart';
import 'package:smart_home/services/admin_repository.dart';
import 'package:smart_home/services/firestore_auth_repository.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Dashboard admin pour une maison + gestion propriétaire / invités.
class AdminHouseDetailScreen extends StatefulWidget {
  const AdminHouseDetailScreen({super.key, required this.house});

  final HouseSummary house;

  @override
  State<AdminHouseDetailScreen> createState() => _AdminHouseDetailScreenState();
}

class _AdminHouseDetailScreenState extends State<AdminHouseDetailScreen> {
  late HouseSummary _house;
  List<AppUser> _users = const [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _house = widget.house;
    FirestoreHomeRepository.instance.setAdminTargetHouse(_house.houseId);
    _loadUsers();
  }

  @override
  void dispose() {
    FirestoreHomeRepository.instance.setAdminTargetHouse(null);
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingUsers = true);
    try {
      _users = await AdminRepository.instance.fetchAssignableUsers();
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _refreshHouse() async {
    final houses = await AdminRepository.instance.fetchHouses();
    final updated = houses.where((h) => h.houseId == _house.houseId).firstOrNull;
    if (updated != null && mounted) setState(() => _house = updated);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _assignOwner() async {
    if (_loadingUsers) return;
    final candidates = [
      for (final u in _users)
        if (!u.isMemberOfAnotherHouse && !UserRole.isOwner(u.role)) u,
    ];
    if (candidates.isEmpty) {
      _snack('Aucun utilisateur disponible.');
      return;
    }

    final picked = await showDialog<AppUser>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Désigner un propriétaire'),
        children: [
          for (final u in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, u),
              child: Text('${u.name.isEmpty ? u.userId : u.name} (${u.email})'),
            ),
        ],
      ),
    );
    if (picked == null) return;

    try {
      await AdminRepository.instance.assignOwnerToHouse(
        houseId: _house.houseId,
        ownerUserId: picked.userId,
      );
      await _refreshHouse();
      _snack('${picked.name.isEmpty ? picked.userId : picked.name} est propriétaire.');
    } on AdminFailure catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _addMember() async {
    if (_loadingUsers) return;
    final candidates = [
      for (final u in _users)
        if (!u.isMemberOfAnotherHouse &&
            !UserRole.isOwner(u.role) &&
            u.userId != _house.ownerUserId)
        u,
    ];
    if (candidates.isEmpty) {
      _snack('Aucun utilisateur disponible.');
      return;
    }

    final picked = await showDialog<AppUser>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Ajouter un invité'),
        children: [
          for (final u in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, u),
              child: Text('${u.name.isEmpty ? u.userId : u.name} (${u.email})'),
            ),
        ],
      ),
    );
    if (picked == null) return;

    try {
      await AdminRepository.instance.assignMemberToHouse(
        houseId: _house.houseId,
        memberUserId: picked.userId,
      );
      await _refreshHouse();
      _snack('Invité ajouté.');
    } on AdminFailure catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _removeMember(String memberId) async {
    try {
      await AdminRepository.instance.removeMemberFromHouse(
        houseId: _house.houseId,
        memberUserId: memberId,
      );
      await _refreshHouse();
      _snack('Invité retiré.');
    } on AdminFailure catch (e) {
      _snack(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: c.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _house.displayTitle,
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                _house.hasOwner
                    ? 'Propriétaire : ${_house.ownerLabel}'
                    : 'Sans propriétaire',
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
            ],
          ),
          bottom: TabBar(
            labelColor: accentColor,
            unselectedLabelColor: c.textSecondary,
            tabs: const [
              Tab(text: 'Appareils'),
              Tab(text: 'Accès'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DashboardScreen(
              readOnly: false,
              embedded: true,
              showHeader: false,
              houseTitlePrefix: 'Gestion des appareils',
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Propriétaire',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                if (_house.hasOwner)
                  ListTile(
                    tileColor: c.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(Icons.person_rounded, color: successColor),
                    title: Text(
                      _house.ownerName,
                      style: TextStyle(color: c.textPrimary),
                    ),
                    subtitle: Text(
                      _house.ownerEmail,
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _assignOwner,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Assigner un propriétaire'),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Invités (${_house.memberUserIds.length})',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: c.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addMember,
                      icon: const Icon(Icons.person_add_rounded, size: 18),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_house.memberUserIds.isEmpty)
                  Text(
                    'Aucun invité pour cette maison.',
                    style: TextStyle(color: c.textSecondary),
                  )
                else
                  FutureBuilder<List<AppUser>>(
                    future: Future.wait(
                      _house.memberUserIds.map(
                        (id) => FirestoreAuthRepository.instance.fetchUserById(id),
                      ),
                    ).then(
                      (list) => [
                        for (final u in list)
                          if (u != null) u,
                      ],
                    ),
                    builder: (context, snap) {
                      final members = snap.data ?? const <AppUser>[];
                      if (snap.connectionState == ConnectionState.waiting &&
                          members.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return Column(
                        children: [
                          for (final m in members)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                tileColor: c.card,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: Text(
                                  m.name.isEmpty ? m.userId : m.name,
                                  style: TextStyle(color: c.textPrimary),
                                ),
                                subtitle: Text(
                                  m.email,
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Retirer',
                                  icon: Icon(
                                    Icons.person_remove_rounded,
                                    color: c.textSecondary,
                                  ),
                                  onPressed: () => _removeMember(m.userId),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
