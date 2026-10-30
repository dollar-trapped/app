import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

import 'package:dollar_trapped/features/auth/screens/auth_page.dart';
import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';

class DollarTrappedApp extends StatefulWidget {
  const DollarTrappedApp({
    super.key,
    this.initiallyAuthenticated = false,
    this.themeController,
  });

  final bool initiallyAuthenticated;
  final ThemeController? themeController;

  @override
  State<DollarTrappedApp> createState() => _DollarTrappedAppState();
}

class _DollarTrappedAppState extends State<DollarTrappedApp> {
  late final ThemeController _theme;

  @override
  void initState() {
    super.initState();
    _theme = widget.themeController ?? ThemeController();
    if (widget.themeController == null) unawaited(_theme.load());
  }

  @override
  void dispose() {
    if (widget.themeController == null) _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeController>.value(
      value: _theme,
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: '달러물림',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: theme.mode,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.overlay(Theme.of(context).brightness),
            child: child!,
          ),
          home: widget.initiallyAuthenticated
              ? const UsdKrwPage(initialPage: 2, checkConsent: true)
              : const AuthPage(),
        ),
      ),
    );
  }
}
