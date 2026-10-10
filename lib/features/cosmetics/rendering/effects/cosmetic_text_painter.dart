import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../effect_registry.dart';

/// Paints within glyphs, preserving the normal Text child's layout and semantics.
class CosmeticTextPainter extends CustomPainter {
  const CosmeticTextPainter({
    required this.nickname,
    required this.textStyle,
    required this.scene,
    required this.phase,
    required this.textDirection,
    required this.textScaler,
  });
  final String nickname;
  final TextStyle textStyle;
  final CosmeticTextScene scene;
  final double phase;
  final TextDirection textDirection;
  final TextScaler textScaler;

  static double hologramRedMix(double phase) {
    if (phase < .56 || phase > .88) return 0;
    final t = phase < .68
        ? (phase - .56) / .12
        : phase > .76
        ? (.88 - phase) / .12
        : 1.0;
    return t * t * (3 - 2 * t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    final red = hologramRedMix(phase);
    final color = scene == CosmeticTextScene.blood
        ? const Color(0xFF85142C)
        : Color.lerp(const Color(0xFF007B4F), const Color(0xFFBD2445), red)!;
    final text = TextPainter(
      text: TextSpan(
        text: nickname,
        style: textStyle.copyWith(color: color),
      ),
      textDirection: textDirection,
      textAlign: TextAlign.center,
      textScaler: textScaler,
    )..layout(maxWidth: size.width);
    canvas.save();
    canvas.clipRect(bounds);
    canvas.saveLayer(bounds, Paint());
    if (scene == CosmeticTextScene.hologram) {
      // Short local horizontal faults; the name never disappears or flashes.
      for (var band = 0; band < 5; band++) {
        canvas.save();
        canvas.clipRect(
          Rect.fromLTWH(0, size.height * band / 5, size.width, size.height / 5),
        );
        final shift = red * math.sin(phase * math.pi * 20 + band * 2.3) * 1.8;
        text.paint(canvas, Offset(shift, 0));
        canvas.restore();
      }
    } else {
      text.paint(canvas, Offset.zero);
    }
    // The glyph mask clips all liquid and scanline detail to the letters.
    final base = Paint()
      ..blendMode = BlendMode.srcIn
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: scene == CosmeticTextScene.blood
            ? [const Color(0xFFAE2940), const Color(0xFF6F1025)]
            : [color.withValues(alpha: .65), color, color],
      ).createShader(bounds);
    // Hologram already has its shifted glyphs; only add faint scanline texture.
    if (scene == CosmeticTextScene.blood) {
      canvas.drawRect(bounds, base);
      for (var flow = 0; flow < 5; flow++) {
        final x = size.width * (flow + .45) / 5;
        final progress = (phase + flow * .19) % 1;
        // Ease down slowly; fade at the loop boundary instead of snapping.
        final eased = progress * progress * (3 - 2 * progress);
        final y = size.height * (.08 + eased * .84);
        final width = (size.height * .12).clamp(2.0, 6.0);
        final alpha = math.sin(progress * math.pi) * .85;
        final liquid = Path()
          ..moveTo(x - width * .35, -2)
          ..cubicTo(x + width * .2, y * .25, x - width, y * .75, x - width, y)
          ..cubicTo(
            x - width,
            y + width * 1.8,
            x + width,
            y + width * 1.8,
            x + width,
            y,
          )
          ..cubicTo(
            x + width,
            y * .75,
            x - width * .2,
            y * .25,
            x + width * .35,
            -2,
          )
          ..close();
        canvas.drawPath(
          liquid,
          Paint()
            ..blendMode = BlendMode.srcATop
            ..color = const Color(0xFFDB4050).withValues(alpha: alpha),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x - width * .25, y),
            width: width * .35,
            height: width * 1.1,
          ),
          Paint()
            ..blendMode = BlendMode.srcATop
            ..color = const Color(0xFFF48688).withValues(alpha: alpha * .6),
        );
      }
    } else {
      for (double y = 1; y < size.height; y += 3) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          Paint()
            ..blendMode = BlendMode.srcATop
            ..color = Colors.white.withValues(alpha: .24)
            ..strokeWidth = .7,
        );
      }
    }
    canvas.restore();
    canvas.restore();
    text.dispose();
  }

  @override
  bool shouldRepaint(CosmeticTextPainter oldDelegate) =>
      nickname != oldDelegate.nickname ||
      textStyle != oldDelegate.textStyle ||
      scene != oldDelegate.scene ||
      phase != oldDelegate.phase ||
      textDirection != oldDelegate.textDirection ||
      textScaler != oldDelegate.textScaler;
}
