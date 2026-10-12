import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_presentation.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_result.dart';
import 'package:dollar_trapped/features/gacha/presentation/film/gacha_film_track.dart';
import 'package:dollar_trapped/features/gacha/presentation/film/gacha_film_layer.dart';
import 'package:dollar_trapped/features/gacha/presentation/film/gacha_film_impact.dart';

// Opt-in artifact generation; run via tool/gacha_art/export_preview.py.
void main() {
  testWidgets(
    'export production film intro previews',
    (tester) async {
      final track = GachaFilmTrack.fromJson(
        jsonDecode(File('assets/gacha/film/track.json').readAsStringSync())
            as Map<String, dynamic>,
        burstSeed: 74021,
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
              ..clipRect(const Rect.fromLTWH(0, 0, 720, 1600))
              ..transform(
                GachaFilmImpact.matrix(
                  const Size(720, 1600),
                  state.controller.ms,
                  state.controller.timeline,
                  state.controller.configs[grade]!,
                ).storage,
              )
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
    skip: !const bool.fromEnvironment('EXPORT_FILM_INTRO'),
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
