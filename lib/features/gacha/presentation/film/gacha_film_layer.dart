import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../gacha_controller.dart';
import '../gacha_timeline.dart';
import '../grade_config.dart';
import '../painters/gacha_scene_painter.dart';
import 'gacha_film_driver.dart';
import 'gacha_film_track.dart';
import 'gacha_film_ignition.dart';

class GachaFilmLayer extends StatelessWidget {
  const GachaFilmLayer({
    super.key,
    required this.film,
    required this.resources,
  });
  final GachaFilmDriver film;
  final GachaSceneResources resources;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      final rect = film.track!.viewport(size);
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF03070E)),
          Positioned.fromRect(
            rect: rect,
            child: film.finished
                ? Image.asset(
                    'assets/gacha/film/opened.jpg',
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  )
                : VideoPlayer(film.video),
          ),
          RepaintBoundary(
            child: CustomPaint(
              key: const Key('gacha-blender-overlay'),
              painter: GachaFilmPainter(film.scene, film.track!, resources),
            ),
          ),
        ],
      );
    },
  );
}

/// Only result-dependent light, glyphs and rim color are drawn in Flutter.
/// Sky, camera, solid case, contact dust and lid motion come from Blender.
class GachaFilmPainter extends CustomPainter {
  GachaFilmPainter(this.scene, this.track, this.resources)
    : super(repaint: scene);
  final GachaController scene;
  final GachaFilmTrack track;
  final GachaSceneResources resources;
  @override
  void paint(Canvas canvas, Size size) {
    final ms = scene.ms, tl = scene.timeline;
    final rect = track.viewport(size);
    const width = 420.0;
    final height = width * track.sourceSize.height / track.sourceSize.width;
    final p = resources.paint;
    Offset point(double t, String key, [int? index]) {
      final xy = track.point(t, tl, key, index);
      return Offset(xy.dx * width, xy.dy * height);
    }

    final key = resources.lights.length == 1 ? 'one' : 'ten';
    canvas.save();
    canvas.clipRect(rect);
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width / width);
    final sourceMs = track.sourceMs(ms, tl);
    GachaFilmIgnition.paint(
      canvas,
      Size(width, height),
      sourceMs,
      scene.result.highest,
      p,
    );
    for (final light in resources.lights) {
      final hit = tl.impactMs + light.strikeDelayMs;
      final color = scene.configs[light.gradeAt(ms)]!.color;
      if (ms < hit) {
        if (sourceMs < GachaFilmIgnition.splitMs) continue;
        final at = point(ms, key, light.index);
        final falling = tl.progress(ms, tl.bounds[1], tl.impactMs);
        final quiet =
            ms >= tl.bounds[2] && ms < tl.impactMs - GachaTimeline.strikeMs;
        final ignition = Curves.easeOutCubic.transform(
          (ms / GachaFilmTrack.ignitionMs).clamp(0, 1),
        );
        final trailGrowth = Curves.easeInCubic.transform(
          ((track.sourceMs(ms, tl) - tl.bounds[1]) /
                  (GachaFilmTrack.formationEndSourceMs - tl.bounds[1]))
              .clamp(0, 1),
        );
        final strength = (quiet ? .16 : 1.0) * trailGrowth;
        final trailScale = track.trailScale(ms, light.isReversed(ms));
        final scale = resources.lights.length == 1 ? 1.0 : .5;
        final radius = (9 + falling * 10) * scale;
        // Tail offsets use the exported camera at each sampled instant. Keeping
        // a small upward extension reads as velocity during camera tracking.
        for (var j = 16; j > 0; j--) {
          final f = j / 16;
          final previous =
              point(math.max(0, ms - f * 180), key, light.index) -
              Offset(0, f * (70 + falling * 130) * trailGrowth * trailScale);
          final next =
              point(math.max(0, ms - (f - 1 / 16) * 180), key, light.index) -
              Offset(
                0,
                (f - 1 / 16) * (70 + falling * 130) * trailGrowth * trailScale,
              );
          p
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = (1 - f) * (light.isReversed(ms) ? 9 : 5) * scale
            ..color = color.withValues(alpha: (1 - f) * .65 * strength)
            ..blendMode = BlendMode.plus;
          canvas.drawLine(previous, next, p);
        }
        p
          ..blendMode = BlendMode.srcOver
          ..style = PaintingStyle.fill;
        resources.glow(canvas, at, radius * 4, color, .7 * ignition);
        resources.casePainter.glyph(
          canvas,
          at.dx,
          at.dy,
          radius,
          color,
          alpha: ignition,
        );
        resources.casePainter.glyph(
          canvas,
          at.dx,
          at.dy,
          radius * .7,
          Colors.white,
          alpha: ignition,
        );
        if (!quiet && trailGrowth > 0) {
          final count = resources.quality == GachaQuality.high ? 6 : 3;
          for (var j = 0; j < count; j++) {
            final f = ((ms / 450 + j / count + light.index * .17) % 1);
            final x = at.dx + math.sin(j * 3.1 + light.index) * 18 * f;
            final y = at.dy - f * 150;
            p
              ..style = PaintingStyle.stroke
              ..strokeWidth = .7
              ..color = color.withValues(alpha: (1 - f) * .55 * trailGrowth);
            if (j.isEven) {
              canvas.save();
              canvas.translate(x, y);
              canvas.rotate(f * 4 + j);
              canvas.drawRect(const Rect.fromLTWH(-3, -1.5, 6, 3), p);
              canvas.restore();
            } else {
              resources.casePainter.glyph(
                canvas,
                x,
                y,
                2.3,
                color,
                alpha: (1 - f) * .6 * trailGrowth,
              );
            }
          }
          p.style = PaintingStyle.fill;
        }
        if (light.isReversed(ms)) {
          final flash =
              1 -
              tl.progress(
                ms,
                GachaTimeline.reversalMs,
                GachaTimeline.reversalMs + GachaTimeline.reversalFlashMs,
              );
          resources.glow(canvas, at, 90, Colors.white, flash);
        }
      } else if (ms >= hit && ms < tl.openingMs) {
        final at = point(hit + 25, key, light.index);
        final burst =
            1 - Curves.easeOutCubic.transform(tl.progress(ms, hit, hit + 300));
        resources.glow(canvas, at, 42, color, burst);
        resources.casePainter.glyph(
          canvas,
          at.dx,
          at.dy,
          4,
          color,
          alpha: (1 - tl.progress(ms, hit, tl.openingMs)) * .8,
        );
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = color.withValues(alpha: burst);
        for (var j = 0; j < 5; j++) {
          final angle = j * math.pi * 2 / 5 + light.index;
          final d = Offset(math.cos(angle), math.sin(angle));
          canvas.drawLine(
            at + d * (1 - burst) * 22,
            at + d * (1 - burst) * 38,
            p,
          );
        }
        p.style = PaintingStyle.fill;
      }
    }
    if (ms >= tl.impactMs) {
      final color = scene.configs[scene.result.highest]!.color;
      final opening = Curves.easeInOutCubic.transform(
        tl.progress(ms, tl.openingMs, tl.bounds[6]),
      );
      final after =
          1 -
          Curves.easeOutCubic.transform(
            tl.progress(ms, tl.cardsEnd, tl.totalMs),
          );
      final center = point(ms, 'case');
      resources.glow(canvas, center, 130, color, (.10 + .25 * opening) * after);
      final path = resources.path..reset();
      for (var i = 0; i < 4; i++) {
        final at = point(ms, 'rim', i);
        if (i == 0) {
          path.moveTo(at.dx, at.dy);
        } else {
          path.lineTo(at.dx, at.dy);
        }
      }
      path.close();
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: .55 * after)
        ..blendMode = BlendMode.plus;
      canvas.drawPath(path, p);
      p
        ..blendMode = BlendMode.srcOver
        ..style = PaintingStyle.fill;
      if (opening > 0) {
        for (final light in resources.lights) {
          final hue = scene.configs[light.reward.grade]!.color;
          final x = center.dx + light.lane * 15;
          resources.glow(
            canvas,
            Offset(x, center.dy - 15),
            35,
            hue,
            opening * .55 * after,
          );
          p
            ..strokeWidth = 9
            ..style = PaintingStyle.stroke
            ..color = hue.withValues(alpha: .09 * opening * after)
            ..blendMode = BlendMode.plus;
          canvas.drawLine(
            Offset(x, center.dy - 10),
            Offset(x + light.lane * 16, center.dy - 200 * opening),
            p,
          );
        }
        p
          ..blendMode = BlendMode.srcOver
          ..style = PaintingStyle.fill;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GachaFilmPainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.track != track;
}
