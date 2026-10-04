import 'dart:math' as math;
import 'package:flutter/material.dart';

abstract final class StarryEffect {
  static void paintAccent(
    Canvas canvas,
    Size size,
    int i,
    double progress,
    double x,
  ) {
    final y = size.height * (.15 + (i * .219 % .7));
    final radius = 1.5 + (math.sin(progress * math.pi * 2) + 1) * 1.2;
    final star = Path()
      ..moveTo(x, y - radius * 2)
      ..lineTo(x + radius * .5, y - radius * .5)
      ..lineTo(x + radius * 2, y)
      ..lineTo(x + radius * .5, y + radius * .5)
      ..lineTo(x, y + radius * 2)
      ..lineTo(x - radius * .5, y + radius * .5)
      ..lineTo(x - radius * 2, y)
      ..lineTo(x - radius * .5, y - radius * .5)
      ..close();
    canvas.drawPath(
      star,
      Paint()
        ..color = const Color(0xFFFFE5A3).withValues(alpha: .35 + radius / 6),
    );
  }
}
