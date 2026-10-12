import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../gacha_controller.dart';
import '../gacha_timeline.dart';
import '../grade_config.dart';
import '../painters/gacha_scene_painter.dart';
import 'gacha_film_driver.dart';
import 'gacha_film_track.dart';
import 'gacha_film_ignition.dart';
import 'gacha_film_impact.dart';

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
      return AnimatedBuilder(
        animation: film.scene,
        builder: (context, child) => ClipRect(
          child: Transform(
            transform: GachaFilmImpact.matrix(
              size,
              film.scene.ms,
              film.scene.timeline,
              film.scene.configs[film.scene.result.highest]!,
            ),
            child: child,
          ),
        ),
        child: Stack(
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
        ),
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
    GachaFilmIgnition.paintEmbers(
      canvas,
      Size(width, height),
      sourceMs,
      scene.result.highest,
      p,
      count: resources.quality == GachaQuality.high ? 64 : 28,
      rotation: track.firework.emberRotation,
    );
    for (final light in resources.lights) {
      // All heads meet the lid together. Delaying each flash after contact
      // leaves landed heads hovering and turns the strike into a soft dissolve.
      final hit = tl.impactMs;
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
        final release = GachaFilmIgnition.releaseTrail(sourceMs);
        final strength = (quiet ? .16 : 1.0) * math.max(trailGrowth, release);
        final strike = tl.progress(ms, hit - track.strikeMs, hit);
        final trailScale =
            track.trailScale(ms, light.isReversed(ms)) *
            (1 + strike * strike * 2.4);
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
        if (release > 0) {
          final previous = point(math.max(0, ms - 25), key, light.index);
          final direction = at - previous;
          if (direction.distance > .01) {
            final tail = at - direction / direction.distance * 32 * release;
            p
              ..strokeWidth = 2.2 * release
              ..strokeCap = StrokeCap.round
              ..blendMode = BlendMode.plus
              ..shader = ui.Gradient.linear(tail, at, [
                color.withValues(alpha: 0),
                Colors.white.withValues(alpha: release),
              ]);
            canvas.drawLine(tail, at, p);
            p
              ..shader = null
              ..blendMode = BlendMode.srcOver;
          }
        }
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
          resources.glow(canvas, at, 48, Colors.white, flash * .7);
        }
      } else if (ms >= hit && ms < tl.openingMs) {
        final at = point(hit + 25, key, light.index);
        final burst =
            1 -
            Curves.easeOutCubic.transform(
              tl.progress(ms, hit, hit + GachaFilmImpact.sparksMs),
            );
        final flash = 1 - tl.progress(ms, hit, hit + GachaFilmImpact.flashMs);
        resources.glow(canvas, at, GachaFilmImpact.glowRadius, color, burst);
        resources.glow(
          canvas,
          at,
          GachaFilmImpact.coreRadius,
          Colors.white,
          flash,
        );
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
          ..strokeWidth = 2
          ..color = color.withValues(alpha: burst);
        final sparks = resources.quality == GachaQuality.high
            ? GachaFilmImpact.sparkCount
            : GachaFilmImpact.sparkCountLow;
        for (var j = 0; j < sparks; j++) {
          final angle = j * math.pi * 2 / sparks + light.index;
          final d = Offset(math.cos(angle), math.sin(angle));
          canvas.drawLine(
            at + d * (1 - burst) * GachaFilmImpact.sparkInner,
            at + d * (1 - burst) * GachaFilmImpact.sparkOuter,
            p,
          );
        }
        p.style = PaintingStyle.fill;
      }
    }
    GachaFilmIgnition.paintCore(canvas, Size(width, height), sourceMs, p);
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
      GachaFilmImpact.paint(
        canvas,
        center,
        ms - tl.impactMs,
        color,
        resources.quality,
        p,
      );
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
