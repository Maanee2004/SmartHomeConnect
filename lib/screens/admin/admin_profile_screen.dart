import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/screens/auth/login_screen.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/firestore_home_repository.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key, required this.bottomNavigationBar});

  final Widget bottomNavigationBar;

  Future<void> _logout(BuildContext context) async {
    FirestoreHomeRepository.instance.setAdminTargetUser(null);
    await AuthService.instance.clearSession();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUserEmail ?? '—';
    final userId = AuthService.instance.currentUserId ?? '—';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profil admin',
          style: TextStyle(
            color: context.smartColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [ThemeToggleButton()],
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: accentColor.withValues(alpha: 0.2),
              child: Icon(Icons.admin_panel_settings_rounded,
                  size: 44, color: accentColor),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: StreamBuilder<String?>(
              stream: AuthService.instance.userNameStream(),
              builder: (context, snap) {
                final name = snap.data?.trim();
                return Text(
                  (name == null || name.isEmpty) ? 'Administrateur' : name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.smartColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Rôle : admin',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _infoTile(context, 'Email', email),
          _infoTile(context, 'Identifiant', userId),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.smartColors.card,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          title: Text(
            label,
            style: TextStyle(
              color: context.smartColors.textSecondary,
              fontSize: 12,
            ),
          ),
          subtitle: Text(
            value,
            style: TextStyle(
              color: context.smartColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
