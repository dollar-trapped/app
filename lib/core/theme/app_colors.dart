import 'package:flutter/material.dart';

/// Interface colors only. Cosmetic item colors keep their server appearance.
class AppColors {
  const AppColors._({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.soft,
    required this.action,
    required this.onAction,
    required this.forest,
    required this.error,
    required this.errorSurface,
    required this.negative,
    required this.marketRise,
    required this.marketFall,
  });

  final Color background, surface, ink, muted, line, soft;
  final Color action, onAction, forest, error, errorSurface, negative;
  final Color marketRise, marketFall;

  TextStyle get caption => TextStyle(
    fontSize: 12,
    height: 1.5,
    color: muted,
    fontWeight: FontWeight.w400,
  );

  TextStyle get title => TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    color: ink,
  );

  static const light = AppColors._(
    background: Colors.white,
    surface: Color(0xFFF5F7F5),
    ink: Color(0xFF151916),
    muted: Color(0xFF667069),
    line: Color(0xFFE1E6E2),
    soft: Color(0xFFEAF7EE),
    action: Color(0xFF008A29),
    onAction: Colors.white,
    forest: Color(0xFF163C2B),
    error: Color(0xFFB3261E),
    errorSurface: Color(0xFFFCEDEA),
    negative: Color(0xFF2463B5),
    marketRise: Color(0xFFD63B3B),
    marketFall: Color(0xFF2464C4),
  );

  static AppColors of(BuildContext context) => light;
}
