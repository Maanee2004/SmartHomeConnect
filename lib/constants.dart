import 'package:flutter/cupertino.dart';

const double defaultPadding = 20.0;

/// Palette principale (cohérence app).
const Color bgColor = Color(0xFF0F172A);
const Color cardColor = Color(0xFF1E293B);
const Color primaryColor = Color(0xFF22C55E); // vert glow
const Color accentColor = Color(0xFF06B6D4); // turquoise

/// Fond des champs (login / register).
const Color inputFillColor = Color(0xFF020617);

const Color appBg = bgColor;
const Color surfaceColor = cardColor;
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0xFF9CA3AF);
const Color disabledColor = Color(0xFFD3D3D3);

const Color successColor = Color(0xFF4CAF50);
const Color warningColor = Color(0xFFFF9800);
const Color errorColor = Color(0xFFF44336);
const Color infoColor = Color(0xFF2196F3);

/// Alias historiques.
const Color constColor = textPrimary;

const Color surfaceElevated = Color(0xFF334155);
const Color glassColor = Color(0x660F172A);

const Color bgGradientBotomStart = accentColor;
const Color bgGradientBotomStartQ = primaryColor;
const Color bgGradientBottomMiddle = cardColor;
const Color bgGradientBotomEndQ = warningColor;
const Color bgGradientBotomEnd = errorColor;

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
