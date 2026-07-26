import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Guide pas à pas : ajouter et déplacer des appareils (utilisateurs).
class DeviceSetupGuideScreen extends StatelessWidget {
  const DeviceSetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Guide appareils',
          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: AdaptiveContent(
        padding: context.responsive.listPadding,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Icon(Icons.menu_book_rounded, size: 48, color: accentColor),
            const SizedBox(height: 12),
            Text(
              'Configurer votre maison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ce guide explique comment ajouter des capteurs et actionneurs, '
              'et les organiser par pièce.',
              style: TextStyle(color: c.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 24),
            const _GuideStep(
              number: 1,
              title: 'Créer une pièce',
              body:
                  'Onglet **Pièces** → bouton **+** en haut.\n'
                  'Exemples : Salon, Chambre, Garage, Entrée.',
              icon: Icons.meeting_room_outlined,
            ),
            const _GuideStep(
              number: 2,
              title: 'Choisir la pièce active',
              body:
                  'Sur l’**Accueil**, touchez **⋮** (menu) → sélectionnez la pièce '
                  'ou **Toute la maison**.',
              icon: Icons.filter_list_rounded,
            ),
            const _GuideStep(
              number: 3,
              title: 'Ajouter un appareil',
              body:
                  'Bouton **+** en haut à droite de l’Accueil.\n'
                  'Choisissez le type (lampe, relais, capteur DHT, RFID…), '
                  'donnez un nom et une broche GPIO si demandé.',
              icon: Icons.add_circle_outline_rounded,
            ),
            const _GuideStep(
              number: 4,
              title: 'Déplacer vers une autre pièce',
              body:
                  'Sur la carte de l’appareil, touchez l’icône **déplacer** '
                  '(flèche) → choisissez la nouvelle pièce.\n'
                  'L’appareil reste connecté, seul son emplacement change.',
              icon: Icons.open_with_rounded,
            ),
            const _GuideStep(
              number: 5,
              title: 'Piloter l’appareil',
              body:
                  'Actionneurs : interrupteur ON/OFF sur la carte.\n'
                  'Capteurs : température, humidité, mouvement… en lecture seule.',
              icon: Icons.toggle_on_outlined,
            ),
            const SizedBox(height: 16),
            Material(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Exemples rapides',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _example(context, 'Lampe salon', 'RELAIS ou LAMPE, broche 7'),
                    _example(context, 'Capteur température', 'DHT, broche 4'),
                    _example(context, 'Porte garage', 'SERVO + lecteur RFID'),
                    _example(context, 'Détecteur mouvement', 'PIR, broche 2'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'À l’ajout (+) ou via l’icône broche sur la carte, le sélecteur '
              'montre les broches libres et celles déjà utilisées (nom de '
              'l’appareil). Les infos matérielles ESP32 (broches réservées) '
              'sont visibles uniquement pour l’administrateur plateforme. '
              'La suppression reste réservée au propriétaire.',
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _example(BuildContext context, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: accentColor, fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: context.smartColors.textPrimary,
                  fontSize: 13,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$title — ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: detail,
                    style: TextStyle(
                      color: context.smartColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.number,
    required this.title,
    required this.body,
    required this.icon,
  });

  final int number;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentColor.withValues(alpha: 0.2),
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: accentColor),
                        const SizedBox(width: 6),
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
                    const SizedBox(height: 6),
                    Text(
                      body.replaceAll('**', ''),
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
