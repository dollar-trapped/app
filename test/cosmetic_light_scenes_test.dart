import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:dollar_trapped/features/cosmetics/rendering/effects/cosmetic_scene_painter.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> frame(String style, double phase) async {
  final recorder = ui.PictureRecorder();
  CosmeticScenePainter(
    style: style,
    phase: phase,
  ).paint(ui.Canvas(recorder), const ui.Size(100, 34));
  final picture = recorder.endRecording();
  final image = await picture.toImage(100, 34);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = Uint8List.fromList(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return pixels;
}

int changedPixels(Uint8List a, Uint8List b) {
  var count = 0;
  for (var i = 0; i < a.length; i += 4) {
    if (List.generate(
      4,
      (channel) => (a[i + channel] - b[i + channel]).abs(),
    ).any((difference) => difference > 3)) {
      count++;
    }
  }
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'small chat scenes look different, visibly move, and loop smoothly',
    () async {
      final aurora = await frame('aurora', 0);
      final starlight = await frame('starlight', 0);
      expect(changedPixels(aurora, starlight), greaterThan(340));
      for (final style in ['aurora', 'starlight']) {
        final start = await frame(style, 0);
        expect(changedPixels(start, await frame(style, .25)), greaterThan(100));
        expect(changedPixels(start, await frame(style, 1)), lessThan(34));
      }
    },
  );
}
