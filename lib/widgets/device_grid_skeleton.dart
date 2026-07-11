import 'package:flutter/material.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// Placeholders animés pour la grille d’appareils pendant le chargement.
class DeviceGridSkeleton extends StatefulWidget {
  const DeviceGridSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  State<DeviceGridSkeleton> createState() => _DeviceGridSkeletonState();
}

class _DeviceGridSkeletonState extends State<DeviceGridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final r = context.responsive;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.itemCount > 0 ? widget.itemCount : r.skeletonGridCount,
      gridDelegate: r.deviceGridDelegate,
      itemBuilder: (_, __) {
        return AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t =
                CurvedAnimation(parent: _c, curve: Curves.easeInOut).value;
            final fill = Color.lerp(
              c.inputFill,
              c.textSecondary.withValues(alpha: 0.12),
              t,
            )!;
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: c.textSecondary.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: c.textSecondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 10,
                    width: 72,
                    decoration: BoxDecoration(
                      color: c.textSecondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 48,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c.textSecondary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
