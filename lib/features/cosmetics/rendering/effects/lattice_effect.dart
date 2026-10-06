import 'package:flutter/material.dart';

/// Static interwoven lines: RARE appearance with no animation controller.
class LatticeEffect extends CustomPainter {
  const LatticeEffect();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
    );
    final paint = Paint()
      ..color = const Color(0x2863947A)
      ..strokeWidth = .8;
    for (double x = -size.height; x < size.width + size.height; x += 12) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - size.height, size.height),
        paint,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(.5),
        const Radius.circular(12),
      ),
      Paint()
        ..color = const Color(0x6663947A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(LatticeEffect oldDelegate) => false;
}
