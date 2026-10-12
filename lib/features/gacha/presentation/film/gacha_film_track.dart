import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../gacha_timeline.dart';
import '../gacha_result.dart';
import 'gacha_film_ignition.dart';

/// Projected directly from the Blender camera, not a second guessed trajectory.
class GachaFilmTrack {
  static const formationEndSourceMs = 1850;
  static const ignitionMs = 90;
  GachaFilmTrack.fromJson(Map<String, dynamic> json)
    : boost = (json['specialBoost'] as Map<String, dynamic>?) ?? const {},
      fps = (json['fps'] as num).toDouble(),
      sourceSize = Size(
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      bounds = (json['bounds'] as List).cast<num>(),
      frames = (json['frames'] as List).cast<Map<String, dynamic>>();
  final double fps;
  final Map<String, dynamic> boost;
  final Size sourceSize;
  final List<num> bounds;
  final List<Map<String, dynamic>> frames;
  static Future<GachaFilmTrack> load() async => GachaFilmTrack.fromJson(
    jsonDecode(await rootBundle.loadString('assets/gacha/film/track.json'))
        as Map<String, dynamic>,
  );

  double sourceMs(double ms, GachaTimeline timeline) {
    if (timeline.result.highest == GachaGrade.special && boost.isNotEmpty) {
      final start = (boost['startMs'] as num).toDouble();
      final end = (boost['endMs'] as num).toDouble();
      if (ms > start && ms < end) {
        final u = (ms - start) / (end - start);
        ms += (end - start) * (boost['gain'] as num) * u * (1 - u) * (1 - u);
      }
    }
    for (var i = 0; i < bounds.length - 1; i++) {
      if (ms <= timeline.bounds[i + 1]) {
        final f = timeline.progress(
          ms,
          timeline.bounds[i],
          timeline.bounds[i + 1],
        );
        return bounds[i] + (bounds[i + 1] - bounds[i]) * f;
      }
    }
    return bounds.last.toDouble();
  }

  /// Short speed streak on the gold heads, without changing their row/targets.
  double trailScale(double ms, bool reversed) {
    if (!reversed || boost.isEmpty) return 1;
    final u = ((ms - (boost['startMs'] as num)) / (boost['trailMs'] as num))
        .clamp(0.0, 1.0);
    return 1 + (boost['trailStretch'] as num) * (1 - u) * (1 - u);
  }

  Offset point(double ms, GachaTimeline timeline, String key, [int? index]) {
    final frame = (sourceMs(ms, timeline) * fps / 1000).clamp(
      0.0,
      frames.length - 1.0,
    );
    final a = frame.floor(), b = math.min(a + 1, frames.length - 1);
    Offset read(int i) {
      final value = index == null
          ? frames[i][key]
          : (frames[i][key] as List)[index];
      final xy = value as List;
      return Offset((xy[0] as num).toDouble(), (xy[1] as num).toDouble());
    }

    final projected = Offset.lerp(read(a), read(b), frame - a)!;
    final source = sourceMs(ms, timeline);
    if ((key == 'one' || key == 'ten') &&
        source < GachaFilmIgnition.formationMs) {
      return GachaFilmIgnition.position(source, projected);
    }
    return projected;
  }

  /// Contain preserves the camera projection even on unfolded/landscape devices.
  Rect viewport(Size size) {
    final scale = math.min(
      size.width / sourceSize.width,
      size.height / sourceSize.height,
    );
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: sourceSize.width * scale,
      height: sourceSize.height * scale,
    );
  }
}
