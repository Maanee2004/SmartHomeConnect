import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
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
            title: 'Sécurité',
            children: [
              ListTile(
                leading: Icon(Icons.nfc_rounded, color: accentColor),
                title: Text(
                  'Cartes RFID',
                  style: TextStyle(color: context.smartColors.textPrimary),
                ),
                subtitle: Text(
                  'Gérer les badges porte et garage',
                  style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: context.smartColors.textSecondary),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Types : DHT22 (temp./hum. dans valeur), PIR, RELAIS, LED.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
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
