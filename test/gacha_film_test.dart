import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:dollar_trapped/features/gacha/presentation/film/gacha_film_ignition.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_presentation.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_result.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_timeline.dart';
import 'package:dollar_trapped/features/gacha/presentation/grade_config.dart';
import 'package:dollar_trapped/features/gacha/presentation/film/gacha_film_track.dart';
import 'package:dollar_trapped/features/gacha/presentation/film/gacha_film_layer.dart';

class FilmPlatform extends VideoPlayerPlatform {
  final events = StreamController<VideoEvent>();
  bool fail = false, hold = false;
  int plays = 0, pauses = 0, disposals = 0;
  Duration position = Duration.zero;
  final assets = <String?>[];
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    assets.add(options.dataSource.asset);
    if (fail) {
      events.addError(
        PlatformException(
          code: 'decoder_error',
          message: 'test decoder unavailable',
        ),
      );
    } else if (!hold) {
      initialized();
    }
    return 1;
  }

  void initialized() => events.add(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(milliseconds: 5800),
      size: const Size(720, 1600),
    ),
  );
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events.stream;
  @override
  Future<void> dispose(int playerId) async {
    disposals++;
  }

  @override
  Future<void> play(int playerId) async {
    plays++;
  }

  @override
  Future<void> pause(int playerId) async {
    pauses++;
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Future<void> seekTo(int playerId, Duration value) async {
    position = value;
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(
    int playerId,
    bool value,
  ) async {}
  @override
  Widget buildView(int playerId) => const ColoredBox(color: Colors.black);
}

void main() {
  testWidgets(
    'export production film intro previews',
    (tester) async {
      if (!const bool.fromEnvironment('EXPORT_FILM_INTRO')) return;
      final track = GachaFilmTrack.fromJson(
        jsonDecode(File('assets/gacha/film/track.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      for (final grade in [GachaGrade.special, GachaGrade.rare]) {
        final snapshot = GachaResult(
          rewards: List.generate(
            10,
            (i) => GachaReward(
              id: '$i',
              title: '$i',
              grade: i == 6
                  ? grade
                  : (i == 3 ? GachaGrade.rare : GachaGrade.common),
            ),
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: GachaPresentation(
              key: ValueKey(grade),
              result: snapshot,
              useBlenderFilm: false,
            ),
          ),
        );
        final state = tester.state<GachaPresentationState>(
          find.byType(GachaPresentation),
        );
        state.controller.clock.stop();
        final root = 'build/gacha-art/source-movie/${grade.name}';
        Directory('$root/composite').createSync(recursive: true);
        for (var frame = 0; frame < 195; frame++) {
          state.controller.clock.value =
              frame * 1000 / 30 / state.controller.timeline.totalMs;
          await tester.runAsync(() async {
            final name = (frame + 1).toString().padLeft(4, '0');
            final codec = await ui.instantiateImageCodec(
              await File('$root/plate/$name.png').readAsBytes(),
            );
            final plate = (await codec.getNextFrame()).image;
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder)
              ..drawImage(plate, Offset.zero, Paint());
            GachaFilmPainter(
              state.controller,
              track,
              state.resources,
            ).paint(canvas, const Size(720, 1600));
            final picture = recorder.endRecording();
            final composite = await picture.toImage(720, 1600);
            final bytes = (await composite.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            await File(
              '$root/composite/$name.png',
            ).writeAsBytes(bytes.buffer.asUint8List());
            composite.dispose();
            picture.dispose();
            plate.dispose();
            codec.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
  late FilmPlatform platform;
  setUp(() {
    platform = FilmPlatform();
    VideoPlayerPlatform.instance = platform;
  });
  tearDown(() {
    unawaited(platform.events.close());
  });
  final result = GachaResult(
    rewards: [
      for (var i = 0; i < 10; i++)
        GachaReward(
          id: 'reward-$i',
          grade: i == 2 ? GachaGrade.special : GachaGrade.common,
          title: 'item-$i',
        ),
    ],
  );
  Widget scene({bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: GachaPresentation(result: result),
    ),
  );
  Future<GachaPresentationState> ready(WidgetTester tester) async {
    await tester.pumpWidget(scene());
    final state = tester.state<GachaPresentationState>(
      find.byType(GachaPresentation),
    );
    for (var i = 0; i < 60 && !(state.film!.ready || state.film!.failed); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await tester.pump();
    return state;
  }

  testWidgets(
    'movie owns intro clock, buffering and lifecycle; cards follow its completion',
    (tester) async {
      final state = await ready(tester);
      expect(state.film!.ready, isTrue);
      expect(platform.assets.single, 'assets/gacha/film/special.mp4');
      expect(state.resources.caseFrames.decodedCount, 0);
      platform.position = const Duration(milliseconds: 2000);
      await tester.pump(const Duration(milliseconds: 200));
      expect(state.controller.ms, closeTo(2000, 100));
      platform.events.add(VideoEvent(eventType: VideoEventType.bufferingStart));
      await tester.pump();
      final paused = state.controller.ms;
      await tester.pump(const Duration(milliseconds: 400));
      expect(state.controller.ms, paused);
      platform.events.add(VideoEvent(eventType: VideoEventType.bufferingEnd));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final background = state.controller.ms;
      await tester.pump(const Duration(seconds: 1));
      expect(state.controller.ms, background);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      platform.events.add(VideoEvent(eventType: VideoEventType.completed));
      await tester.pump();
      expect(state.film!.finished, isTrue);
      expect(state.controller.timeline.cardIndex(state.controller.ms), 0);
      expect(state.controller.result, same(result));
      await tester.tap(find.text('건너뛰기'));
      await tester.pump();
      expect(state.controller.complete, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      expect(platform.disposals, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'skip during decoder initialization never restarts or changes rewards',
    (tester) async {
      platform.hold = true;
      await tester.pumpWidget(scene());
      final state = tester.state<GachaPresentationState>(
        find.byType(GachaPresentation),
      );
      await tester.tap(find.text('건너뛰기'));
      await tester.pump();
      platform.initialized();
      await tester.pump();
      expect(state.controller.complete, isTrue);
      expect(state.controller.result, same(result));
      expect(platform.plays, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      expect(platform.disposals, 1);
    },
  );
  testWidgets('decoder failure falls back and keeps exact result accessible', (
    tester,
  ) async {
    platform.fail = true;
    final state = await ready(tester);
    expect(state.film!.failed, isTrue);
    expect(find.byKey(const Key('gacha-procedural-scene')), findsOneWidget);
    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    expect(state.controller.result, same(result));
    expect(state.controller.complete, isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('reduced motion does not initialize a decoder', (tester) async {
    await tester.pumpWidget(scene(reduced: true));
    expect(platform.assets, isEmpty);
    expect(find.text('확인'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'gold reversal boosts only special motion and rejoins before contact',
    () {
      final track = GachaFilmTrack.fromJson(
        jsonDecode(File('assets/gacha/film/track.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      GachaTimeline timeline(GachaGrade grade) => GachaTimeline(
        GachaResult(
          rewards: [GachaReward(id: 'x', grade: grade, title: 'x')],
        ),
        GradeConfig.defaults,
      );
      final special = timeline(GachaGrade.special);
      final rare = timeline(GachaGrade.rare);
      const reversal = GachaTimeline.reversalMs;
      expect(track.boost['startMs'], reversal);
      for (var ms = 0.0; ms <= reversal; ms += 10) {
        expect(track.sourceMs(ms, special), track.sourceMs(ms, rare));
      }
      final burst = track.sourceMs(reversal + 50, special) - reversal;
      expect(burst, greaterThan(100));
      expect(track.sourceMs(reversal + 50, rare) - reversal, closeTo(50, .001));
      var previous = track.sourceMs(reversal.toDouble(), special);
      for (var ms = reversal + 1.0; ms <= special.bounds[2]; ms++) {
        final current = track.sourceMs(ms, special);
        expect(current, greaterThan(previous), reason: 'no rewind at $ms');
        previous = current;
      }
      expect(track.sourceMs(3650, special), 3650);
      expect(track.sourceMs(special.impactMs.toDouble(), special), 4070);
      expect(track.trailScale(reversal.toDouble(), true), greaterThan(1.5));
      expect(track.trailScale(reversal.toDouble(), false), 1);
      expect(track.trailScale(reversal + 320, true), 1);
    },
  );
  test(
    'one source releases ten heads, slows the spread, then keeps the existing row',
    () {
      final track = GachaFilmTrack.fromJson(
        jsonDecode(File('assets/gacha/film/track.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final tl = GachaTimeline(result, GradeConfig.defaults);
      final start = [for (var i = 0; i < 10; i++) track.point(0, tl, 'ten', i)];
      expect(start.toSet(), {GachaFilmIgnition.origin});
      for (var i = 0; i < 10; i++) {
        expect(track.point(250, tl, 'ten', i), GachaFilmIgnition.origin);
        expect(
          (track.point(251, tl, 'ten', i) - GachaFilmIgnition.origin).distance,
          lessThan(.001),
        );
      }
      final released = [
        for (var i = 0; i < 10; i++) track.point(650, tl, 'ten', i),
      ];
      expect(released.toSet().length, 10);
      expect(
        GachaFilmIgnition.spread(950) - GachaFilmIgnition.spread(600),
        lessThan(
          (GachaFilmIgnition.spread(600) - GachaFilmIgnition.spread(250)) / 5,
        ),
      );
      for (final ms in [1850.0, 2500.0, 3200.0]) {
        final row = [
          for (var i = 0; i < 10; i++) track.point(ms, tl, 'ten', i),
        ];
        for (var i = 1; i < 10; i++) {
          expect(row[i].dy, closeTo(row.first.dy, .001));
          expect(row[i].dx - row[i - 1].dx, greaterThan(.04));
        }
        expect(row.first.dy, inInclusiveRange(.42, .50));
      }
      expect(track.point(1850, tl, 'case').dy, greaterThan(1));
      expect(track.point(3650, tl, 'case').dy, lessThan(1));
    },
  );
  testWidgets(
    'source and released heads remain visible through the start of descent',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GachaPresentation(result: result, useBlenderFilm: false),
        ),
      );
      final state = tester.state<GachaPresentationState>(
        find.byType(GachaPresentation),
      );
      state.controller.clock.stop();
      final track = GachaFilmTrack.fromJson(
        jsonDecode(File('assets/gacha/film/track.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      const size = Size(420, 933);
      for (final ms in [
        90.0,
        250.0,
        500.0,
        549.0,
        550.0,
        700.0,
        950.0,
        1850.0,
      ]) {
        state.controller.clock.value = ms / state.controller.timeline.totalMs;
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          GachaFilmPainter(
            state.controller,
            track,
            state.resources,
          ).paint(Canvas(recorder), size);
          final picture = recorder.endRecording();
          final image = await picture.toImage(420, 933);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final viewport = track.viewport(size);
          for (var i = 0; i < 10; i++) {
            final p = track.point(ms, state.controller.timeline, 'ten', i);
            final x = (viewport.left + p.dx * viewport.width).round();
            final y = (viewport.top + p.dy * viewport.height).round();
            var visible = false;
            for (var dy = -3; dy <= 3; dy++) {
              for (var dx = -3; dx <= 3; dx++) {
                if (bytes.getUint8(((y + dy) * 420 + x + dx) * 4 + 3) > 128) {
                  visible = true;
                }
              }
            }
            expect(visible, isTrue, reason: 'head $i must persist at ${ms}ms');
          }
          image.dispose();
          picture.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('first source is rainbow only when a SPECIAL is present', (
    tester,
  ) async {
    final track = GachaFilmTrack.fromJson(
      jsonDecode(File('assets/gacha/film/track.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    for (final grade in GachaGrade.values) {
      final snapshot = GachaResult(
        rewards: List.generate(
          10,
          (i) => GachaReward(
            id: '$i',
            grade: i == 6 ? grade : GachaGrade.common,
            title: '$i',
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GachaPresentation(
            key: ValueKey(grade),
            result: snapshot,
            useBlenderFilm: false,
          ),
        ),
      );
      final state = tester.state<GachaPresentationState>(
        find.byType(GachaPresentation),
      );
      state.controller.clock.stop();
      for (final ms in [140.0, 600.0, 950.0, 1850.0]) {
        state.controller.clock.value = ms / state.controller.timeline.totalMs;
        await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder)
            ..drawColor(const Color(0xFF03070E), BlendMode.src);
          GachaFilmPainter(
            state.controller,
            track,
            state.resources,
          ).paint(canvas, const Size(420, 933));
          final picture = recorder.endRecording();
          final image = await picture.toImage(420, 933);
          if (ms == 140) {
            final bytes = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            var colored = 0;
            for (var i = 0; i < bytes.lengthInBytes; i += 4) {
              final rgb = [
                bytes.getUint8(i),
                bytes.getUint8(i + 1),
                bytes.getUint8(i + 2),
              ]..sort();
              if (bytes.getUint8(i + 3) > 40 && rgb.last - rgb.first > 60) {
                colored++;
              }
            }
            expect(colored, grade == GachaGrade.special ? greaterThan(100) : 0);
          }
          final dir = Directory('build/gacha-art/ignition-review')
            ..createSync(recursive: true);
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          File(
            '${dir.path}/${grade.name}-${ms.round()}.png',
          ).writeAsBytesSync(png.buffer.asUint8List());
          image.dispose();
          picture.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
  test(
    'Blender tracks preserve all ten distinct contacts and match grade phase boundaries',
    () async {
      final track = GachaFilmTrack.fromJson(
        jsonDecode(File('assets/gacha/film/track.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      for (final grade in GachaGrade.values) {
        final tl = GachaTimeline(
          GachaResult(
            rewards: [GachaReward(id: 'x', grade: grade, title: 'x')],
          ),
          GradeConfig.defaults,
        );
        for (var i = 0; i < 7; i++) {
          expect(
            track.sourceMs(tl.bounds[i].toDouble(), tl),
            closeTo(track.bounds[i], .001),
          );
        }
        final contacts = [
          for (var i = 0; i < 10; i++)
            track.point(tl.openingMs.toDouble(), tl, 'ten', i),
        ];
        expect(contacts.toSet().length, 10);
        for (final p in contacts) {
          expect(p.dx, inInclusiveRange(0.1, .9));
          expect(p.dy, inInclusiveRange(.5, .85));
        }
        for (final size in [
          const Size(420, 900),
          const Size(900, 420),
          const Size(800, 1000),
        ]) {
          final viewport = track.viewport(size);
          expect(viewport.left, greaterThanOrEqualTo(-.001));
          expect(viewport.top, greaterThanOrEqualTo(-.001));
          expect(viewport.width / viewport.height, closeTo(.45, .001));
        }
      }
    },
  );
}
