import 'package:flutter/material.dart';

/// Couleurs sémantiques (clair / sombre), exposées via [ThemeExtension].
@immutable
class SmartHomeColors extends ThemeExtension<SmartHomeColors> {
  const SmartHomeColors({
    required this.scaffoldBackground,
    required this.card,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.surfaceElevated,
    required this.planCanvasBg,
    required this.planRoomIdle,
    required this.planRoomSelectedFill,
    required this.planBorder,
    required this.planBorderSelected,
    required this.planGrid,
    required this.planHandle,
    required this.planHandleRing,
    required this.planDeviceBg,
    required this.planNameColor,
    required this.planIconColor,
  });

  final Color scaffoldBackground;
  final Color card;
  final Color inputFill;
  final Color textPrimary;
  final Color textSecondary;
  final Color surfaceElevated;
  final Color planCanvasBg;
  final Color planRoomIdle;
  final Color planRoomSelectedFill;
  final Color planBorder;
  final Color planBorderSelected;
  final Color planGrid;
  final Color planHandle;
  final Color planHandleRing;
  final Color planDeviceBg;
  final Color planNameColor;
  final Color planIconColor;

  static final SmartHomeColors dark = SmartHomeColors(
    scaffoldBackground: const Color(0xFF0D1117),
    card: const Color(0xFF161B22),
    inputFill: const Color(0xFF21262D),
    textPrimary: const Color(0xFFE6EDF3),
    textSecondary: const Color(0xFF8B949E),
    surfaceElevated: const Color(0xFF2D333B),
    planCanvasBg: const Color(0xFF0D1117),
    planRoomIdle: const Color(0xE6161B22),
    planRoomSelectedFill: const Color(0x336D9A78),
    planBorder: const Color(0xFF30363D),
    planBorderSelected: const Color(0xFF6D9A78),
    planGrid: const Color(0x14000000),
    planHandle: const Color(0xFF6D9A78),
    planHandleRing: const Color(0xFFE6EDF3),
    planDeviceBg: const Color(0x5A000000),
    planNameColor: const Color(0xFFE6EDF3),
    planIconColor: const Color(0xFFE6EDF3),
  );

  static const SmartHomeColors light = SmartHomeColors(
    scaffoldBackground: Color(0xFFF8FAFC),
    card: Color(0xFFFFFFFF),
    inputFill: Color(0xFFF1F5F9),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    surfaceElevated: Color(0xFFE2E8F0),
    planCanvasBg: Color(0xFFEEF2F7),
    planRoomIdle: Color(0xF2FFFFFF),
    planRoomSelectedFill: Color(0x336D9A78),
    planBorder: Color(0xFFCBD5E1),
    planBorderSelected: Color(0xFF5A8060),
    planGrid: Color(0x14000000),
    planHandle: Color(0xFF5A8060),
    planHandleRing: Color(0xFF0F172A),
    planDeviceBg: Color(0x330F172A),
    planNameColor: Color(0xFF0F172A),
    planIconColor: Color(0xFF0F172A),
  );

  @override
  SmartHomeColors copyWith({
    Color? scaffoldBackground,
    Color? card,
    Color? inputFill,
    Color? textPrimary,
    Color? textSecondary,
    Color? surfaceElevated,
    Color? planCanvasBg,
    Color? planRoomIdle,
    Color? planRoomSelectedFill,
    Color? planBorder,
    Color? planBorderSelected,
    Color? planGrid,
    Color? planHandle,
    Color? planHandleRing,
    Color? planDeviceBg,
    Color? planNameColor,
    Color? planIconColor,
  }) {
    return SmartHomeColors(
      scaffoldBackground: scaffoldBackground ?? this.scaffoldBackground,
      card: card ?? this.card,
      inputFill: inputFill ?? this.inputFill,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      planCanvasBg: planCanvasBg ?? this.planCanvasBg,
      planRoomIdle: planRoomIdle ?? this.planRoomIdle,
      planRoomSelectedFill:
          planRoomSelectedFill ?? this.planRoomSelectedFill,
      planBorder: planBorder ?? this.planBorder,
      planBorderSelected: planBorderSelected ?? this.planBorderSelected,
      planGrid: planGrid ?? this.planGrid,
      planHandle: planHandle ?? this.planHandle,
      planHandleRing: planHandleRing ?? this.planHandleRing,
      planDeviceBg: planDeviceBg ?? this.planDeviceBg,
      planNameColor: planNameColor ?? this.planNameColor,
      planIconColor: planIconColor ?? this.planIconColor,
    );
  }

  @override
  ThemeExtension<SmartHomeColors> lerp(
    ThemeExtension<SmartHomeColors>? other,
    double t,
  ) {
    if (other is! SmartHomeColors) return this;
    return SmartHomeColors(
      scaffoldBackground:
          Color.lerp(scaffoldBackground, other.scaffoldBackground, t)!,
      card: Color.lerp(card, other.card, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      surfaceElevated:
          Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      planCanvasBg: Color.lerp(planCanvasBg, other.planCanvasBg, t)!,
      planRoomIdle: Color.lerp(planRoomIdle, other.planRoomIdle, t)!,
      planRoomSelectedFill:
          Color.lerp(planRoomSelectedFill, other.planRoomSelectedFill, t)!,
      planBorder: Color.lerp(planBorder, other.planBorder, t)!,
      planBorderSelected:
          Color.lerp(planBorderSelected, other.planBorderSelected, t)!,
      planGrid: Color.lerp(planGrid, other.planGrid, t)!,
      planHandle: Color.lerp(planHandle, other.planHandle, t)!,
      planHandleRing:
          Color.lerp(planHandleRing, other.planHandleRing, t)!,
      planDeviceBg: Color.lerp(planDeviceBg, other.planDeviceBg, t)!,
      planNameColor: Color.lerp(planNameColor, other.planNameColor, t)!,
      planIconColor: Color.lerp(planIconColor, other.planIconColor, t)!,
    );
  }
}

extension SmartHomeColorsX on BuildContext {
  SmartHomeColors get smartColors =>
      Theme.of(this).extension<SmartHomeColors>() ?? SmartHomeColors.dark;
}
