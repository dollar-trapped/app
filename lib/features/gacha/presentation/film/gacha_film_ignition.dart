import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../gacha_result.dart';

/// Visual randomness is sampled once per playback, never per frame or reward.
class GachaFireworkPattern {
  GachaFireworkPattern(int seed) {
    final random = math.Random(seed);
    final sampled = List.generate(10, (i) {
      final angle =
          (-165 + i * 36 + random.nextDouble() * 18 - 9) * math.pi / 180;
      final x = math.cos(angle), y = math.sin(angle);
      var radius = .26 + random.nextDouble() * .14;
      // Reserve margins for the subsequent outward drift and gravity.
      final xRoom = x < 0 ? .56 : .32;
      final yRoom = y < 0 ? .155 : .175;
      radius = math.min(radius, xRoom / (x.abs() * 1.08));
      radius = math.min(radius, yRoom / (y.abs() * .45 * 1.08));
      return Offset(x * radius, y * radius * .45);
    });
    // Preserve spatial order when joining the row, avoiding crossing flights.
    sampled.sort((a, b) => a.dx.compareTo(b.dx));
    rays = List.unmodifiable(sampled);
    emberRotation = random.nextDouble() * math.pi * 2;
  }
  late final List<Offset> rays;
  late final double emberRotation;
}

/// One source flash, a quick release, a suspended fan, then the existing row.
abstract final class GachaFilmIgnition {
  // Leave room around the source for a full firework, including upward rays.
  static const origin = Offset(.62, .20);
  static const splitMs = 250.0;
  static const punchMs = 170.0;
  static const releaseTrailEndMs = 700.0;
  static const formationMs = 1850.0;
  static const driftJoinMs = 700.0;
  static const dragSeconds = .060;
  static const radialDrift = .10;
  static const gravityPerSecond = .09;
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

  static Offset position(
    double sourceMs,
    Offset destination,
    int index,
    int count,
    GachaFireworkPattern pattern,
  ) {
    if (sourceMs <= splitMs) return origin;
    final ray = count == 1 ? 7 : index;
    final t = (math.min(sourceMs, driftJoinMs) - splitMs) / 1000;
    final decay = math.exp(-t / dragSeconds);
    final scattered =
        origin +
        pattern.rays[ray] * (1 - decay + radialDrift * t) +
        Offset(0, gravityPerSecond * t * t);
    if (sourceMs <= driftJoinMs) return scattered;
    final velocity =
        pattern.rays[ray] * (decay / dragSeconds + radialDrift) +
        Offset(0, 2 * gravityPerSecond * t);
    final duration = (formationMs - driftJoinMs) / 1000;
    final u = ((sourceMs - driftJoinMs) / (formationMs - driftJoinMs)).clamp(
      0.0,
      1.0,
    );
    // Hermite preserves the outgoing velocity instead of stopping/restarting.
    return scattered * (2 * u * u * u - 3 * u * u + 1) +
        velocity * duration * (u * u * u - 2 * u * u + u) +
        destination * (-2 * u * u * u + 3 * u * u);
  }

  /// Small secondary embers make an expanding firework, not ten laser spokes.
  static void paintEmbers(
    Canvas canvas,
    Size size,
    double sourceMs,
    GachaGrade highest,
    Paint paint, {
    required int count,
    required double rotation,
  }) {
    const lifetime = 780.0;
    if (sourceMs <= splitMs || sourceMs >= splitMs + lifetime) return;
    final age = (sourceMs - splitMs) / lifetime;
    final colors = palette(highest);
    final at = Offset(origin.dx * size.width, origin.dy * size.height);
    paint
      ..shader = null
      ..blendMode = BlendMode.plus
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < count; i++) {
      final angle = i * 2.3999632297 + rotation;
      final distance = 35 + (i * 37 % 115);
      Offset position(double t) {
        final radial = 1 - math.pow(1 - t, 3);
        return at +
            Offset(
              math.cos(angle) * distance * radial,
              math.sin(angle) * distance * radial + 55 * t * t,
            );
      }

      final flicker = .55 + .45 * math.sin(i * 1.7 + age * 23).abs();
      paint
        ..strokeWidth = i.isEven ? 1.2 : .65
        ..color = colors[i % colors.length].withValues(
          alpha: (1 - age) * flicker,
        );
      canvas.drawLine(position(math.max(0, age - .045)), position(age), paint);
    }
    paint
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver;
  }

  static double releaseTrail(double sourceMs) {
    if (sourceMs < splitMs) return 0;
    final t = ((sourceMs - splitMs) / (releaseTrailEndMs - splitMs)).clamp(
      0.0,
      1.0,
    );
    return (1 - t) * (1 - t);
  }

  /// Draw over the departing heads: they visibly emerge through this core.
  static void paintCore(
    Canvas canvas,
    Size size,
    double sourceMs,
    Paint paint,
  ) {
    if (sourceMs < splitMs || sourceMs >= splitMs + punchMs) return;
    final t = (sourceMs - splitMs) / punchMs;
    final at = Offset(origin.dx * size.width, origin.dy * size.height);
    final expansion = Curves.easeOutCubic.transform(t);
    final alpha = (1 - t) * (1 - t);
    paint
      ..shader = null
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - t) + .5
      ..color = Colors.white.withValues(alpha: alpha * .9);
    canvas.drawCircle(at, 12 + 64 * expansion, paint);
    paint
      ..style = PaintingStyle.fill
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: alpha),
              Colors.white.withValues(alpha: alpha * .8),
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0, .3, 1],
          ).createShader(
            Rect.fromCircle(center: at, radius: 15 + 24 * (1 - expansion)),
          );
    canvas.drawCircle(at, 15 + 24 * (1 - expansion), paint);
    paint
      ..shader = null
      ..blendMode = BlendMode.srcOver;
  }

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
    final compression = sourceMs < splitMs
        ? Curves.easeInCubic.transform(((sourceMs - 160) / 90).clamp(0, 1))
        : 0.0;
    final radius =
        (30 + 18 * math.sin((sourceMs / fadeEndMs) * math.pi)) *
        (1 - .3 * compression);
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
