import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/house_summary.dart';
import 'package:smart_home/models/user_role.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/admin_repository.dart';
import 'package:smart_home/services/firestore_auth_repository.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Feuille admin : modifier le profil d’un utilisateur.
Future<void> showAdminUserEditSheet(
  BuildContext context, {
  required AppUser user,
  required List<HouseSummary> houses,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => _AdminUserEditSheet(
      user: user,
      houses: houses,
      parentContext: context,
    ),
  );
}

class _AdminUserEditSheet extends StatefulWidget {
  const _AdminUserEditSheet({
    required this.user,
    required this.houses,
    required this.parentContext,
  });

  final AppUser user;
  final List<HouseSummary> houses;
  final BuildContext parentContext;

  @override
  State<_AdminUserEditSheet> createState() => _AdminUserEditSheetState();
}

class _AdminUserEditSheetState extends State<_AdminUserEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;

  late final bool _isAdmin;
  late final bool _isOwner;
  late String _selectedRole;
  bool _saving = false;

  AppUser get user => widget.user;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: user.name);
    _emailCtrl = TextEditingController(text: user.email);
    _phoneCtrl = TextEditingController(text: user.phone);
    _passCtrl = TextEditingController();
    _isAdmin = UserRole.isAdmin(user.role);
    _isOwner = UserRole.isOwner(user.role);
    _selectedRole = user.role;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String message) {
    final parent = widget.parentContext;
    if (!parent.mounted) return;
    ScaffoldMessenger.of(parent).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await FirestoreAuthRepository.instance.updateUserByAdmin(
        userId: user.userId,
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        newPlainPassword:
            _passCtrl.text.trim().isEmpty ? null : _passCtrl.text,
        role: _isAdmin ? null : _selectedRole,
      );
      if (!mounted) return;
      Navigator.pop(context);
      _snack('Profil mis à jour.');
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Échec : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profil utilisateur',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  icon: Icon(Icons.close_rounded, color: c.textSecondary),
                  onPressed: _saving ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              user.userId,
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              UserRole.label(user.role),
              style: TextStyle(
                color: _isOwner ? successColor : c.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _field(context, _nameCtrl, 'Nom complet'),
            _field(context, _emailCtrl, 'Email',
                keyboard: TextInputType.emailAddress),
            _field(context, _phoneCtrl, 'Téléphone',
                keyboard: TextInputType.phone),
            _field(context, _passCtrl, 'Nouveau mot de passe (optionnel)',
                obscure: true),
            if (!_isAdmin) ...[
              const SizedBox(height: 8),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Rôle maison',
                  labelStyle: TextStyle(color: c.textSecondary),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedRole,
                    dropdownColor: c.card,
                    style: TextStyle(color: c.textPrimary),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.user,
                        child: Text('Utilisateur (membre)'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.owner,
                        child: Text('Propriétaire (admin maison)'),
                      ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) {
                            if (v == null) return;
                            setState(() => _selectedRole = v);
                          },
                  ),
                ),
              ),
              if (_selectedRole == UserRole.owner)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Le propriétaire gère pièces, appareils et configuration de sa maison.',
                    style: TextStyle(color: c.textSecondary, fontSize: 12),
                  ),
                ),
            ],
            if (user.memberHouseId != null || user.houseOwnerUserId != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        Navigator.pop(context);
                        try {
                          await FirestoreAuthRepository.instance
                              .unassignUserFromHouse(user.userId);
                          _snack('Utilisateur détaché de la maison.');
                        } on AuthFailure catch (e) {
                          _snack(e.message);
                        }
                      },
                icon: const Icon(Icons.link_off_rounded),
                label: Text(
                  'Retirer de la maison (${user.memberHouseId ?? user.houseOwnerUserId})',
                ),
              ),
            ] else if (!_isAdmin && !_isOwner) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        if (widget.houses.isEmpty) {
                          _snack('Aucune maison disponible.');
                          return;
                        }
                        final houseId = await showDialog<String>(
                          context: context,
                          builder: (dCtx) => SimpleDialog(
                            title: Text(
                              'Rattacher à une maison',
                              style: TextStyle(color: c.textPrimary),
                            ),
                            children: [
                              for (final h in widget.houses)
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(dCtx, h.houseId),
                                  child: Text(h.displayTitle),
                                ),
                            ],
                          ),
                        );
                        if (houseId == null || !mounted) return;

                        final house = widget.houses
                            .where((h) => h.houseId == houseId)
                            .firstOrNull;
                        final asOwner = house != null && !house.hasOwner
                            ? await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  title: const Text('Rôle'),
                                  content: const Text(
                                    'Assigner cet utilisateur comme propriétaire ou invité ?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dCtx, false),
                                      child: const Text('Invité'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(dCtx, true),
                                      child: const Text('Propriétaire'),
                                    ),
                                  ],
                                ),
                              )
                            : false;

                        try {
                          if (asOwner == true) {
                            await AdminRepository.instance.assignOwnerToHouse(
                              houseId: houseId,
                              ownerUserId: user.userId,
                            );
                          } else {
                            await FirestoreAuthRepository.instance
                                .assignUserToHouse(
                              houseId: houseId,
                              memberUserId: user.userId,
                            );
                          }
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _snack('Utilisateur rattaché.');
                        } on AuthFailure catch (e) {
                          _snack(e.message);
                        } on AdminFailure catch (e) {
                          _snack(e.message);
                        }
                      },
                icon: const Icon(Icons.link_rounded),
                label: const Text('Rattacher à une maison'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
            if (!_isAdmin) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: errorColor,
                  side: BorderSide(color: errorColor.withValues(alpha: 0.6)),
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            title: Text(
                              'Supprimer ${user.name.isEmpty ? user.userId : user.name} ?',
                              style: TextStyle(color: c.textPrimary),
                            ),
                            content: Text(
                              'Le compte, ses préférences et ses badges RFID seront '
                              'supprimés définitivement. Cette action est irréversible.',
                              style: TextStyle(color: c.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: const Text('Annuler'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () => Navigator.pop(dCtx, true),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !mounted) return;
                        try {
                          await FirestoreAuthRepository.instance
                              .deleteUserByAdmin(
                            userId: user.userId,
                            actingAdminUserId:
                                AuthService.instance.currentUserId,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _snack('Utilisateur supprimé.');
                        } on AuthFailure catch (e) {
                          _snack(e.message);
                        }
                      },
                icon: const Icon(Icons.delete_forever_rounded),
                label: const Text('Supprimer l’utilisateur'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Widget _field(
  BuildContext context,
  TextEditingController controller,
  String hint, {
  TextInputType? keyboard,
  bool obscure = false,
}) {
  final c = context.smartColors;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textSecondary),
      ),
    ),
  );
}
