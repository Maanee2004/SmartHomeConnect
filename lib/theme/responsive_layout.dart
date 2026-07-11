import 'package:flutter/material.dart';

/// Breakpoints et helpers pour adapter l'UI au telephone, tablette et desktop.
class ResponsiveLayout {
  ResponsiveLayout._(this._size);

  final Size _size;

  static ResponsiveLayout of(BuildContext context) =>
      ResponsiveLayout._(MediaQuery.sizeOf(context));

  double get width => _size.width;
  double get height => _size.height;
  double get shortestSide => _size.shortestSide;

  bool get isCompact => width < 600;
  bool get isTablet => width >= 600 && width < 1200;
  bool get isDesktop => width >= 1200;
  bool get isLandscape => width > height;

  /// Largeur max du contenu principal (shell, formulaires).
  double get maxContentWidth {
    if (isDesktop) return 1100;
    if (isTablet) return 840;
    return width;
  }

  /// Padding horizontal des pages.
  double get horizontalPadding {
    if (isDesktop) return 32;
    if (isTablet) return 24;
    if (width < 360) return 12;
    return 16;
  }

  /// Padding vertical des pages.
  double get verticalPadding {
    if (isDesktop) return 20;
    if (isTablet) return 14;
    return 8;
  }

  EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      );

  EdgeInsets get listPadding => EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding + 8,
      );

  double scale(double base) {
    if (width < 340) return base * 0.9;
    if (width < 600) return base;
    if (width < 900) return base * 1.04;
    return base * 1.08;
  }

  double fontSize(double base) => scale(base);

  double iconSize(double base) => scale(base);

  double qrSize() {
    final side = shortestSide;
    if (side < 340) return side * 0.55;
    if (side < 600) return 220;
    if (side < 900) return 260;
    return 280;
  }

  /// Grille d'appareils : hauteur genereuse pour eviter les overflow.
  SliverGridDelegate get deviceGridDelegate {
    if (width < 380) {
      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        childAspectRatio: isLandscape ? 1.85 : 1.45,
      );
    }

    final maxExtent = width < 600 ? 200.0 : (width < 900 ? 240.0 : 280.0);
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxExtent,
      mainAxisSpacing: gridSpacing,
      crossAxisSpacing: gridSpacing,
      childAspectRatio: _gridAspectRatio(maxExtent),
    );
  }

  double _gridAspectRatio(double maxExtent) {
    if (width < 600) return 0.58;
    if (width < 900) return 0.68;
    return 0.75;
  }

  bool get isTightWidth => width < 400;

  double get gridSpacing => width < 360 ? 6 : 8;

  int get skeletonGridCount {
    if (width < 380) return 2;
    if (width < 900) return 4;
    return 6;
  }

  /// Deux boutons cote a cote, ou empiles sur ecran etroit.
  Widget buttonRow(List<Widget> buttons, {double spacing = 8}) {
    if (width < 380) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            buttons[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }
}

extension ResponsiveContext on BuildContext {
  ResponsiveLayout get responsive => ResponsiveLayout.of(this);
}

/// Centre le contenu et limite la largeur sur grands ecrans.
class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? r.maxContentWidth,
        ),
        child: Padding(
          padding: padding ?? r.pagePadding,
          child: child,
        ),
      ),
    );
  }
}
