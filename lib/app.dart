import 'package:flutter/material.dart';

import 'features/auth/presentation/pages/auth_page.dart';
import 'features/home/presentation/pages/usd_krw_page.dart';

class DollarTrappedApp extends StatelessWidget {
  const DollarTrappedApp({super.key, this.initiallyAuthenticated = false});

  final bool initiallyAuthenticated;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '달러물림',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00B235)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: initiallyAuthenticated ? const UsdKrwPage() : const AuthPage(),
    );
  }
}
