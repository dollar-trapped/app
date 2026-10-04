import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Small original scene accents, clipped inside a nickname's background.
class CosmeticScenePainter extends CustomPainter {
  const CosmeticScenePainter({required this.style, required this.phase});
  final String style;
  final double phase;
  static const styles = {'sakura_drift', 'starry_night', 'bubble_party'};

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < 10; i++) {
      final progress = (phase + i * .137) % 1;
      // Most detail sits to the right, leaving the name's center calmer.
      final x =
          size.width * (.55 + (i * .173 % .55)) +
          math.sin(progress * math.pi * 2 + i) * 5;
      if (style == 'sakura_drift') {
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
      } else if (style == 'starry_night') {
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
            ..color = const Color(
              0xFFFFE5A3,
            ).withValues(alpha: .35 + radius / 6),
        );
      } else if (style == 'bubble_party') {
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(CosmeticScenePainter oldDelegate) =>
      style != oldDelegate.style || phase != oldDelegate.phase;
}
