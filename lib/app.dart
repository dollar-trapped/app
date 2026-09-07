import 'package:flutter/material.dart';

import 'features/auth/presentation/pages/auth_page.dart';

class DollarTrappedApp extends StatelessWidget {
  const DollarTrappedApp({super.key});

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
      home: const AuthPage(), //
    );
  }
}
