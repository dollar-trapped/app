import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fine horizontal waves carry tiny glints; no stationary star particles.
abstract final class StarlightWaveEffect {
  static void paint(Canvas canvas, Size size, double phase) {
    if (size.isEmpty) return;
    const colors = [Color(0xFF8ECFF1), Color(0xFFB9B2F5), Color(0xFF76BCE7)];
    for (var wave = 0; wave < 3; wave++) {
      double height(double x) =>
          size.height *
          ([.18, .78, .93][wave] +
              .07 *
                  math.sin((x / size.width * 2 - phase * 2) * math.pi + wave));
      final path = Path()..moveTo(0, height(0));
      for (var step = 1; step <= 40; step++) {
        final x = size.width * step / 40;
        path.lineTo(x, height(x));
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[wave].withValues(alpha: .12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = colors[wave].withValues(alpha: .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      for (var glint = 0; glint < 2; glint++) {
        final progress = (phase + wave * .29 + glint * .5) % 1;
        final x = size.width * progress;
        final y = height(x);
        final glow = math.sin(progress * math.pi);
        canvas.drawCircle(
          Offset(x, y),
          2.5,
          Paint()..color = colors[wave].withValues(alpha: .2 * glow),
        );
        canvas.drawCircle(
          Offset(x, y),
          .9,
          Paint()..color = Colors.white.withValues(alpha: .9 * glow),
        );
      }
    }
  }
}
