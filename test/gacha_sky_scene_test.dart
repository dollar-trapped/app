import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_flight.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_timeline.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_presentation.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_result.dart';
import 'package:dollar_trapped/features/gacha/presentation/grade_config.dart';
import 'package:dollar_trapped/features/gacha/presentation/painters/gacha_scene_painter.dart';
import 'package:dollar_trapped/features/gacha/presentation/painters/blender_case_frames.dart';

GachaResult fixture(GachaGrade grade, int count) => GachaResult(
  rewards: [
    for (var i = 0; i < count; i++)
      GachaReward(
        id: 'reward-$i',
        grade: i == 0 || (count == 10 && i == 6)
            ? grade
            : (i == 3 && grade != GachaGrade.common
                  ? GachaGrade.rare
                  : GachaGrade.common),
        title: switch (i % 3) {
          0 => '달러의 빛',
          1 => '새로운 이름',
          _ => '별의 흔적',
        },
        duplicate: i.isOdd,
        chips: 1,
      ),
  ],
);
void main() {
  test(
    'camera follows an accelerating descent with ground initially offscreen',
    () {
      final tl = GachaTimeline(
        fixture(GachaGrade.special, 10),
        GradeConfig.defaults,
      );
      final flight = GachaFlight(tl);
      const size = Size(420, 900);
      expect(flight.cameraY(size, 0), 0);
      expect(
        GachaStyle.worldHorizonY * size.height,
        greaterThan(size.height * 2),
      );
      final distances = [
        for (final ms in [750, 1000, 1250, 1500])
          GachaFlight.point(size, flight.travel(ms.toDouble())).dy,
      ];
      expect(
        distances[3] - distances[2],
        greaterThan(distances[2] - distances[1]),
      );
      expect(
        distances[2] - distances[1],
        greaterThan(distances[1] - distances[0]),
      );
      expect(
        flight.cameraY(size, tl.bounds[2] - 100.0),
        greaterThan(size.height * 2),
      );
      final attackStart = tl.impactMs - GachaTimeline.strikeMs;
      final earlyAttack =
          flight.travel(attackStart + 60) -
          flight.travel(attackStart.toDouble());
      final lateAttack =
          flight.travel(tl.impactMs.toDouble()) -
          flight.travel(tl.impactMs - 60);
      expect(lateAttack, greaterThan(earlyAttack));
      expect(
        GachaFlight.landing(size).dy -
            flight.cameraY(size, tl.impactMs.toDouble()),
        closeTo(size.height * GachaStyle.landingY, .001),
      );
      expect(flight.cameraY(size, 5000), flight.cameraY(size, 6000));
    },
  );
  testWidgets(
    'mixed batch retains green blue and gold pixels in the same descent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GachaPresentation(
            useBlenderFilm: false,
            result: fixture(GachaGrade.special, 10),
          ),
        ),
      );
      final state = tester.state<GachaPresentationState>(
        find.byType(GachaPresentation),
      );
      state.controller.clock.stop();
      for (final ms in [
        GachaTimeline.reversalMs - 250,
        GachaTimeline.reversalMs + 150,
      ]) {
        state.controller.clock.value = ms / state.controller.timeline.totalMs;
        await tester.pump();
        final counts = [0, 0, 0];
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          GachaSkyPainter(
            state.resources,
            state.controller,
          ).paint(canvas, const Size(420, 900));
          GachaScenePainter(
            controller: state.controller,
            resources: state.resources,
          ).paint(canvas, const Size(420, 900));
          final picture = recorder.endRecording();
          final image = await picture.toImage(420, 900);
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final bytes = data!.buffer.asUint8List();
          for (var i = 0; i < bytes.length; i += 4) {
            final r = bytes[i], g = bytes[i + 1], b = bytes[i + 2];
            if (g > 150 && g > r * 1.25 && g > b * 1.1) counts[0]++;
            if (b > 150 && b > r * 1.25 && b > g * 1.1) counts[1]++;
            if (r > 150 && g > 130 && r > b * 1.4 && g > b * 1.2) counts[2]++;
          }
          image.dispose();
          picture.dispose();
        });
        expect(counts[0], greaterThan(20));
        expect(counts[1], greaterThan(20));
        expect(counts[2], ms < GachaTimeline.reversalMs ? 0 : greaterThan(20));
      }
    },
  );
  testWidgets('one reward keeps one light; ten keep ten even in Low quality', (
    tester,
  ) async {
    for (final count in [1, 10]) {
      for (final quality in GachaQuality.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: GachaPresentation(
              useBlenderFilm: false,
              key: ValueKey('$count-$quality'),
              result: fixture(GachaGrade.special, count),
              quality: quality,
            ),
          ),
        );
        final state = tester.state<GachaPresentationState>(
          find.byType(GachaPresentation),
        );
        final lights = state.resources.lights;
        expect(lights.length, count);
        expect(
          lights.map((light) => light.reward.id),
          state.controller.result.rewards.map((reward) => reward.id),
        );
        final positions = lights
            .map((light) => light.offset(const Size(420, 900), .5))
            .toSet();
        expect(positions.length, count);
        if (count == 10) {
          final xs = positions.map((p) => p.dx).toList()..sort();
          for (var i = 1; i < xs.length; i++) {
            expect(xs[i] - xs[i - 1], greaterThan(30));
          }
        }
        for (final light in lights) {
          expect(
            light.offset(const Size(420, 900), 1),
            light.target(const Size(420, 900)),
          );
          expect(light.target(const Size(420, 900)).dy, lessThan(0));
        }
        for (final t in [.5, .84, .9, .95, 1.0]) {
          for (var i = 0; i < lights.length; i++) {
            for (var j = i + 1; j < lights.length; j++) {
              expect(
                (lights[i].offset(const Size(420, 900), t) -
                        lights[j].offset(const Size(420, 900), t))
                    .distance,
                greaterThan(12),
                reason: 'lights $i/$j must not merge at $t',
              );
              expect(
                lights[j].strikeDelayMs,
                greaterThan(lights[i].strikeDelayMs),
              );
            }
          }
        }
      }
    }
  });
  testWidgets('original Blender closed and open frames load and release', (
    tester,
  ) async {
    final frames = BlenderCaseFrames(GachaQuality.low);
    await tester.runAsync(() => frames.prepare());
    expect(frames.ready, isTrue);
    expect(frames.decodedCount, 24);
    expect(frames.frameAt(0)!.width, 384);
    expect(frames.frameAt(1), isNot(same(frames.frameAt(0))));
    expect(frames.frameAt(-1), same(frames.frameAt(0)));
    expect(frames.frameAt(2), same(frames.frameAt(1)));
    frames.dispose();
    expect(frames.decodedCount, 0);
    final abandoned = BlenderCaseFrames(GachaQuality.low);
    await tester.runAsync(() async {
      final loading = abandoned.prepare();
      abandoned.dispose();
      await loading;
    });
    expect(abandoned.ready, isFalse);
    expect(abandoned.decodedCount, 0);
  });
  testWidgets('export descending camera and individually graded lights', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('EXPORT_TRACKING_SCENE')) return;
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: GachaPresentation(
          useBlenderFilm: false,
          result: fixture(GachaGrade.special, 10),
        ),
      ),
    );
    final state = tester.state<GachaPresentationState>(
      find.byType(GachaPresentation),
    );
    state.controller.clock.stop();
    for (var i = 0; i < 200 && !state.resources.caseFrames.ready; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(state.resources.caseFrames.ready, isTrue);
    await tester.runAsync(() async {
      await Directory('/private/tmp/gacha-tracking').create(recursive: true);
      for (final ms in [3000, 3400, 3650, 3950, 4030, 4070, 4140, 4230, 4450]) {
        state.controller.clock.value = ms / state.controller.timeline.totalMs;
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        GachaSkyPainter(
          state.resources,
          state.controller,
        ).paint(canvas, const Size(420, 900));
        GachaScenePainter(
          controller: state.controller,
          resources: state.resources,
        ).paint(canvas, const Size(420, 900));
        final picture = recorder.endRecording();
        final image = await picture.toImage(420, 900);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '/private/tmp/gacha-tracking/$ms.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    });
  });
  testWidgets('rare and special render identically before the reversal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final captures = <GachaGrade, List<List<int>>>{};
    for (final grade in [GachaGrade.rare, GachaGrade.special]) {
      await tester.pumpWidget(
        MaterialApp(
          home: GachaPresentation(
            useBlenderFilm: false,
            key: ValueKey(grade),
            result: fixture(grade, 1),
          ),
        ),
      );
      final state = tester.state<GachaPresentationState>(
        find.byType(GachaPresentation),
      );
      state.controller.clock.stop();
      captures[grade] = [];
      for (final ms in [
        400,
        1000,
        GachaTimeline.reversalMs - 250,
        GachaTimeline.reversalMs - 1,
        GachaTimeline.reversalMs + 1,
      ]) {
        state.controller.clock.value = ms / state.controller.timeline.totalMs;
        await tester.pump();
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          // Render the exact production painters using the same viewport.
          final c = Canvas(recorder);
          GachaSkyPainter(
            state.resources,
            state.controller,
          ).paint(c, const Size(420, 900));
          GachaScenePainter(
            controller: state.controller,
            resources: state.resources,
          ).paint(c, const Size(420, 900));
          final picture = recorder.endRecording();
          final frame = await picture.toImage(420, 900);
          final bytes = await frame.toByteData();
          captures[grade]!.add(bytes!.buffer.asUint8List().toList());
          frame.dispose();
          picture.dispose();
        });
      }
    }
    for (var i = 0; i < 4; i++) {
      expect(captures[GachaGrade.rare]![i], captures[GachaGrade.special]![i]);
    }
    expect(
      captures[GachaGrade.rare]![4],
      isNot(captures[GachaGrade.special]![4]),
    );
  });
  testWidgets('quality caps reuse fixed particle objects across the timeline', (
    tester,
  ) async {
    for (final quality in GachaQuality.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: GachaPresentation(
            useBlenderFilm: false,
            key: ValueKey(quality),
            result: fixture(GachaGrade.special, 10),
            quality: quality,
          ),
        ),
      );
      final state = tester.state<GachaPresentationState>(
        find.byType(GachaPresentation),
      );
      final slots = List.of(state.resources.pool.slots);
      expect(slots.length, quality == GachaQuality.high ? 240 : 96);
      for (final ms in [1000, 2500, 3800, 5000, 8000]) {
        state.controller.clock.value = ms / state.controller.timeline.totalMs;
        await tester.pump();
        for (var i = 0; i < slots.length; i++) {
          expect(state.resources.pool.slots[i], same(slots[i]));
        }
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets(
    'export deterministic production widget movies',
    (tester) async {
      if (!const bool.fromEnvironment('EXPORT_GACHA_MOVIE')) return;
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        final loader = FontLoader('ReviewSans')
          ..addFont(rootBundle.load('assets/fonts/NotoSansKR.ttf'));
        await loader.load();
      });
      for (final grade in GachaGrade.values) {
        for (final count in [1, 10]) {
          for (final quality in GachaQuality.values) {
            final name = '${grade.name}_${count}_${quality.name}';
            const selected = String.fromEnvironment('GACHA_MOVIE_CASES');
            if (selected.isNotEmpty && !selected.split(',').contains(name)) {
              continue;
            }
            final result = fixture(grade, count);
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(fontFamily: 'ReviewSans'),
                home: RepaintBoundary(
                  key: const Key('movie'),
                  child: GachaPresentation(
                    useBlenderFilm: false,
                    key: ValueKey(name),
                    result: result,
                    quality: quality,
                  ),
                ),
              ),
            );
            final state = tester.state<GachaPresentationState>(
              find.byType(GachaPresentation),
            );
            state.controller.clock.stop();
            for (var i = 0; i < 200 && !state.resources.caseFrames.ready; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 10)),
              );
              await tester.pump();
            }
            expect(state.resources.caseFrames.ready, isTrue);
            final frames = (state.controller.timeline.totalMs / 1000 * 15)
                .ceil();
            const output = String.fromEnvironment(
              'GACHA_MOVIE_DIR',
              defaultValue: '/private/tmp/gacha-procedural',
            );
            final dir = Directory('$output/$name');
            await tester.runAsync(() => dir.create(recursive: true));
            for (var i = 0; i <= frames + 12; i++) {
              state.controller.clock.value =
                  ((i * 1000 / 15).round() / state.controller.timeline.totalMs)
                      .clamp(0, 1);
              await tester.pump();
              await tester.runAsync(() async {
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(const Key('movie')),
                );
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '${dir.path}/frame_${i.toString().padLeft(4, '0')}.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
              expect(tester.takeException(), isNull);
            }
          }
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
