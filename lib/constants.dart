import 'package:flutter/cupertino.dart';

const double defaultPadding = 20.0;

// --- Palette sombre bleu nuit (accent vert sage) ---

/// Fond principal — bleu marine profond.
const Color bgColor = Color(0xFF0F1B33);

/// Cartes / panneaux — bleu légèrement plus clair.
const Color cardColor = Color(0xFF162847);

/// Accent unique (CTA, focus, liens) — vert sage désaturé.
const Color primaryColor = Color(0xFF6D9A78);

/// Alias : même teinte (pas de second accent néon type cyan).
const Color accentColor = Color(0xFF6D9A78);

/// Champs remplis, surfaces enfoncées.
const Color inputFillColor = Color(0xFF1C3255);

/// Bordures discrètes (outline champs, séparateurs).
const Color borderSubtle = Color(0xFF2E4A6E);

const Color appBg = bgColor;
const Color surfaceColor = cardColor;

/// Texte principal — blanc cassé bleuté.
const Color textPrimary = Color(0xFFE8EEF8);

/// Texte secondaire / labels.
const Color textSecondary = Color(0xFF8FA3C4);

const Color disabledColor = Color(0xFF6E7681);

const Color successColor = Color(0xFF6D9A78);
const Color warningColor = Color(0xFFD4A72C);
const Color errorColor = Color(0xFFDA6B6B);
const Color infoColor = Color(0xFF6E8A9E);

const Color constColor = textPrimary;

const Color surfaceElevated = Color(0xFF243B5E);
const Color glassColor = Color(0x660F1B33);

/// Gradients utilitaires (ex. AC) — restent dans les tons verts/gris, pas arc-en-ciel.
const Color bgGradientBotomStart = Color(0xFF5D8267);
const Color bgGradientBotomStartQ = Color(0xFF6D9A78);
const Color bgGradientBottomMiddle = Color(0xFF3D5244);
const Color bgGradientBotomEndQ = Color(0xFF4A5C52);
const Color bgGradientBotomEnd = Color(0xFF243B5E);

Color getColor(double progress) {
  var first = mapToRange(progress, 0, 1, 0, 0.25);
  var second = mapToRange(progress, 0, 1, 0.25, 0.5);
  var third = mapToRange(progress, 0, 1, 0.5, 0.75);
  var forth = mapToRange(progress, 0, 1, 0.75, 1);

  if (progress >= 0 && progress <= 0.25) {
    return Color.lerp(bgGradientBotomStart, bgGradientBotomStartQ, first) ??
        bgGradientBotomStart;
  } else if (progress > 0.25 && progress <= 0.5) {
    return Color.lerp(bgGradientBotomStartQ, bgGradientBottomMiddle, second) ??
        bgGradientBotomStartQ;
  } else if (progress > 0.5 && progress <= 0.75) {
    return Color.lerp(bgGradientBottomMiddle, bgGradientBotomEndQ, third) ??
        bgGradientBottomMiddle;
  } else if (progress > 0.75 && progress <= 1) {
    return Color.lerp(bgGradientBotomEndQ, bgGradientBotomEnd, forth) ??
        bgGradientBotomEndQ;
  } else {
    return bgGradientBottomMiddle;
  }
}

double mapToRange(
    double value, double start, double end, double oldStart, double oldEnd) {
  var oldRange = (oldEnd - oldStart);
  var newRange = (end - start);
  return (((value - oldStart) * newRange) / oldRange) + start;
}
