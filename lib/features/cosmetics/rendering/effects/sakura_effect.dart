import 'dart:math' as math;
import 'package:flutter/material.dart';

abstract final class SakuraEffect {
  static void paintAccent(
    Canvas canvas,
    Size size,
    int i,
    double progress,
    double x,
  ) {
    final y = progress * (size.height + 16) - 8;
    canvas.save();
    canvas.translate(x - progress * size.width * .2, y);
    canvas.rotate(progress * math.pi * 2 + i);
    final petal = Path()
      ..moveTo(0, -4)
      ..quadraticBezierTo(7, -1, 0, 5)
      ..quadraticBezierTo(-5, 0, 0, -4);
    canvas.drawPath(
      petal,
      Paint()
        ..color = Color.lerp(
          const Color(0xFFC94F88),
          const Color(0xFFF28CAC),
          i / 10,
        )!.withValues(alpha: .65),
    );
    canvas.restore();
  }
}
