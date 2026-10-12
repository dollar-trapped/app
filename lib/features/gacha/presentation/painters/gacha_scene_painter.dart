import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../gacha_controller.dart';
import '../gacha_flight.dart';
import '../gacha_result.dart';
import '../gacha_timeline.dart';
import '../grade_config.dart';
import '../particle_pool.dart';
import '../reward_light.dart';
import 'blender_case_frames.dart';
import 'hard_case_painter.dart';

/// Shared resources live for a route, including deterministic particle slots.
class GachaSceneResources {
  GachaSceneResources(GachaResult result, this.quality)
    : pool = ParticlePool(result.visualSeed, quality),
      caseFrames = BlenderCaseFrames(quality),
      lights = List.unmodifiable([
        for (var i = 0; i < result.rewards.length; i++)
          RewardLight(i, result.rewards.length, result.rewards[i]),
      ]);
  final GachaQuality quality;
  final ParticlePool pool;
  final BlenderCaseFrames caseFrames;
  final List<RewardLight> lights;
  final casePainter = HardCasePainter();
  final paint = Paint()..isAntiAlias = true;
  final path = Path();
  ui.Picture? sky;
  ui.Image? smokeImage;
  bool _disposed = false;
  Size? skySize;
  final shadowShader = ui.Gradient.radial(
    Offset.zero,
    1,
    const [
      GachaStyle.contactShadow,
      GachaStyle.softShadow,
      GachaStyle.clearShadow,
    ],
    [0, .5, 1],
  );
  final glowShader = ui.Gradient.radial(
    Offset.zero,
    1,
    const [GachaStyle.whiteLight, GachaStyle.softLight, GachaStyle.clearLight],
    [0, .18, 1],
  );
  final smokeShader = ui.Gradient.radial(
    Offset.zero,
    1,
    const [GachaStyle.smokeCore, GachaStyle.smokeEdge, GachaStyle.smokeClear],
    [0, .48, 1],
  );
  void dispose() {
    _disposed = true;
    sky?.dispose();
    smokeImage?.dispose();
    caseFrames.dispose();
    sky = null;
    smokeImage = null;
  }

  /// Bake this code-generated radial puff once. Applying a changing Gaussian
  /// filter to dozens of live particles stalls Impeller on the measured device.
  Future<void> prepareSmoke() async {
    final pixels = quality == GachaQuality.high ? 128 : 64;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final radius = pixels * .34;
    canvas.translate(pixels / 2, pixels / 2);
    canvas.scale(radius);
    canvas.drawCircle(
      Offset.zero,
      1,
      Paint()
        ..shader = smokeShader
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          QualityConfig.of(quality).blur / radius,
        ),
    );
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(pixels, pixels);
      if (_disposed) {
        image.dispose();
      } else {
        smokeImage = image;
      }
    } catch (_) {
      // The soft radial fallback is entirely procedural and keeps results usable.
    } finally {
      picture.dispose();
    }
  }

  void glow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    if (radius <= 0 || alpha <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radius);
    paint
      ..shader = glowShader
      ..color = Colors.white.withValues(alpha: alpha.clamp(0, 1))
      ..colorFilter = ColorFilter.mode(color, BlendMode.modulate)
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 1, paint);
    paint
      ..shader = null
      ..colorFilter = null
      ..blendMode = BlendMode.srcOver;
    canvas.restore();
  }
}

class GachaSkyPainter extends CustomPainter {
  GachaSkyPainter(this.resources, this.controller) : super(repaint: controller);
  final GachaSceneResources resources;
  final GachaController controller;
  @override
  void paint(Canvas canvas, Size size) {
    if (resources.skySize != size || resources.sky == null) {
      resources.sky?.dispose();
      final recorder = ui.PictureRecorder(), p = Paint();
      final c = Canvas(recorder);
      final skyHeight =
          size.height * (1 + GachaStyle.worldGroundY * GachaStyle.skyParallax);
      p.shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, skyHeight),
        const [GachaStyle.night, GachaStyle.sky, GachaStyle.skyGround],
        [0, .62, 1],
      );
      c.drawRect(Rect.fromLTWH(0, 0, size.width, skyHeight), p);
      p.shader = null;
      final random = math.Random(812);
      for (var i = 0; i < GachaStyle.starCount; i++) {
        p.color = Colors.white.withValues(
          alpha: .12 + random.nextDouble() * .55,
        );
        c.drawCircle(
          Offset(
            random.nextDouble() * size.width,
            random.nextDouble() * skyHeight,
          ),
          .35 + random.nextDouble() * .7,
          p,
        );
      }
      resources.sky = recorder.endRecording();
      resources.skySize = size;
    }
    canvas.save();
    canvas.translate(
      0,
      -GachaFlight(controller.timeline).cameraY(size, controller.ms) *
          GachaStyle.skyParallax,
    );
    canvas.drawPicture(resources.sky!);
    canvas.restore();
  }

  @override
  bool shouldRepaint(GachaSkyPainter old) =>
      old.resources != resources || old.controller != controller;
}

class GachaScenePainter extends CustomPainter {
  GachaScenePainter({required this.controller, required this.resources})
    : flight = GachaFlight(controller.timeline),
      super(repaint: controller);
  final GachaController controller;
  final GachaSceneResources resources;
  final GachaFlight flight;
  static double ease(double x) => Curves.easeInCubic.transform(x.clamp(0, 1));
  static double out(double x) => Curves.easeOutCubic.transform(x.clamp(0, 1));
  static Offset landing(Size size) => GachaFlight.landing(size);
  static Offset trajectory(Size size, double t) => GachaFlight.point(size, t);
  double travel(double ms) => flight.travel(ms);

  @override
  void paint(Canvas canvas, Size size) {
    final ms = controller.ms, tl = controller.timeline;
    final visible = tl.visibleGrade(ms), config = controller.configs[visible]!;
    final quality = QualityConfig.of(resources.quality), p = resources.paint;
    final end = landing(size), impact = ms >= tl.impactMs;
    final cameraY = flight.cameraY(size, ms);
    final impactAge = (ms - tl.impactMs) / 1000;
    final shake = impact && impactAge < GachaStyle.impactLifetime
        ? config.shake * math.exp(-impactAge * GachaStyle.shakeDecay)
        : 0.0;
    canvas.save();
    canvas.translate(
      math.sin(impactAge * GachaStyle.shakeFrequencyX) * shake,
      math.cos(impactAge * GachaStyle.shakeFrequencyY) * shake * .6 - cameraY,
    );
    _clouds(canvas, size, cameraY, front: false);
    // This floor exists in world space, initially more than two screens below.
    // It enters the viewport only when the camera catches up with the descent.
    final floor = Rect.fromLTWH(
      0,
      size.height * GachaStyle.worldHorizonY,
      size.width,
      size.height,
    );
    p
      ..shader = ui.Gradient.linear(floor.topCenter, floor.bottomCenter, [
        GachaStyle.floorNear,
        GachaStyle.floorFar,
      ])
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawRect(floor, p);
    p.shader = null;
    p
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6
      ..color = GachaStyle.floorLine.withValues(alpha: .16);
    for (var i = -4; i <= 4; i++) {
      canvas.drawLine(
        Offset(size.width * .5 + i * 12, floor.top),
        Offset(size.width * .5 + i * size.width * .36, floor.bottom),
        p,
      );
    }
    for (var i = 0; i < 5; i++) {
      final y = floor.top + math.pow(i / 4, 2) * size.height * .35;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    p.style = PaintingStyle.fill;
    if (impact) {
      final smokeDissolve = out(tl.progress(ms, tl.impactMs, tl.bounds[5]));
      // Dust expands behind the receiver, leaving the ten contact flashes clear.
      _impact(canvas, size, end, impactAge, smokeDissolve, config, quality);
    }
    // The receiver is physically present on the floor throughout the shot.
    // The descending camera reveals it; no light-to-case crossfade exists.
    _groundedCase(canvas, size, end, ms, config);
    if (ms < tl.bounds[1]) {
      final flash = ms < GachaTimeline.starFlashMs
          ? math.sin(ms / GachaTimeline.starFlashMs * math.pi)
          : 0.0;
      final origin = trajectory(size, 0);
      resources.glow(canvas, origin, 110, Colors.white, flash);
      p
        ..color = Colors.white.withValues(alpha: flash)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        origin - Offset(45 * flash, 0),
        origin + Offset(45 * flash, 0),
        p,
      );
      canvas.drawLine(
        origin - Offset(0, 65 * flash),
        origin + Offset(0, 65 * flash),
        p,
      );
      final darkness = ms >= GachaTimeline.starFlashMs
          ? 1 - out(tl.progress(ms, GachaTimeline.blackoutEndMs, tl.bounds[1]))
          : 0.0;
      p.color = Colors.black.withValues(alpha: darkness);
      canvas.drawRect(Offset.zero & size, p);
    }
    if (ms >= tl.bounds[1] &&
        ms < tl.impactMs + resources.lights.last.strikeDelayMs) {
      final meteorScale = resources.lights.length == 1
          ? 1.0
          : GachaStyle.batchMeteorScale;
      for (final light in resources.lights) {
        final localMs = ms - light.strikeDelayMs;
        if (localMs >= tl.impactMs) continue;
        final t = travel(localMs), pos = trajectory(size, t);
        final quiet = localMs >= tl.bounds[2];
        final attack = ease(
          tl.progress(
            localMs,
            tl.impactMs - GachaTimeline.strikeMs,
            tl.impactMs,
          ),
        );
        final tailVisibility = quiet ? .15 + .85 * attack : 1.0;
        final lightConfig = controller.configs[light.gradeAt(ms)]!;
        final lightReversed = light.isReversed(ms);
        final tailWidth = lightReversed ? 13.0 : 6.0;
        final lightPos = pos + light.offset(size, t);
        for (var i = GachaStyle.tailSamples; i > 0; i--) {
          final f = i / GachaStyle.tailSamples;
          final previousT = (t - f * (.08 + .22 * t)).clamp(0.0, 1.0);
          final nextT = (t - (f - 1 / GachaStyle.tailSamples) * (.08 + .22 * t))
              .clamp(0.0, 1.0);
          final previous =
              trajectory(size, previousT) + light.offset(size, previousT);
          final next = trajectory(size, nextT) + light.offset(size, nextT);
          p
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = (1 - f) * tailWidth * (.4 + t) * meteorScale
            ..color = lightConfig.color.withValues(
              alpha: (1 - f) * .7 * tailVisibility,
            )
            ..blendMode = BlendMode.plus;
          canvas.drawLine(previous, next, p);
        }
        p
          ..blendMode = BlendMode.srcOver
          ..style = PaintingStyle.fill;
        final radius = (8 + 25 * t * t) * meteorScale * (1 - .3 * attack);
        resources.glow(canvas, lightPos, radius * 2.8, lightConfig.color, .55);
        // A solid central emblem with a second broad stroke for the glow edge.
        resources.casePainter.glyph(
          canvas,
          lightPos.dx,
          lightPos.dy,
          radius,
          lightConfig.color,
        );
        resources.casePainter.glyph(
          canvas,
          lightPos.dx,
          lightPos.dy,
          radius * .78,
          Colors.white,
        );
        if (lightReversed) {
          final flash =
              1 -
              tl.progress(
                ms,
                GachaTimeline.reversalMs,
                GachaTimeline.reversalMs + GachaTimeline.reversalFlashMs,
              );
          resources.glow(
            canvas,
            lightPos,
            size.width * .32,
            Colors.white,
            flash * .9,
          );
        }
      }
      if (ms < tl.bounds[2]) {
        _trail(canvas, size, travel(ms), ms, config, quality, 1);
      }
      _clouds(canvas, size, cameraY, front: true);
    }
    canvas.restore();
  }

  void _groundedCase(
    Canvas canvas,
    Size size,
    Offset end,
    double ms,
    GradeConfig config,
  ) {
    final tl = controller.timeline, p = resources.paint;
    final width = math.min(
      size.width * GachaStyle.caseWidth,
      GachaStyle.maxCaseWidth,
    );
    final impact = ms >= tl.impactMs;
    final opening = Curves.easeInOutCubic.transform(
      tl.progress(ms, tl.bounds[5], tl.bounds[6]),
    );
    final after = 1 - out(tl.progress(ms, tl.cardsEnd, tl.totalMs));
    final age = math.max(
      0.0,
      (ms -
              tl.impactMs -
              GachaTimeline.hitStopMs[controller.result.highest.index]) /
          1000,
    );
    final recoil = impact ? math.exp(-age * 9) : 0.0;
    canvas.save();
    canvas.translate(end.dx, end.dy - width * .13);
    canvas.scale(width * .59, width * .14);
    p
      ..shader = resources.shadowShader
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 1, p);
    p.shader = null;
    canvas.restore();
    if (impact) {
      resources.glow(
        canvas,
        end,
        width * .75,
        config.color,
        (.08 + opening * .35) * after,
      );
    }
    if (opening > 0) {
      _rays(canvas, size, end, width, opening * after, resources.lights.length);
    }
    canvas.save();
    canvas.translate(end.dx, end.dy);
    // The base stays on the floor: a brief compression and damped rocking,
    // never an upward arrival/scale-in that could read as materialization.
    canvas.rotate(math.sin(age * 38) * .012 * recoil);
    canvas.scale(1, 1 - .025 * recoil * math.cos(age * 34));
    _case(
      canvas,
      width,
      1,
      opening,
      impact ? config.color : GachaStyle.metalLight,
      impact ? after : .15,
    );
    _strikes(canvas, size, ms, opening);
    canvas.restore();
  }

  void _strikes(Canvas canvas, Size size, double ms, double opening) {
    final p = resources.paint;
    for (final light in resources.lights) {
      final age = ms - controller.timeline.impactMs - light.strikeDelayMs;
      if (age < 0) continue;
      final point = light.target(size);
      final color = controller.configs[light.reward.grade]!.color;
      final progress = (age / GachaTimeline.strikeGlowMs).clamp(0.0, 1.0);
      final burst = 1 - out(progress);
      if (burst > 0) {
        resources.glow(canvas, point, 38, color, burst * .95);
        resources.glow(canvas, point, 15, Colors.white, burst * .7);
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * burst
          ..color = color.withValues(alpha: burst);
        canvas.drawOval(
          Rect.fromCenter(
            center: point,
            width: 12 + progress * 48,
            height: 5 + progress * 18,
          ),
          p,
        );
        for (var j = 0; j < 5; j++) {
          final angle = j * math.pi * .4 + light.index * .7;
          final distance = out(progress) * 42;
          final tip =
              point +
              Offset(
                math.cos(angle) * distance,
                math.sin(angle) * distance * .55 - progress * 18,
              );
          canvas.drawLine(
            tip,
            tip + Offset(math.cos(angle) * 6 * burst, -5 * burst),
            p,
          );
        }
        p.style = PaintingStyle.fill;
      }
      // The mark exists only after its own impact and fades as the lid opens.
      if (opening < .2) {
        resources.casePainter.glyph(
          canvas,
          point.dx,
          point.dy,
          6,
          color,
          alpha: .8 * (1 - opening / .2),
        );
      }
    }
  }

  void _clouds(
    Canvas canvas,
    Size size,
    double cameraY, {
    required bool front,
  }) {
    final p = resources.paint;
    for (var i = 0; i < GachaStyle.cloudCount; i++) {
      final slot = resources.pool.slots[i];
      final radius = size.width * (front ? .28 : .4) * slot.size;
      final x =
          size.width * (i.isEven ? -.08 : 1.08) +
          slot.spread * size.width * .18;
      final y =
          size.height * (.22 + slot.phase * 2.6) +
          cameraY * (front ? 0 : 1 - GachaStyle.cloudBackParallax);
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(radius, radius * .46);
      p
        ..shader = resources.smokeShader
        ..color = Colors.white.withValues(alpha: front ? .42 : .16);
      canvas.drawCircle(Offset.zero, 1, p);
      p.shader = null;
      canvas.restore();
    }
  }

  void _trail(
    Canvas canvas,
    Size size,
    double t,
    double ms,
    GradeConfig config,
    QualityConfig quality,
    double visibility,
  ) {
    final p = resources.paint;
    final count =
        math.min(config.particles, quality.capacity) - quality.smokeLimit;
    for (var i = 0; i < count; i++) {
      final slot = resources.pool.slots[i];
      final light = resources.lights[i % resources.lights.length];
      final lightConfig = controller.configs[light.gradeAt(ms)]!;
      final reversed = light.isReversed(ms);
      final age = (slot.phase + ms / GachaStyle.trailPeriodMs * slot.speed) % 1;
      final behind = age * (reversed ? .38 : .24);
      final trailT = (travel(ms - light.strikeDelayMs) - behind).clamp(
        0.0,
        1.0,
      );
      final path = trajectory(size, trailT) + light.offset(size, trailT);
      final spread =
          slot.spread *
          (12 + age * 45) *
          (reversed ? 1.45 : 1) /
          math.sqrt(resources.lights.length);
      final x = path.dx + spread, y = path.dy + spread * .35;
      final alpha = (1 - age) * (.15 + .5 * t) * visibility;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(slot.angle + ms / GachaStyle.paperRotationMs * slot.spread);
      if (i % 4 == 0) {
        resources.casePainter.glyph(
          canvas,
          0,
          0,
          (2 + 4 * t) * slot.size,
          lightConfig.color,
          alpha: alpha,
        );
      } else {
        p
          ..style = PaintingStyle.fill
          ..color = lightConfig.color.withValues(alpha: alpha);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: (2 + 5 * t) * slot.size,
            height: 2 * slot.size,
          ),
          p,
        );
      }
      canvas.restore();
    }
  }

  void _impact(
    Canvas canvas,
    Size size,
    Offset end,
    double age,
    double reveal,
    GradeConfig config,
    QualityConfig quality,
  ) {
    final p = resources.paint,
        smoke = math.min(config.smoke, quality.smokeLimit);
    final life = (1 - age / GachaStyle.impactLifetime).clamp(0.0, 1.0);
    if (life > 0) {
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * life
        ..color = config.color.withValues(alpha: life * .8);
      canvas.drawOval(
        Rect.fromCenter(
          center: end,
          width: 50 + age * size.width * 2.3,
          height: 10 + age * 120,
        ),
        p,
      );
      p.style = PaintingStyle.fill;
      for (
        var i = smoke;
        i < math.min(config.particles, quality.capacity);
        i++
      ) {
        final s = resources.pool.slots[i],
            distance =
                out(age / GachaStyle.impactLifetime) *
                size.width *
                .85 *
                s.speed;
        final pos =
            end +
            Offset(
              math.cos(s.angle) * distance,
              math.sin(s.angle) * distance * .48 - age * 70,
            );
        p.color = config.color.withValues(alpha: life * .7);
        canvas.drawCircle(pos, s.size * 1.6 * life, p);
      }
    }
    final smokeAlpha = (1 - reveal) * .46;
    if (smokeAlpha <= 0) return;
    for (var i = 0; i < smoke; i++) {
      final s = resources.pool.slots[i];
      final expansion = out(
        (age - s.phase * .06) / GachaStyle.smokeExpandSeconds,
      );
      final x =
          end.dx +
          math.cos(s.angle) * expansion * GachaStyle.smokeTravel * s.speed;
      final y =
          end.dy - 28 - math.sin(s.angle).abs() * expansion * 90 - age * 22;
      final radius = (20 + expansion * 65) * s.size;
      final image = resources.smokeImage;
      p
        ..color = Colors.white.withValues(alpha: smokeAlpha)
        ..shader = null;
      if (image != null) {
        p.filterQuality = FilterQuality.low;
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromCenter(
            center: Offset(x, y),
            width: radius / .34,
            height: radius * .8 / .34,
          ),
          p,
        );
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.scale(radius, radius * .8);
        p.shader = resources.smokeShader;
        canvas.drawCircle(Offset.zero, 1, p);
        p.shader = null;
        canvas.restore();
      }
    }
  }

  void _rays(
    Canvas canvas,
    Size size,
    Offset origin,
    double width,
    double strength,
    int count,
  ) {
    final p = resources.paint, path = resources.path;
    final rayTop = origin.dy - size.height * .65;
    for (var i = 0; i < count; i++) {
      final lane = count == 1 ? 0.0 : i / (count - 1) - .5;
      final x = origin.dx + lane * width * 1.8;
      final source = origin + Offset(lane * width * .62, -width * .24);
      final rewardColor =
          controller.configs[resources.lights[i].reward.grade]!.color;
      path
        ..reset()
        ..moveTo(source.dx - 2, source.dy)
        ..lineTo(x - 9, rayTop)
        ..lineTo(x + 9, rayTop)
        ..lineTo(source.dx + 2, source.dy)
        ..close();
      p
        ..shader = ui.Gradient.linear(origin, Offset(origin.dx, rayTop), [
          rewardColor.withValues(alpha: .2 * strength),
          rewardColor.withValues(alpha: 0),
        ])
        ..blendMode = BlendMode.plus;
      canvas.drawPath(path, p);
      p
        ..shader = null
        ..blendMode = BlendMode.srcOver;
    }
  }

  void _case(
    Canvas canvas,
    double width,
    double reveal,
    double opening,
    Color accent,
    double light,
  ) {
    final frame = resources.caseFrames.frameAt(opening);
    if (frame == null) {
      // Asset/decode failure must never block access to confirmed rewards.
      resources.casePainter.paint(
        canvas,
        width: width,
        reveal: reveal,
        opening: opening,
        accent: accent,
        light: light,
      );
      return;
    }
    final side = width / GachaStyle.caseImageVisibleWidth;
    final dest = Rect.fromLTWH(
      -side * GachaStyle.caseImageCenterX,
      -side * GachaStyle.caseImageGroundY,
      side,
      side,
    );
    final source = Rect.fromLTWH(
      0,
      0,
      frame.width.toDouble(),
      frame.height.toDouble(),
    );
    final p = resources.paint;
    p
      ..shader = null
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.srcOver
      ..filterQuality = FilterQuality.medium
      ..color = Colors.white
      ..colorFilter = ColorFilter.mode(
        accent.withValues(alpha: .32 * reveal * light),
        BlendMode.srcIn,
      );
    // Alpha silhouette rim follows the original Blender geometry.
    canvas.drawImageRect(frame, source, dest.inflate(1.1), p);
    p.colorFilter = ColorFilter.matrix([
      reveal,
      0,
      0,
      0,
      0,
      0,
      reveal,
      0,
      0,
      0,
      0,
      0,
      reveal,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ]);
    canvas.drawImageRect(frame, source, dest, p);
    p.colorFilter = null;
  }

  @override
  bool shouldRepaint(GachaScenePainter old) =>
      old.controller != controller || old.resources != resources;
}
