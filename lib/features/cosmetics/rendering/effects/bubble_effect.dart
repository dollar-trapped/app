import 'package:flutter/material.dart';

abstract final class BubbleEffect {
  static void paintAccent(
    Canvas canvas,
    Size size,
    int i,
    double progress,
    double x,
  ) {
    final y = size.height + 8 - progress * (size.height + 16);
    final radius = 3.0 + i % 3 * 1.5;
    final color = [
      const Color(0xFFC077C8),
      const Color(0xFF66AFC8),
      const Color(0xFFECA06D),
    ][i % 3];
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()..color = color.withValues(alpha: .3),
    );
    canvas.drawCircle(
      Offset(x, y),
      radius,
      Paint()
        ..color = color.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    canvas.drawCircle(
      Offset(x - radius * .3, y - radius * .3),
      radius * .18,
      Paint()..color = Colors.white.withValues(alpha: .85),
    );
  }
}
