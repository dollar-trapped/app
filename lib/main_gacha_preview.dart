import 'package:flutter/material.dart';
import 'features/gacha/preview/gacha_presentation_preview.dart';

/// Dedicated offline entry point for profile builds. Never the release entry point.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4E8E64)),
        useMaterial3: true,
      ),
      home: const GachaPresentationPreview(),
    ),
  );
}
