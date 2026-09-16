import 'package:flutter/material.dart';

import 'package:dollar_trapped/features/auth/screens/auth_page.dart';
import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';

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
      home: initiallyAuthenticated
          ? const UsdKrwPage(initialPage: 2)
          : const AuthPage(),
    );
  }
}
