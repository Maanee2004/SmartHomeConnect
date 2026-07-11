import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/services/lan_access_config.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';
import 'package:smart_home/widgets/theme_toggle_button.dart';
import 'package:url_launcher/url_launcher.dart';

class LanAccessScreen extends StatefulWidget {
  const LanAccessScreen({super.key});

  @override
  State<LanAccessScreen> createState() => _LanAccessScreenState();
}

class _LanAccessScreenState extends State<LanAccessScreen> {
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '${LanAccessConfig.defaultPort}');

  bool _loading = true;
  bool _autoDetected = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final host = await LanAccessConfig.loadHost();
    final port = await LanAccessConfig.loadPort();
    if (!mounted) return;
    final guessedHost = _guessHostFromCurrentUrl();
    final guessedPort = _guessPortFromCurrentUrl();
    _hostCtrl.text = host ?? guessedHost;
    _portCtrl.text = '${host != null ? port : (guessedPort ?? port)}';
    _autoDetected = host == null && guessedHost.isNotEmpty;
    setState(() => _loading = false);
  }

  String _guessHostFromCurrentUrl() {
    final host = Uri.base.host;
    if (host.isEmpty || host == 'localhost' || host == '127.0.0.1') {
      return '';
    }
    return host;
  }

  int? _guessPortFromCurrentUrl() {
    final port = Uri.base.port;
    if (port > 0 && port <= 65535) return port;
    return null;
  }

  bool get _isPrivateLanHost =>
      LanAccessConfig.isPrivateLanHost(_hostCtrl.text);

  int? _parsedPort() {
    final p = int.tryParse(_portCtrl.text.trim());
    if (p == null || p < 1 || p > 65535) return null;
    return p;
  }

  String get _url {
    final port = _parsedPort();
    if (port == null) return '';
    return LanAccessConfig.buildUrl(host: _hostCtrl.text, port: port);
  }

  /// Mode téléphone : app native ou petit écran, pas déjà sur le serveur LAN.
  bool _isPhoneClient(BuildContext context) {
    if (LanAccessConfig.isBrowsingOnLanServer) return false;
    if (!kIsWeb) {
      return defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
    }
    return MediaQuery.sizeOf(context).shortestSide < 600;
  }

  Future<void> _persist() async {
    final port = _parsedPort();
    if (port == null) return;
    await LanAccessConfig.save(host: _hostCtrl.text, port: port);
  }

  void _onFieldChanged() {
    _persist();
    setState(() {});
  }

  Future<void> _copyUrl() async {
    final url = _url;
    if (url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copié dans le presse-papiers.')),
    );
  }

  Future<void> _openOnPhone() async {
    final url = _url;
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ouvre manuellement : $url')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ouvre manuellement : $url')),
      );
    }
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phoneClient = _isPhoneClient(context);
    final onLan = LanAccessConfig.isBrowsingOnLanServer;
    final lanUrl = LanAccessConfig.currentBrowsingLanUrl;
    final r = context.responsive;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          phoneClient ? 'Connexion au PC' : 'Accès mobile (Wi‑Fi)',
          style: TextStyle(
            color: context.smartColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [ThemeToggleButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: r.listPadding,
              children: [
                if (onLan) ...[
                  _PhoneConnectedCard(url: lanUrl ?? _url),
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.tips_and_updates_rounded,
                    title: 'Astuce',
                    children: [
                      _StepRow(
                        number: '•',
                        text:
                            'Ajoute cette page à l’écran d’accueil (menu du navigateur → '
                            '« Ajouter à l’écran d’accueil ») pour un accès rapide.',
                      ),
                    ],
                  ),
                ] else if (phoneClient) ...[
                  _InfoCard(
                    icon: Icons.smartphone_rounded,
                    title: 'Sur le téléphone',
                    children: const [
                      _StepRow(
                        number: '1',
                        text:
                            'Le PC doit lancer le serveur (script run_web_lan.ps1) '
                            'et rester allumé.',
                      ),
                      SizedBox(height: 12),
                      _StepRow(
                        number: '2',
                        text:
                            'Téléphone et PC sur le même Wi‑Fi (pas les données mobiles).',
                      ),
                      SizedBox(height: 12),
                      _StepRow(
                        number: '3',
                        text:
                            'Saisis l’IP du PC (affichée dans le terminal) puis appuie sur '
                            '« Ouvrir l’app ». Tu peux aussi scanner le QR affiché sur le PC.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _HostFields(
                    hostCtrl: _hostCtrl,
                    portCtrl: _portCtrl,
                    onChanged: _onFieldChanged,
                  ),
                  const SizedBox(height: 20),
                  if (_url.isNotEmpty) ...[
                    SelectableText(
                      _url,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.smartColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openOnPhone,
                        icon: const Icon(Icons.open_in_browser_rounded),
                        label: const Text('Ouvrir l’app'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _copyUrl,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copier le lien'),
                      ),
                    ),
                  ] else
                    Material(
                      color: context.smartColors.card,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Saisis l’adresse IP du PC (ex. 192.168.1.42).',
                          style: TextStyle(
                            color: context.smartColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    icon: Icons.help_outline_rounded,
                    title: 'Ça ne marche pas ?',
                    children: const [
                      _StepRow(
                        number: '•',
                        text: 'Désactive les données mobiles, reste en Wi‑Fi.',
                      ),
                      SizedBox(height: 8),
                      _StepRow(
                        number: '•',
                        text:
                            'Vérifie que le pare-feu Windows autorise le port 8080.',
                      ),
                      SizedBox(height: 8),
                      _StepRow(
                        number: '•',
                        text:
                            'Sur le PC : ipconfig → adresse IPv4 (192.168.x.x).',
                      ),
                    ],
                  ),
                ] else ...[
                  _InfoCard(
                    icon: Icons.wifi_rounded,
                    title: 'Même réseau Wi‑Fi',
                    children: const [
                      _StepRow(
                        number: '1',
                        text:
                            'Sur le PC, lance le serveur local :\n'
                            'scripts\\run_web_lan.ps1\n'
                            'ou : flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080',
                      ),
                      SizedBox(height: 12),
                      _StepRow(
                        number: '2',
                        text:
                            'Trouve l’adresse IP du PC (ipconfig → IPv4, ex. 192.168.1.42). '
                            'Le téléphone doit être sur le même réseau Wi‑Fi.',
                      ),
                      SizedBox(height: 12),
                      _StepRow(
                        number: '3',
                        text:
                            'Saisis l’IP ci-dessous, affiche le QR et scanne-le avec '
                            'l’appareil photo du téléphone.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_autoDetected && _isPrivateLanHost) ...[
                    Material(
                      color: successColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: successColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Adresse détectée depuis l’URL actuelle (${_hostCtrl.text}).',
                                style: TextStyle(
                                  color: context.smartColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Adresse du PC',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.smartColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  _HostFields(
                    hostCtrl: _hostCtrl,
                    portCtrl: _portCtrl,
                    onChanged: _onFieldChanged,
                  ),
                  const SizedBox(height: 24),
                  if (_url.isNotEmpty) ...[
                    Center(
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: QrImageView(
                          data: _url,
                          version: QrVersions.auto,
                          size: r.qrSize(),
                            gapless: true,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F1B33),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F1B33),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      _url,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.smartColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: FilledButton.icon(
                        onPressed: _copyUrl,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copier le lien'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Scanne le QR avec l’appareil photo du téléphone.',
                        style: TextStyle(
                          color: context.smartColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ] else
                    Material(
                      color: context.smartColors.card,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded,
                                color: context.smartColors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _parsedPort() != null
                                    ? 'Saisis l’adresse IP du PC pour afficher le QR code.'
                                    : 'Port invalide (1–65535).',
                                style: TextStyle(
                                  color: context.smartColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _PhoneConnectedCard extends StatelessWidget {
  const _PhoneConnectedCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: successColor.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: successColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connecté au serveur local',
                    style: TextStyle(
                      color: context.smartColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'L’app tourne sur le PC via le Wi‑Fi. Tu peux te connecter et piloter la maison.',
              style: TextStyle(
                color: context.smartColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 10),
              SelectableText(
                url,
                style: TextStyle(
                  color: context.smartColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HostFields extends StatelessWidget {
  const _HostFields({
    required this.hostCtrl,
    required this.portCtrl,
    required this.onChanged,
  });

  final TextEditingController hostCtrl;
  final TextEditingController portCtrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.smartColors.card,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: hostCtrl,
              onChanged: (_) => onChanged(),
              keyboardType: TextInputType.url,
              autocorrect: false,
              style: TextStyle(color: context.smartColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Adresse IP du PC',
                hintText: '192.168.1.42',
                labelStyle:
                    TextStyle(color: context.smartColors.textSecondary),
                prefixIcon: Icon(Icons.lan_rounded, color: accentColor),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portCtrl,
              onChanged: (_) => onChanged(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(color: context.smartColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Port',
                hintText: '${LanAccessConfig.defaultPort}',
                labelStyle:
                    TextStyle(color: context.smartColors.textSecondary),
                prefixIcon:
                    Icon(Icons.settings_ethernet_rounded, color: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.smartColors.card,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: context.smartColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: context.smartColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
