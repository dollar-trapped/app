import 'dart:math' as math;
import 'package:flutter/material.dart';

abstract final class GradientEffect {
  static LinearGradient gradient(List<Color> colors, {required double phase}) {
    final shift = 1 - math.cos(phase * math.pi * 2);
    return LinearGradient(
      begin: Alignment(-1 + shift, -1),
      end: Alignment(1 - shift, 1),
      colors: colors,
    );
  }
}
