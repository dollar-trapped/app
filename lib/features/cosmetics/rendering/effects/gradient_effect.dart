import 'dart:math' as math;
import 'package:flutter/material.dart';

abstract final class GradientEffect {
  static LinearGradient shimmer(List<Color> colors, {required double phase}) {
    final sweeping = phase > 0 && phase < .45;
    final center = -.35 + (phase / .45) * 1.7;
    final strength = sweeping ? math.sin(phase / .45 * math.pi) * .45 : 0.0;
    return LinearGradient(
      colors: List.generate(17, (i) {
        final position = i / 16;
        final palettePosition = position * (colors.length - 1);
        final left = palettePosition.floor();
        final base = Color.lerp(
          colors[left],
          colors[math.min(left + 1, colors.length - 1)],
          palettePosition - left,
        )!;
        final highlight =
            math.max(0.0, 1 - (position - center).abs() / .24) * strength;
        return Color.lerp(base, const Color(0xFFFFE9A6), highlight)!;
      }),
    );
  }

  static LinearGradient gradient(List<Color> colors, {required double phase}) {
    final shift = 1 - math.cos(phase * math.pi * 2);
    return LinearGradient(
      begin: Alignment(-1 + shift, -1),
      end: Alignment(1 - shift, 1),
      colors: colors,
    );
  }
}
