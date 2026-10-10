import 'dart:math' as math;
import 'package:flutter/material.dart';

abstract final class DesertEffect {
  static void paint(Canvas canvas, Size size, double phase) {
    if (size.isEmpty) return;
    final dune = Path()
      ..moveTo(0, size.height * .72)
      ..quadraticBezierTo(
        size.width * .3,
        size.height * .4,
        size.width * .65,
        size.height * .8,
      )
      ..quadraticBezierTo(
        size.width * .85,
        size.height * .55,
        size.width,
        size.height * .7,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(dune, Paint()..color = const Color(0xFFE9C18C));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .88, size.width, size.height * .12),
      Paint()..color = const Color(0xFFD6A66C),
    );
    final radius = (size.height * .23).clamp(4.0, 12.0);
    final x = -radius + phase * (size.width + radius * 2);
    final y =
        size.height * .87 - radius - math.sin(phase * math.pi * 6).abs() * 1.5;
    canvas.save();
    canvas.translate(x, y);
    // Angular distance follows travel, giving the tumbleweed a rolling gait.
    canvas.rotate(x / radius);
    final twig = Paint()
      ..color = const Color(0xFF916039).withValues(alpha: .8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    for (var ring = 0; ring < 3; ring++) {
      canvas.save();
      canvas.rotate(ring * math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 2,
          height: radius * 1.25,
        ),
        twig,
      );
      canvas.restore();
    }
    for (var branch = 0; branch < 7; branch++) {
      final angle = branch * math.pi * 2 / 7;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle), math.sin(angle)) * radius,
        twig,
      );
    }
    canvas.restore();
  }
}
