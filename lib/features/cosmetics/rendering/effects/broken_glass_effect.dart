import 'package:flutter/material.dart';

/// Static displaced facets and branching cracks, under the legible name.
class BrokenGlassEffect extends CustomPainter {
  const BrokenGlassEffect();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(12)),
    );
    Offset point(double x, double y) => Offset(size.width * x, size.height * y);
    final impact = point(.76, .32);
    final edges = [
      point(.52, 0),
      point(.92, 0),
      point(1, .65),
      point(.84, 1),
      point(.4, 1),
      point(.13, .8),
    ];
    for (var i = 0; i < edges.length; i++) {
      final next = edges[(i + 1) % edges.length];
      final facet = Path()
        ..moveTo(impact.dx, impact.dy)
        ..lineTo(edges[i].dx, edges[i].dy)
        ..lineTo(next.dx, next.dy)
        ..close();
      canvas.drawPath(
        facet,
        Paint()
          ..color = (i.isEven ? Colors.white : const Color(0xFF85AEC2))
              .withValues(alpha: .22),
      );
      final branch = Offset.lerp(impact, edges[i], .58)!;
      final crack = Path()
        ..moveTo(impact.dx, impact.dy)
        ..lineTo(branch.dx + (i.isEven ? 2 : -2), branch.dy)
        ..lineTo(edges[i].dx, edges[i].dy);
      canvas.drawPath(
        crack,
        Paint()
          ..color = const Color(0xFF7394A6).withValues(alpha: .65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
      canvas.drawPath(
        crack.shift(const Offset(1, 0)),
        Paint()
          ..color = Colors.white.withValues(alpha: .85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7,
      );
    }
    // Offset fragments on the rim make the badge itself appear fractured.
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .2, 0)
        ..lineTo(size.width * .24, 4)
        ..lineTo(size.width * .3, 0),
      Paint()
        ..color = const Color(0xFF7394A6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrokenGlassEffect oldDelegate) => false;
}
