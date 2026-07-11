import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/screens/home/user_guide_screen.dart';
import 'package:smart_home/screens/home/device_setup_guide_screen.dart';
import 'package:smart_home/screens/home/house_invites_screen.dart';
import 'package:smart_home/screens/home/join_house_screen.dart';
import 'package:smart_home/screens/home/lan_access_screen.dart';
import 'package:smart_home/screens/home/rfid_cards_screen.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.bottomNavigationBar});

  final Widget bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Paramètres',
          style: TextStyle(color: context.smartColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: const [ThemeToggleButton()],
      ),
      bottomNavigationBar: bottomNavigationBar,
      body: AdaptiveContent(
        padding: context.responsive.listPadding,
        child: ListView(
          padding: EdgeInsets.zero,
        children: [
          _SettingsSection(
            title: 'Apparence',
            children: [
              ListTile(
                leading: Icon(Icons.person_rounded, color: accentColor),
                title: Text(
                  'Thème, langue et police',
                  style: TextStyle(color: context.smartColors.textPrimary),
                ),
                subtitle: Text(
                  'Réglages dans l’onglet Profil',
                  style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                ),
                trailing:
                    Icon(Icons.chevron_right_rounded, color: context.smartColors.textSecondary),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ouvre l’onglet Profil en bas.'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: Text(
                  'Alertes maison',
                  style: TextStyle(color: context.smartColors.textPrimary),
                ),
                subtitle: Text(
                  'Température, accès RFID, mouvement…',
                  style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                ),
                secondary: Icon(Icons.notifications_active_outlined,
                    color: accentColor),
                value: true,
                activeThumbColor: accentColor,
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Accès distant',
            children: [
              ListTile(
                leading: Icon(Icons.qr_code_2_rounded, color: accentColor),
                title: Text(
                  'Accès mobile (Wi‑Fi)',
                  style: TextStyle(color: context.smartColors.textPrimary),
                ),
                subtitle: Text(
                  'Connexion au PC sur le même Wi‑Fi (QR ou lien direct)',
                  style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.smartColors.textSecondary),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LanAccessScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (AuthService.instance.isLoggedIn)
            _SettingsSection(
              title: 'Guides utilisateur',
              children: [
                ListTile(
                  leading: Icon(
                    AuthService.instance.isHouseOwner
                        ? Icons.home_work_rounded
                        : Icons.menu_book_outlined,
                    color: accentColor,
                  ),
                  title: Text(
                    AuthService.instance.isHouseOwner
                        ? 'Guide propriétaire'
                        : AuthService.instance.isMember
                            ? 'Guide invité'
                            : 'Guide utilisateur',
                    style: TextStyle(color: context.smartColors.textPrimary),
                  ),
                  subtitle: Text(
                    AuthService.instance.isHouseOwner
                        ? 'Pièces, appareils, invités, RFID — en autonomie'
                        : 'Permissions et utilisation de l’app',
                    style: TextStyle(
                      color: context.smartColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: context.smartColors.textSecondary),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const UserGuideScreen(),
                      ),
                    );
                  },
                ),
                if (AuthService.instance.canAddDevices &&
                    !AuthService.instance.isMember)
                  ListTile(
                    leading: Icon(Icons.devices_other_rounded, color: accentColor),
                    title: Text(
                      'Guide : ajouter des appareils',
                      style: TextStyle(color: context.smartColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Étapes détaillées pièce par pièce',
                      style: TextStyle(
                        color: context.smartColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: context.smartColors.textSecondary),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeviceSetupGuideScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          if (AuthService.instance.canManageInvites ||
              AuthService.instance.canJoinHouse) ...[
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Maison',
              children: [
                if (AuthService.instance.canManageInvites)
                  ListTile(
                    leading: Icon(Icons.group_add_rounded, color: accentColor),
                    title: Text(
                      'Mes invités',
                      style: TextStyle(color: context.smartColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Codes d’invitation et membres',
                      style: TextStyle(
                        color: context.smartColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: context.smartColors.textSecondary),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HouseInvitesScreen(),
                        ),
                      );
                    },
                  ),
                if (AuthService.instance.canJoinHouse)
                  ListTile(
                    leading: Icon(Icons.home_work_outlined, color: accentColor),
                    title: Text(
                      'Rejoindre une maison',
                      style: TextStyle(color: context.smartColors.textPrimary),
                    ),
                    subtitle: Text(
                      'Saisir un code invité à 5 chiffres',
                      style: TextStyle(
                        color: context.smartColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: context.smartColors.textSecondary),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const JoinHouseScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Sécurité',
            children: [
              ListTile(
                leading: Icon(Icons.nfc_rounded, color: accentColor),
                title: Text(
                  'Accès RFID & portes',
                  style: TextStyle(color: context.smartColors.textPrimary),
                ),
                subtitle: Text(
                  'Badges, lecteurs et servomoteurs',
                  style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.smartColors.textSecondary),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RfidCardsScreen(),
                    ),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.smartColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Material(
          color: context.smartColors.card,
          borderRadius: BorderRadius.circular(14),
          child: Column(children: children),
        ),
      ],
    );
  }
}
