import 'package:flutter/material.dart';
import 'package:smart_home/constants.dart';
import 'package:smart_home/theme/app_branding.dart';
import 'package:smart_home/theme/responsive_layout.dart';
import 'package:smart_home/theme/smart_home_colors.dart';

/// En-tête centré : logo Wi‑Fi + « SMART HOME CONNECT ».
class AppBrandHeader extends StatelessWidget {
  const AppBrandHeader({
    super.key,
    this.compact = false,
    this.showTagline = true,
    this.logoAsset,
  });

  /// Version réduite pour le dashboard (barre fine sous la status bar).
  final bool compact;
  final bool showTagline;

  /// Surcharge [AppBranding.selectedLogoAsset] pour un écran précis.
  final String? logoAsset;

  @override
  Widget build(BuildContext context) {
    final c = context.smartColors;
    final brightness = Theme.of(context).brightness;
    final asset = AppBranding.resolveLogoAsset(
      brightness,
      override: logoAsset,
    );
    final r = ResponsiveLayout.of(context);
    final logoSize = r.scale(compact ? 36.0 : 52.0);
    final titleSize = r.fontSize(compact ? 13.0 : 17.0);
    final useAssetLogo = asset != null;

    return Material(
      color: c.scaffoldBackground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          r.horizontalPadding,
          compact ? r.scale(6) : r.scale(12),
          r.horizontalPadding,
          compact ? r.scale(6) : r.scale(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useAssetLogo)
              Image.asset(
                asset,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) {
                  if (brightness == Brightness.dark &&
                      asset == AppBranding.logoOptionBTransparent) {
                    return Image.asset(
                      AppBranding.logoOptionB,
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) =>
                          _LogoMark(size: logoSize, colors: c),
                    );
                  }
                  return _LogoMark(size: logoSize, colors: c);
                },
              )
            else
              _LogoMark(size: logoSize, colors: c),
            SizedBox(height: compact ? 6 : 10),
            Text(
              AppBranding.appName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                letterSpacing: compact ? 0.8 : 1.2,
                height: 1.1,
                decoration: TextDecoration.none,
                decorationThickness: 0,
              ),
            ),
          if (showTagline && !compact) ...[
            const SizedBox(height: 4),
            Text(
              AppBranding.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }
}

/// Logo vectoriel par défaut : maison + symbole Wi‑Fi.
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
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.wifi_rounded,
            size: size * 0.62,
            color: primaryColor,
          ),
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
