import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One restrained sweep per four-second cycle, with a quiet pause between sweeps.
class ShimmerEffect extends CustomPainter {
  const ShimmerEffect({required this.phase});
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Fixed foil seams remain visible even when motion is disabled.
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
    );
    final seam = Paint()
      ..color = const Color(0x30A57817)
      ..strokeWidth = .7;
    for (var i = 0; i < 5; i++) {
      final x = size.width * (i + .3) / 5;
      canvas.drawLine(Offset(x, 0), Offset(x + 9, size.height * .45), seam);
      canvas.drawLine(
        Offset(x + 9, size.height * .45),
        Offset(x - 3, size.height),
        seam,
      );
    }
    canvas.restore();
    // The band fades out before looping; reduced motion at phase zero is static.
    if (phase <= 0 || phase >= .45) return;
    final progress = phase / .45;
    final center = size.width * (-.5 + progress * 2);
    final radius = size.width * .13 + 6;
    final alpha = math.sin(progress * math.pi) * .42;
    final band = Rect.fromLTRB(
      center - radius,
      0,
      center + radius,
      size.height,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
    );
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ShimmerEffect oldDelegate) => phase != oldDelegate.phase;
}
