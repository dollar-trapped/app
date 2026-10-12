import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../gacha_result.dart';

/// One source flash, a quick release, a suspended fan, then the existing row.
abstract final class GachaFilmIgnition {
  static const origin = Offset(.82, .085);
  static const splitMs = 250.0;
  static const burstEndMs = 600.0;
  static const slowEndMs = 950.0;
  static const formationMs = 1850.0;
  static const fadeEndMs = 720.0;
  static const rainbow = <Color>[
    Color(0xFFFF526C),
    Color(0xFFFFAB49),
    Color(0xFFFFED70),
    Color(0xFF63FFB0),
    Color(0xFF59DFFF),
    Color(0xFF7284FF),
    Color(0xFFD87CFF),
  ];
  static List<Color> palette(GachaGrade highest) =>
      highest == GachaGrade.special ? rainbow : const [Colors.white];

  static double spread(double sourceMs) {
    double ease(double a, double b) => Curves.easeInOutCubic.transform(
      ((sourceMs - a) / (b - a)).clamp(0.0, 1.0),
    );
    if (sourceMs <= splitMs) return 0;
    if (sourceMs < burstEndMs) return .64 * ease(splitMs, burstEndMs);
    if (sourceMs < slowEndMs) return .64 + .05 * ease(burstEndMs, slowEndMs);
    return .69 + .31 * ease(slowEndMs, formationMs);
  }

  static Offset position(double sourceMs, Offset destination) =>
      Offset.lerp(origin, destination, spread(sourceMs))!;

  static void paint(
    Canvas canvas,
    Size size,
    double sourceMs,
    GachaGrade highest,
    Paint paint,
  ) {
    if (sourceMs >= fadeEndMs) return;
    final at = Offset(origin.dx * size.width, origin.dy * size.height);
    final rise = Curves.easeOutCubic.transform((sourceMs / 90).clamp(0, 1));
    final fade =
        1 -
        Curves.easeInCubic.transform(
          ((sourceMs - splitMs) / (fadeEndMs - splitMs)).clamp(0, 1),
        );
    final alpha = rise * fade;
    final colors = palette(highest);
    final radius = 30 + 18 * math.sin((sourceMs / fadeEndMs) * math.pi);
    paint
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.plus;
    for (var i = 0; i < colors.length; i++) {
      final angle = i * math.pi * 2 / colors.length;
      final offset = colors.length == 1
          ? Offset.zero
          : Offset(math.cos(angle), math.sin(angle)) * radius * .38;
      final center = at + offset;
      paint.shader = RadialGradient(
        colors: [
          colors[i].withValues(alpha: alpha * .8),
          colors[i].withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
      paint.shader = null;
      paint
        ..color = colors[i].withValues(alpha: alpha)
        ..strokeWidth = 1.5;
      final ray = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(at + ray * 8, at + ray * radius * 1.25, paint);
    }
    paint
      ..shader = null
      ..color = Colors.white.withValues(alpha: alpha);
    canvas.drawCircle(at, 4 + 3 * rise, paint);
    paint.strokeWidth = 1.3;
    canvas.drawLine(at - Offset(0, radius), at + Offset(0, radius), paint);
    canvas.drawLine(at - Offset(radius, 0), at + Offset(radius, 0), paint);
    paint
      ..blendMode = BlendMode.srcOver
      ..style = PaintingStyle.fill;
  }
}
