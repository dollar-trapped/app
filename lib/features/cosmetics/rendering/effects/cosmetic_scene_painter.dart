import 'sakura_effect.dart';
import 'starry_effect.dart';
import 'bubble_effect.dart';
import 'aurora_effect.dart';
import 'starlight_wave_effect.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small original scene accents, clipped inside a nickname's background.
class CosmeticScenePainter extends CustomPainter {
  const CosmeticScenePainter({required this.style, required this.phase});
  final String style;
  final double phase;
  static const styles = {
    'sakura_drift',
    'starry_night',
    'bubble_party',
    'aurora',
    'starlight',
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (style == 'aurora' || style == 'starlight') {
      if (style == 'aurora') {
        AuroraEffect.paint(canvas, size, phase);
      } else {
        StarlightWaveEffect.paint(canvas, size, phase);
      }
      canvas.restore();
      return;
    }
    for (var i = 0; i < 10; i++) {
      final progress = (phase + i * .137) % 1;
      // Most detail sits to the right, leaving the name's center calmer.
      final x =
          size.width * (.55 + (i * .173 % .55)) +
          math.sin(progress * math.pi * 2 + i) * 5;
      switch (style) {
        case 'sakura_drift':
          SakuraEffect.paintAccent(canvas, size, i, progress, x);
        case 'starry_night':
          StarryEffect.paintAccent(canvas, size, i, progress, x);
        case 'bubble_party':
          BubbleEffect.paintAccent(canvas, size, i, progress, x);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CosmeticScenePainter oldDelegate) =>
      style != oldDelegate.style || phase != oldDelegate.phase;
}
