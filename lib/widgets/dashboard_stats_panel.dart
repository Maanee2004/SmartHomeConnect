import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/l10n/app_localizations.dart';
import 'package:smart_home/models/home_dashboard_stats.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Bandeau statistiques : allumés, total, conso estimée.
class DashboardStatsPanel extends StatelessWidget {
  const DashboardStatsPanel({
    super.key,
    required this.stats,
    this.scopeLabel,
  });

  final HomeDashboardStats stats;
  final String? scopeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final r = context.responsive;
    final l = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.insights_rounded, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              l.dashboardStatsTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (scopeLabel != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scopeLabel!,
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: r.isCompact ? 1.85 : 2.15,
          children: [
            _StatTile(
              icon: Icons.power_rounded,
              label: l.statOn,
              value: '${stats.onCount}',
              subtitle: l.statOnSubtitle,
              color: warningColor,
            ),
            _StatTile(
              icon: Icons.home_work_outlined,
              label: l.statTotal,
              value: '${stats.total}',
              subtitle: l.statTotalSubtitle(stats.sensorCount, stats.actuatorCount),
              color: accentColor,
            ),
            _StatTile(
              icon: Icons.bolt_rounded,
              label: l.statConsumption,
              value: stats.wattsLabel,
              subtitle: l.statConsumptionSubtitle,
              color: infoColor,
            ),
          ],
        ),
        if (stats.instantWatts > 0) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (stats.instantWatts / 500).clamp(0.05, 1.0),
              minHeight: 4,
              backgroundColor: c.inputFill,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l.loadEstimate500,
            style: TextStyle(color: c.textSecondary, fontSize: 10),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(color: c.textSecondary, fontSize: 9, height: 1.1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
