import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/l10n/app_localizations.dart';
import 'package:smart_home/screens/home/user_guide_screen.dart';
import 'package:smart_home/screens/home/device_setup_guide_screen.dart';
import 'package:smart_home/screens/home/house_invites_screen.dart';
import 'package:smart_home/screens/home/join_house_screen.dart';
import 'package:smart_home/screens/home/lan_access_screen.dart';
import 'package:smart_home/screens/home/rfid_cards_screen.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/alert_settings_section.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.bottomNavigationBar});

  final Widget bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
              color: context.smartColors.textPrimary,
              fontWeight: FontWeight.w600),
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
              title: l10n.sectionAppearance,
              children: [
                ListTile(
                  leading: Icon(Icons.person_rounded, color: accentColor),
                  title: Text(
                    l10n.themeLanguageFont,
                    style: TextStyle(color: context.smartColors.textPrimary),
                  ),
                  subtitle: Text(
                    l10n.themeLanguageFontHint,
                    style: TextStyle(
                        color: context.smartColors.textSecondary, fontSize: 12),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: context.smartColors.textSecondary),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.openProfileTabSnackbar),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: l10n.sectionNotifications,
              children: const [AlertSettingsSection()],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: l10n.sectionRemoteAccess,
              children: [
                ListTile(
                  leading: Icon(Icons.qr_code_2_rounded, color: accentColor),
                  title: Text(
                    l10n.mobileWifiAccess,
                    style: TextStyle(color: context.smartColors.textPrimary),
                  ),
                  subtitle: Text(
                    l10n.mobileWifiHint,
                    style: TextStyle(
                        color: context.smartColors.textSecondary, fontSize: 12),
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
                title: l10n.sectionGuides,
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
                          ? l10n.guideOwner
                          : AuthService.instance.isMember
                              ? l10n.guideGuest
                              : l10n.guideUser,
                      style: TextStyle(color: context.smartColors.textPrimary),
                    ),
                    subtitle: Text(
                      AuthService.instance.isHouseOwner
                          ? l10n.guideOwnerSubtitle
                          : l10n.guideGuestSubtitle,
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
                      leading:
                          Icon(Icons.devices_other_rounded, color: accentColor),
                      title: Text(
                        'Guide : ajouter des appareils',
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
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
                title: l10n.sectionHouse,
                children: [
                  if (AuthService.instance.canManageInvites)
                    ListTile(
                      leading:
                          Icon(Icons.group_add_rounded, color: accentColor),
                      title: Text(
                        l10n.myGuests,
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        l10n.myGuestsHint,
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
                      leading:
                          Icon(Icons.home_work_outlined, color: accentColor),
                      title: Text(
                        l10n.joinHouse,
                        style:
                            TextStyle(color: context.smartColors.textPrimary),
                      ),
                      subtitle: Text(
                        l10n.joinHouseHint,
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
              title: l10n.sectionSecurity,
              children: [
                ListTile(
                  leading: Icon(Icons.nfc_rounded, color: accentColor),
                  title: Text(
                    l10n.rfidAccess,
                    style: TextStyle(color: context.smartColors.textPrimary),
                  ),
                  subtitle: Text(
                    l10n.rfidAccessHint,
                    style: TextStyle(
                        color: context.smartColors.textSecondary, fontSize: 12),
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
