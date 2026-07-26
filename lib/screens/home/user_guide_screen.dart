import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/screens/home/device_setup_guide_screen.dart';
import 'package:smart_home/services/auth_service.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Guide self-service selon le rôle (propriétaire, utilisateur, invité).
class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final c = context.smartColors;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          auth.isHouseOwner
              ? 'Guide propriétaire'
              : auth.isMember
                  ? 'Guide invité'
                  : 'Guide utilisateur',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: AdaptiveContent(
        padding: context.responsive.listPadding,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Icon(Icons.school_outlined, size: 48, color: accentColor),
            const SizedBox(height: 12),
            Text(
              auth.isHouseOwner
                  ? 'Gérez votre maison en autonomie'
                  : 'Utiliser Smart Home Connect',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              auth.isHouseOwner
                  ? 'En tant que propriétaire, vous configurez pièces, appareils, '
                      'invités et RFID sans intervention sur place. '
                      'L’administrateur plateforme intervient seulement pour '
                      'la création de compte et la promotion en propriétaire.'
                  : auth.isMember
                      ? 'Vous pilotez les appareils et pouvez les classer '
                          'dans une pièce (icône déplacer). La configuration '
                          'avancée reste au propriétaire.'
                      : 'Ce guide vous aide à utiliser l’application. '
                          'Demandez le rôle propriétaire à l’administrateur '
                          'pour gérer une maison complète.',
              style: TextStyle(color: c.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 20),
            if (auth.isHouseOwner) ...[
              _permissionsCard(context),
              const SizedBox(height: 16),
              const _SectionTitle(title: 'Configuration maison'),
              const _GuideBlock(
                icon: Icons.meeting_room_outlined,
                title: 'Pièces',
                steps: [
                  'Onglet Pièces → + pour créer (Salon, Chambre, Garage…).',
                  'Icône crayon pour renommer une pièce.',
                  'Menu ⋮ sur l’Accueil pour filtrer par pièce.',
                ],
              ),
              const _GuideBlock(
                icon: Icons.devices_other_rounded,
                title: 'Appareils',
                steps: [
                  'Accueil → bouton + → choisir le type (lampe, DHT, RFID, relais…).',
                  'Indiquer un nom et une broche GPIO (2 à 53).',
                  'Icône déplacer sur une carte → changer de pièce.',
                  'Icône corbeille → supprimer (propriétaire uniquement).',
                  'Icône broche → modifier le GPIO.',
                ],
                actionLabel: 'Guide détaillé appareils',
              ),
              const _GuideBlock(
                icon: Icons.group_add_rounded,
                title: 'Invités et membres',
                steps: [
                  'Paramètres → Mes invités : voir le code maison (5 chiffres).',
                  'Partagez le code par SMS ou WhatsApp à votre famille.',
                  'Bouton Nouveau code pour un invité temporaire (30 jours).',
                  'Liste des membres → icône retirer pour révoquer l’accès.',
                ],
              ),
              const _GuideBlock(
                icon: Icons.nfc_rounded,
                title: 'RFID et portes',
                steps: [
                  'Paramètres → Accès RFID & portes.',
                  'Onglet Lecteurs : badges autorisés par lecteur.',
                  'Onglet Portes : lier un servomoteur à un lecteur.',
                  'Onglet Badges : ajouter ou réassigner un badge.',
                ],
              ),
              const _GuideBlock(
                icon: Icons.insights_rounded,
                title: 'Tableau de bord',
                steps: [
                  'Bandeau sous « Ma maison » : appareils allumés, total, conso estimée.',
                  'Indicateur Maison en ligne = ESP32 connecté à Firestore.',
                ],
              ),
              const _GuideBlock(
                icon: Icons.qr_code_2_rounded,
                title: 'Accès depuis le téléphone (Wi‑Fi)',
                steps: [
                  'Paramètres → Accès mobile (Wi‑Fi).',
                  'PC et téléphone sur le même réseau → scanner le QR code.',
                ],
              ),
              const SizedBox(height: 8),
              const _SectionTitle(title: 'Rôle administrateur plateforme'),
              _adminOnlyCard(context),
            ] else if (auth.isMember) ...[
              _permissionsCard(context),
              const SizedBox(height: 16),
              const _GuideBlock(
                icon: Icons.toggle_on_outlined,
                title: 'Piloter les appareils',
                steps: [
                  'Accueil : interrupteur ON/OFF sur lampe, relais, etc.',
                  'Capteurs en lecture seule (température, mouvement…).',
                  'Icône déplacer sur une carte → ranger l’appareil dans une pièce.',
                  'Onglet Pièces → touchez une pièce pour voir et déplacer les appareils.',
                  'Menu ⋮ sur l’Accueil pour filtrer par pièce.',
                ],
              ),
              const _GuideBlock(
                icon: Icons.exit_to_app_rounded,
                title: 'Quitter la maison',
                steps: [
                  'Profil → Quitter la maison.',
                  'Vous perdrez l’accès aux appareils du propriétaire.',
                ],
              ),
            ] else ...[
              _permissionsCard(context),
              const SizedBox(height: 16),
              const _GuideBlock(
                icon: Icons.badge_outlined,
                title: 'Devenir propriétaire',
                steps: [
                  'Contactez l’administrateur plateforme (email / téléphone support).',
                  'Il promeut votre compte en « Propriétaire » depuis l’interface admin.',
                  'Déconnectez-vous puis reconnectez-vous.',
                  'Vous accédez alors à toutes les fonctions de gestion maison.',
                ],
              ),
              if (auth.canAddDevices) ...[
                const _GuideBlock(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Ajouter des appareils (utilisateur)',
                  steps: [
                    'Pièces → + pour créer une pièce.',
                    'Accueil → + pour ajouter un appareil.',
                    'Déplacer : icône flèches sur la carte.',
                  ],
                  actionLabel: 'Guide détaillé appareils',
                ),
              ],
              const _GuideBlock(
                icon: Icons.home_work_outlined,
                title: 'Rejoindre une maison existante',
                steps: [
                  'Demandez le code à 5 chiffres au propriétaire.',
                  'Paramètres → Rejoindre une maison → saisir le code.',
                ],
              ),
            ],
            const SizedBox(height: 16),
            _faqCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _permissionsCard(BuildContext context) {
    final auth = AuthService.instance;
    final c = context.smartColors;

    final allowed = auth.isHouseOwner
        ? const [
            'Créer / renommer des pièces',
            'Ajouter, déplacer, supprimer des appareils',
            'Modifier les broches GPIO',
            'Inviter et retirer des membres',
            'Gérer badges RFID et portes',
            'Voir stats et consommation estimée',
          ]
        : auth.isMember
            ? const [
                'Allumer / éteindre les actionneurs',
                'Consulter capteurs et dashboard',
                'Classer un appareil dans une pièce',
                'Changer de pièce affichée sur l’Accueil',
              ]
            : auth.canAddDevices
                ? const [
                    'Ajouter des pièces et appareils',
                    'Choisir une broche à l’ajout (+) ou icône sur la carte',
                    'Voir les broches déjà occupées (nom de l’appareil)',
                    'Déplacer un appareil entre pièces',
                    'Piloter ON/OFF',
                    'Rejoindre une maison par code',
                  ]
                : const [
                    'Se connecter et consulter le profil',
                  ];

    final denied = auth.isHouseOwner
        ? const [
            'Gérer les autres maisons (admin plateforme)',
            'Créer des comptes administrateur',
          ]
        : auth.isMember
            ? const [
                'Ajouter ou supprimer des appareils',
                'Créer ou renommer des pièces',
                'Choisir ou modifier une broche GPIO',
                'Inviter d’autres personnes',
              ]
            : auth.canAddDevices
                ? const [
                    'Supprimer des appareils (réservé propriétaire)',
                    'Gérer invités, RFID et réglages avancés',
                    'Détails matériels ESP32 / Arduino (admin plateforme)',
                  ]
                : const [
                    'Supprimer des appareils (réservé propriétaire)',
                    'Modifier broches GPIO',
                    'Gérer les invités',
                  ];

    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vos permissions',
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Autorisé',
              style: TextStyle(color: successColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final item in allowed)
              _permRow(context, item, allowed: true),
            const SizedBox(height: 10),
            Text(
              'Non autorisé',
              style: TextStyle(color: errorColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            for (final item in denied)
              _permRow(context, item, allowed: false),
          ],
        ),
      ),
    );
  }

  Widget _permRow(BuildContext context, String text, {required bool allowed}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            allowed ? Icons.check_circle_outline : Icons.block_outlined,
            size: 16,
            color: allowed ? successColor : context.smartColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.smartColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminOnlyCard(BuildContext context) {
    final c = context.smartColors;
    return Material(
      color: c.inputFill,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings_outlined, color: accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Intervention admin (à distance)',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Même avec des milliers d’utilisateurs, l’admin n’a pas besoin '
              'de se déplacer. Il intervient uniquement pour :',
              style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            for (final s in const [
              'Créer un compte utilisateur',
              'Promouvoir un compte en « Propriétaire »',
              'Réinitialiser un mot de passe (console Firebase)',
              'Supprimer un compte ou une maison entière',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $s',
                  style: TextStyle(color: c.textSecondary, fontSize: 13),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Tout le reste (appareils, pièces, invités, RFID) est à votre charge '
              'via ce guide et les menus Paramètres / Accueil.',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqCard(BuildContext context) {
    final c = context.smartColors;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questions fréquentes',
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _faq(context, 'Je ne vois pas le bouton +',
                'Vérifiez que vous n’êtes pas invité (membre). '
                    'Créez au moins une pièce dans l’onglet Pièces.'),
            _faq(context, 'Broche déjà utilisée',
                'Le sélecteur de broche affiche les broches libres et celles '
                    'déjà prises (avec le nom de l’appareil). Choisis une '
                    'broche libre ou une autre entre 2 et 53.'),
            _faq(context, 'Maison hors ligne',
                'L’ESP32 n’est pas connecté. Vérifiez Wi‑Fi et alimentation.'),
            _faq(context, 'Invité ne peut pas ajouter d’appareil',
                'Normal : le propriétaire (ou un utilisateur autorisé) ajoute '
                    'les appareils et choisit les broches ; le sélecteur indique '
                    'celles déjà prises. L’invité pilote ON/OFF et peut classer '
                    'un appareil dans une pièce existante.'),
          ],
        ),
      ),
    );
  }

  Widget _faq(BuildContext context, String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: TextStyle(
              color: context.smartColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            a,
            style: TextStyle(
              color: context.smartColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
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
      padding: const EdgeInsets.only(left: 4, bottom: 10),
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

class _GuideBlock extends StatelessWidget {
  const _GuideBlock({
    required this.icon,
    required this.title,
    required this.steps,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final List<String> steps;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accentColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${i + 1}. ',
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          steps[i],
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (actionLabel != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeviceSetupGuideScreen(),
                        ),
                      );
                    },
                    icon: Icon(Icons.arrow_forward_rounded, color: accentColor),
                    label: Text(
                      actionLabel!,
                      style: TextStyle(color: accentColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
