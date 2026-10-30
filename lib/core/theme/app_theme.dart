import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static final light = _build(Brightness.light, AppColors.light);
  static final dark = _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors colors) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF00B235),
          brightness: brightness,
        ).copyWith(
          primary: colors.action,
          onPrimary: colors.onAction,
          surface: colors.background,
          onSurface: colors.ink,
          onSurfaceVariant: colors.muted,
          outline: colors.line,
          error: colors.error,
        );
    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.line,
      useMaterial3: true,
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(bodyColor: colors.ink, displayColor: colors.ink),
      iconTheme: IconThemeData(color: colors.muted),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.muted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.ink,
        systemOverlayStyle: overlay(brightness),
      ),
    );
  }

  static SystemUiOverlayStyle overlay(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: dark
          ? AppColors.dark.background
          : AppColors.light.background,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
    );
  }
}
