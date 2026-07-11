import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/models/app_user.dart';
import 'package:smart_home/models/house_invite.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/house_invites_repository.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Écran propriétaire : codes invités + membres.
class HouseInvitesScreen extends StatefulWidget {
  const HouseInvitesScreen({super.key});

  @override
  State<HouseInvitesScreen> createState() => _HouseInvitesScreenState();
}

class _HouseInvitesScreenState extends State<HouseInvitesScreen> {
  final _repo = HouseInvitesRepository.instance;
  String? _ownerId;
  List<AppUser> _members = [];
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();
    _ownerId = AuthService.instance.currentUserId;
    _loadMembers();
    _ensurePrimaryCode();
  }

  Future<void> _ensurePrimaryCode() async {
    final owner = _ownerId;
    if (owner == null) return;
    try {
      await _repo.ensurePrimaryInvite(owner);
    } catch (_) {}
  }

  Future<void> _loadMembers() async {
    final owner = _ownerId;
    if (owner == null) return;
    setState(() => _loadingMembers = true);
    try {
      final members = await _repo.fetchMembers(owner);
      if (mounted) setState(() => _members = members);
    } finally {
      if (mounted) setState(() => _loadingMembers = false);
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code $code copié')),
    );
  }

  Future<void> _createInvite() async {
    final owner = _ownerId;
    if (owner == null) return;
    try {
      await _repo.createInvite(
        ownerUserId: owner,
        label: 'Invitation ${DateTime.now().day}/${DateTime.now().month}',
        expiresIn: const Duration(days: 30),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau code créé.')),
      );
    } on InviteFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _revokeInvite(String inviteId) async {
    final owner = _ownerId;
    if (owner == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Révoquer ce code ?'),
        content: const Text(
          'Le code ne pourra plus être utilisé pour rejoindre la maison.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repo.revokeInvite(ownerUserId: owner, inviteId: inviteId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code révoqué.')),
      );
    } on InviteFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _removeMember(String memberId, String name) async {
    final owner = _ownerId;
    if (owner == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer ce membre ?'),
        content: Text('$name n’aura plus accès à votre maison.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repo.removeMember(
        ownerUserId: owner,
        memberUserId: memberId,
      );
      await _loadMembers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membre retiré.')),
      );
    } on InviteFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = _ownerId;
    final c = context.smartColors;

    if (owner == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes invités')),
        body: const Center(child: Text('Session invalide.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mes invités',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createInvite,
        backgroundColor: accentColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau code'),
      ),
      body: AdaptiveContent(
        padding: context.responsive.listPadding,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            Text(
              'Codes d’invitation',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: _repo.watchInvites(owner),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final invites = snap.data ?? [];
                if (invites.isEmpty) {
                  return Material(
                    color: c.card,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Aucun code pour le moment.'),
                    ),
                  );
                }
                return Material(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    children: [
                      for (var i = 0; i < invites.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                        _InviteTile(
                          invite: invites[i],
                          onCopy: () => _copyCode(invites[i].code),
                          onRevoke: invites[i].isPrimary
                              ? null
                              : () => _revokeInvite(invites[i].inviteId),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Membres (${_members.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Material(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              child: _loadingMembers
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _members.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Aucun membre. Partagez un code pour inviter '
                            'famille ou amis.',
                            style: TextStyle(color: c.textSecondary),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < _members.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      accentColor.withValues(alpha: 0.2),
                                  child: Icon(Icons.person_outline,
                                      color: accentColor),
                                ),
                                title: Text(
                                  _members[i].name,
                                  style: TextStyle(color: c.textPrimary),
                                ),
                                subtitle: Text(
                                  _members[i].email,
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.person_remove_outlined,
                                      color: errorColor),
                                  tooltip: 'Retirer',
                                  onPressed: () => _removeMember(
                                    _members[i].userId,
                                    _members[i].name,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteTile extends StatelessWidget {
  const _InviteTile({
    required this.invite,
    required this.onCopy,
    this.onRevoke,
  });

  final HouseInvite invite;
  final VoidCallback onCopy;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final active = invite.isActive;
    final status = invite.revoked
        ? 'Révoqué'
        : active
            ? 'Actif'
            : 'Expiré';
    final statusColor = invite.revoked
        ? errorColor
        : active
            ? successColor
            : warningColor;

    return ListTile(
      leading: Icon(Icons.vpn_key_outlined, color: accentColor),
      title: Text(
        invite.label,
        style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            invite.code,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$status · ${invite.usedCount} utilisation(s)',
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.copy_rounded, color: c.textSecondary),
            tooltip: 'Copier',
            onPressed: onCopy,
          ),
          if (onRevoke != null)
            IconButton(
              icon: Icon(Icons.block_rounded, color: errorColor),
              tooltip: 'Révoquer',
              onPressed: onRevoke,
            ),
        ],
      ),
      isThreeLine: true,
    );
  }
}
