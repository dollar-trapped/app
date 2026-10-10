import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Broad, translucent curtains bend vertically, rather than sweeping sideways.
abstract final class AuroraEffect {
  static void paint(Canvas canvas, Size size, double phase) {
    if (size.isEmpty) return;
    const colors = [Color(0xFF69E9BE), Color(0xFFAA88E5), Color(0xFF67CEE1)];
    final time = phase * math.pi * 2;
    for (var band = 0; band < 3; band++) {
      double ridge(double x) {
        final position = x / size.width;
        return size.height *
            (.18 +
                band * .24 +
                .16 * math.sin(position * math.pi * 2 + band * 1.8) +
                .13 * math.sin(time + position * math.pi + band * 1.4));
      }

      final thickness = size.height * (.26 + band * .035);
      final curtain = Path()..moveTo(0, ridge(0));
      for (var step = 1; step <= 32; step++) {
        final x = size.width * step / 32;
        curtain.lineTo(x, ridge(x));
      }
      for (var step = 32; step >= 0; step--) {
        final x = size.width * step / 32;
        curtain.lineTo(x, ridge(x) + thickness);
      }
      curtain.close();
      canvas.drawPath(
        curtain,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors[band].withValues(alpha: .08),
              colors[band].withValues(alpha: .48),
              colors[band].withValues(alpha: .02),
            ],
          ).createShader(curtain.getBounds()),
      );
    }
  }
}
