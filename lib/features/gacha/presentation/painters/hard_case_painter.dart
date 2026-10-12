import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../grade_config.dart';

/// Perspective is projected from a hinged lid; no sprite or image decoding.
class HardCasePainter {
  final Paint _paint = Paint()..isAntiAlias = true;
  final Path _face = Path();
  final Path dollar = Path()
    ..moveTo(.28, -.58)
    ..cubicTo(-.58, -.95, -.66, -.05, 0, .02)
    ..cubicTo(.68, .10, .49, .87, -.32, .58)
    ..moveTo(0, -.91)
    ..lineTo(0, .91);
  late final ui.Shader _metal = ui.Gradient.linear(
    const Offset(0, -80),
    const Offset(0, 58),
    const [
      GachaStyle.metalHighlight,
      GachaStyle.metalMid,
      GachaStyle.metalShadow,
    ],
    [0, .45, 1],
  );
  late final ui.Shader _lid = ui.Gradient.linear(
    const Offset(0, -150),
    const Offset(0, -20),
    const [GachaStyle.lidHighlight, GachaStyle.lidShadow],
  );
  void polygon(
    Canvas canvas,
    List<Offset> points,
    Color color, {
    ui.Shader? shader,
  }) {
    _face.reset();
    _face.addPolygon(points, true);
    _paint
      ..style = PaintingStyle.fill
      ..shader = shader
      ..color = color;
    canvas.drawPath(_face, _paint);
    _paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = GachaStyle.edge.withValues(alpha: .4);
    canvas.drawPath(_face, _paint);
  }

  void glyph(
    Canvas canvas,
    double x,
    double y,
    double scale,
    Color color, {
    double alpha = 1,
  }) {
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale);
    _paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..strokeWidth = .16
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: alpha.clamp(0, 1));
    canvas.drawPath(dollar, _paint);
    _paint.style = PaintingStyle.fill;
    canvas.restore();
  }

  void paint(
    Canvas canvas, {
    required double width,
    required double reveal,
    required double opening,
    required Color accent,
    required double light,
  }) {
    canvas.save();
    canvas.scale(width / 320);
    final body = Color.lerp(GachaStyle.silhouette, GachaStyle.metal, reveal)!;
    // Body extends upward from a fixed contact point at (0, 0).
    polygon(
      canvas,
      const [
        Offset(-160, -73),
        Offset(145, -73),
        Offset(145, -8),
        Offset(-152, -8),
      ],
      body,
      shader: reveal > .1 ? _metal : null,
    );
    polygon(canvas, const [
      Offset(145, -73),
      Offset(171, -98),
      Offset(171, -34),
      Offset(145, -8),
    ], Color.lerp(GachaStyle.silhouetteSide, GachaStyle.caseSide, reveal)!);
    polygon(canvas, const [
      Offset(-160, -73),
      Offset(-134, -98),
      Offset(171, -98),
      Offset(145, -73),
    ], GachaStyle.interior);
    // Interior is visible as the lid rises.
    if (opening > 0) {
      _paint
        ..style = PaintingStyle.fill
        ..shader = null
        ..color = accent.withValues(alpha: light * .25);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-139, -94, 290, 24),
          const Radius.circular(6),
        ),
        _paint,
      );
    }
    if (opening > 0) {
      _paint
        ..color = GachaStyle.interior
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-139, -94, 290, 24),
          const Radius.circular(6),
        ),
        _paint,
      );
      _paint
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: light * .85);
      canvas.drawLine(const Offset(-125, -80), const Offset(137, -80), _paint);
    }
    final hinge = -98.0;
    final lift = math.sin(opening * math.pi * .48) * 116;
    final frontY = -73 - lift;
    final frontX = -160 + opening * 16;
    polygon(
      canvas,
      [
        Offset(frontX, frontY),
        Offset(145, frontY),
        const Offset(171, -98),
        Offset(-134, hinge),
      ],
      Color.lerp(GachaStyle.lidSilhouette, GachaStyle.lidBase, reveal)!,
      shader: reveal > .1 ? _lid : null,
    );
    // Recessed panel and machined ribs follow the hinged plane.
    for (var i = 0; i < 5; i++) {
      final x = -114.0 + i * 49;
      _paint
        ..shader = null
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.black.withValues(alpha: .42 * reveal);
      canvas.drawLine(
        Offset(x, frontY + (hinge - frontY) * .18),
        Offset(x + 10, frontY + (hinge - frontY) * .82),
        _paint,
      );
    }
    // Impact marks remain on the front instead of floating independently.
    for (var i = -1; i <= 1; i++) {
      glyph(canvas, i * 72, -42, 12, accent, alpha: .45 + .35 * (1 - reveal));
    }
    if (reveal > .05) {
      // Bevels and inset fasteners create material depth without textures.
      _paint
        ..shader = null
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = GachaStyle.fastener.withValues(alpha: .5 * reveal);
      canvas.drawLine(const Offset(-145, -17), const Offset(136, -17), _paint);
      canvas.drawLine(const Offset(151, -31), const Offset(166, -46), _paint);
      for (final x in [-147.0, 136.0]) {
        for (final y in [-66.0, -23.0]) {
          _paint
            ..style = PaintingStyle.fill
            ..color = GachaStyle.rubber;
          canvas.drawCircle(Offset(x, y), 3.5, _paint);
          _paint
            ..color = GachaStyle.fastener
            ..strokeWidth = .7;
          canvas.drawLine(Offset(x - 1.5, y), Offset(x + 1.5, y), _paint);
        }
      }
      for (final x in [-131.0, 111.0]) {
        _paint
          ..style = PaintingStyle.fill
          ..color = GachaStyle.rubber
          ..shader = null;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, -83, 25, 61),
            const Radius.circular(5),
          ),
          _paint,
        );
        _paint.color = GachaStyle.fastener;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 4, -68, 17, 24),
            const Radius.circular(3),
          ),
          _paint,
        );
        _paint.color = GachaStyle.latchInset;
        canvas.drawRect(Rect.fromLTWH(x + 7, -61, 11, 8), _paint);
      }
      _paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = GachaStyle.handle;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-28, -34, 56, 20),
          const Radius.circular(6),
        ),
        _paint,
      );
      _paint
        ..strokeWidth = 2
        ..color = accent.withValues(alpha: .65 * reveal);
      canvas.drawLine(const Offset(-149, -75), const Offset(142, -75), _paint);
      canvas.drawLine(Offset(frontX, frontY), Offset(145, frontY), _paint);
      canvas.drawLine(Offset(145, frontY), const Offset(171, -98), _paint);
    }
    canvas.restore();
  }
}
