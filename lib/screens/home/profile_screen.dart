import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/models/user_app_preferences.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/services/user_preferences_service.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.bottomNavigationBar});

  final Widget bottomNavigationBar;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static final _prefs = UserPreferencesService.instance;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _prefs.prefs.showDateTime) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatNow(UserAppPreferences p) {
    final now = DateTime.now();
    final date = DateFormat(p.datePattern, p.languageCode).format(now);
    final timePattern = p.use24HourTime ? 'HH:mm' : 'hh:mm a';
    final time = DateFormat(timePattern, p.languageCode).format(now);
    return '$date · $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profil',
          style: TextStyle(color: context.smartColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: const [ThemeToggleButton()],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: ValueListenableBuilder<UserAppPreferences>(
        valueListenable: _prefs.notifier,
        builder: (context, userPrefs, _) {
          return StreamBuilder<String?>(
            stream: AuthService.instance.userNameStream(),
            builder: (context, snap) {
              final name = snap.data?.trim();
              final display =
                  (name == null || name.isEmpty) ? 'Utilisateur' : name;
              final email = AuthService.instance.currentUserEmail ?? '—';
              final userId = AuthService.instance.currentUserId ?? '—';

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: accentColor.withValues(alpha: 0.2),
                      child: Icon(Icons.person_rounded,
                          size: 44, color: accentColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      display,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: context.smartColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      email,
                      style: TextStyle(color: context.smartColors.textSecondary, fontSize: 13),
                    ),
                  ),
                  if (userPrefs.showDateTime) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 18, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            _formatNow(userPrefs),
                            style: TextStyle(
                              color: context.smartColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  _InfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Identifiant',
                    value: userId,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Personnalisation'),
                  _SettingsCard(
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Thème sombre',
                          style: TextStyle(color: context.smartColors.textPrimary),
                        ),
                        subtitle: Text(
                          userPrefs.themeMode == ThemeMode.dark
                              ? 'Bleu nuit'
                              : 'Mode clair',
                          style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        secondary: Icon(
                          userPrefs.themeMode == ThemeMode.dark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: accentColor,
                        ),
                        value: userPrefs.themeMode == ThemeMode.dark,
                        activeThumbColor: accentColor,
                        onChanged: (v) => _prefs.setThemeMode(
                          v ? ThemeMode.dark : ThemeMode.light,
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading:
                            Icon(Icons.language_rounded, color: accentColor),
                        title: Text(
                          'Langue',
                          style: TextStyle(color: context.smartColors.textPrimary),
                        ),
                        subtitle: Text(
                          UserAppPreferences.supportedLanguages[
                                  userPrefs.languageCode] ??
                              userPrefs.languageCode,
                          style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: userPrefs.languageCode,
                          dropdownColor: context.smartColors.card,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(color: context.smartColors.textPrimary),
                          items: UserAppPreferences.supportedLanguages.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) _prefs.setLanguage(v);
                          },
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading:
                            Icon(Icons.text_fields_rounded, color: accentColor),
                        title: Text(
                          'Police',
                          style: TextStyle(color: context.smartColors.textPrimary),
                        ),
                        subtitle: Text(
                          UserAppPreferences.supportedFonts[
                                  userPrefs.fontFamily] ??
                              userPrefs.fontFamily,
                          style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: userPrefs.fontFamily,
                          dropdownColor: context.smartColors.card,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(color: context.smartColors.textPrimary),
                          items: UserAppPreferences.supportedFonts.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) _prefs.setFontFamily(v);
                          },
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading:
                            Icon(Icons.format_size_rounded, color: accentColor),
                        title: Text(
                          'Taille du texte',
                          style: TextStyle(color: context.smartColors.textPrimary),
                        ),
                        subtitle: Text(
                          userPrefs.fontScaleLabel,
                          style: TextStyle(
                            color: context.smartColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: DropdownButton<String>(
                          value: userPrefs.fontScaleKey,
                          dropdownColor: context.smartColors.card,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(color: context.smartColors.textPrimary),
                          items: UserAppPreferences.supportedFontScales.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              _prefs.setFontScale(
                                UserAppPreferences.fontScaleFromKey(v),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionTitle(title: 'Date et heure (optionnel)'),
                  _SettingsCard(
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Afficher date et heure',
                          style: TextStyle(color: context.smartColors.textPrimary),
                        ),
                        subtitle: Text(
                          'Visible sur le profil',
                          style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                        ),
                        secondary:
                            Icon(Icons.calendar_month_rounded, color: accentColor),
                        value: userPrefs.showDateTime,
                        activeThumbColor: accentColor,
                        onChanged: _prefs.setShowDateTime,
                      ),
                      if (userPrefs.showDateTime) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        SwitchListTile(
                          title: Text(
                            'Format 24 h',
                            style: TextStyle(color: context.smartColors.textPrimary),
                          ),
                          subtitle: Text(
                            userPrefs.use24HourTime ? '14:30' : '02:30 PM',
                            style: TextStyle(
                              color: context.smartColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          secondary:
                              Icon(Icons.access_time_rounded, color: accentColor),
                          value: userPrefs.use24HourTime,
                          activeThumbColor: accentColor,
                          onChanged: _prefs.setUse24HourTime,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        ListTile(
                          leading: Icon(Icons.event_rounded, color: accentColor),
                          title: Text(
                            'Format de date',
                            style: TextStyle(color: context.smartColors.textPrimary),
                          ),
                          trailing: DropdownButton<String>(
                            value: userPrefs.datePattern,
                            dropdownColor: context.smartColors.card,
                            underline: const SizedBox.shrink(),
                            style: TextStyle(color: context.smartColors.textPrimary),
                            items: UserAppPreferences.supportedDatePatterns.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _prefs.setDatePattern(v);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      await AuthService.instance.clearSession();
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: Text('Se déconnecter'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.smartColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.planBorder.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.smartColors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: context.smartColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: context.smartColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
