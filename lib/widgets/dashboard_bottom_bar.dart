import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Barre de navigation basse style smartphone : icône + libellé.
class DashboardBottomBar extends StatelessWidget {
  const DashboardBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const labels = ['Accueil', 'Pièces', 'Profil', 'Paramètres'];

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.home_rounded, label: 'Accueil'),
    _NavItem(icon: Icons.meeting_room_rounded, label: 'Pièces'),
    _NavItem(icon: Icons.person_rounded, label: 'Profil'),
    _NavItem(icon: Icons.settings_rounded, label: 'Paramètres'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final r = context.responsive;
    final iconSize = r.iconSize(26);
    final labelSize = r.fontSize(11);

    return Material(
      color: c.scaffoldBackground,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: c.planBorder.withValues(alpha: 0.55),
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _BottomNavItem(
                      item: _items[i],
                      selected: selectedIndex == i,
                      iconSize: iconSize,
                      labelSize: labelSize,
                      onPressed: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.item,
    required this.selected,
    required this.iconSize,
    required this.labelSize,
    required this.onPressed,
  });

  final _NavItem item;
  final bool selected;
  final double iconSize;
  final double labelSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final color = selected ? primaryColor : c.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: color, size: iconSize),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: TextStyle(
                  color: color,
                  fontSize: labelSize,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
