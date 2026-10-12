import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../gacha_timeline.dart';
import '../grade_config.dart';

/// Shared by the live video/overlay stage and offline previews. UI stays still.
abstract final class GachaFilmImpact {
  // Contact flash and sparks share the same impact event as the camera.
  static const flashMs = 45;
  static const sparksMs = 180;
  static const sparkCount = 12;
  static const sparkCountLow = 6;
  static const coreRadius = 15.0;
  static const glowRadius = 38.0;
  static const sparkInner = 24.0;
  static const sparkOuter = 78.0;

  static const cameraMs = 340.0;
  static const shockwaveMs = 260.0;
  static const debrisMs = 420.0;
  static const stageWidth = 420.0;
  static const kickMultiplier = 2.2;
  static const zoom = .075;
  static const fragmentsHigh = 42;
  static const fragmentsLow = 18;

  static Matrix4 matrix(
    Size size,
    double ms,
    GachaTimeline tl,
    GradeConfig grade,
  ) {
    final age = ms - tl.impactMs;
    final matrix = Matrix4.identity();
    if (age < 0 || age >= cameraMs) return matrix;
    final gain = (grade.shake / 10).clamp(.3, 1.0);
    final pixels = math.min(
      size.width / stageWidth,
      size.height / (stageWidth / .45),
    );
    final fade = math.pow(1 - age / cameraMs, 2).toDouble();
    final kick = grade.shake * kickMultiplier * pixels * fade;
    final x = math.sin(age * .095) * kick * .4;
    final y = kick * (math.exp(-age / 65) - .48 * math.sin(age * .065));
    // Keep the plate covering the viewport while the kick settles. Letting
    // the zoom decay faster than translation exposes a thin black edge.
    final coverage =
        1 +
        math.max(2 * x.abs() / size.width, 2 * y.abs() / size.height) +
        .002 * fade;
    final scale = math.max(
      coverage,
      1 + zoom * gain * math.exp(-age / 85) * fade,
    );
    return matrix
      ..translateByDouble(size.width / 2 + x, size.height / 2 + y, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-size.width / 2, -size.height / 2, 0, 1);
  }

  static void paint(
    Canvas canvas,
    Offset center,
    double age,
    Color color,
    GachaQuality quality,
    Paint paint,
  ) {
    if (age < 0 || age >= debrisMs) return;
    if (age < shockwaveMs) {
      final t = Curves.easeOutCubic.transform(age / shockwaveMs);
      paint
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.plus
        ..strokeWidth = 4 * (1 - t) + .5
        ..color = color.withValues(alpha: (1 - t) * .9);
      canvas.drawOval(
        Rect.fromCenter(
          center: center + const Offset(0, 72),
          width: 50 + 480 * t,
          height: 8 + 90 * t,
        ),
        paint,
      );
    }
    final t = age / debrisMs;
    final count = quality == GachaQuality.high ? fragmentsHigh : fragmentsLow;
    paint
      ..blendMode = BlendMode.srcOver
      ..strokeCap = StrokeCap.square;
    // Fixed indexed fragments: no particles, random lists or state allocated
    // per frame. Arc, length and speed differ for each shard.
    for (var i = 0; i < count; i++) {
      final seed = (i * .61803398875) % 1;
      final direction = i.isEven ? 1.0 : -1.0;
      final x =
          center.dx + (seed - .5) * 210 + direction * (40 + seed * 145) * t;
      final y = center.dy + 40 - (90 + ((i * .37) % 1) * 150) * t + 160 * t * t;
      paint
        ..strokeWidth = 1 + seed * 2
        ..color = (i % 3 == 0 ? Colors.white : color).withValues(
          alpha: (1 - t) * .85,
        );
      canvas.drawLine(
        Offset(x, y),
        Offset(x + direction * (3 + seed * 7), y - 4),
        paint,
      );
    }
    paint
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver;
  }
}
