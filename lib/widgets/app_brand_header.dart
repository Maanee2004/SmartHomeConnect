import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/l10n/app_localizations.dart';
import 'package:smart_home/theme/app_branding.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// En-tête : icône en haut, texte en dessous.
class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({
    super.key,
    this.compact = false,
    this.showTagline = true,
    this.logoAsset,
  });

  final bool compact;
  final bool showTagline;
  final String? logoAsset;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final brightness = Theme.of(context).brightness;
    final asset = AppBranding.resolveLogoAsset(
      override: logoAsset,
      compact: compact,
      brightness: brightness,
    );
    final r = ResponsiveLayout.of(context);

    final iconSize = r.scale(compact ? 22.0 : 40.0);
    final titleSize = r.fontSize(compact ? 8.5 : 12.0);
    final taglineSize = r.fontSize(compact ? 7.5 : 10.0);
    final gapIconText = compact ? 3.0 : 6.0;
    final gapTitleTagline = compact ? 1.0 : 2.0;

    return Material(
      color: c.scaffoldBackground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          r.horizontalPadding,
          compact ? r.scale(2) : r.scale(6),
          r.horizontalPadding,
          compact ? r.scale(2) : r.scale(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              asset,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) =>
                  _LogoMark(size: iconSize, colors: c),
            ),
            SizedBox(height: gapIconText),
            Text(
              AppBranding.appName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                letterSpacing: compact ? 0.4 : 0.8,
                height: 1.0,
              ),
            ),
            if (showTagline) ...[
              SizedBox(height: gapTitleTagline),
              Text(
                context.l10n.tagline,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: taglineSize,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size, required this.colors});

  final double size;
  final SmartHomeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withValues(alpha: 0.35),
            colors.card,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.wifi_rounded, size: size * 0.62, color: primaryColor),
          Positioned(
            bottom: size * 0.14,
            child: Icon(
              Icons.home_rounded,
              size: size * 0.28,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
