import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../gacha_timeline.dart';
import '../gacha_result.dart';
import 'gacha_film_ignition.dart';

/// Projected directly from the Blender camera, not a second guessed trajectory.
class GachaFilmTrack {
  static const formationEndSourceMs = GachaFilmIgnition.formationMs;
  static const ignitionMs = 90;
  GachaFilmTrack.fromJson(Map<String, dynamic> json, {int? burstSeed})
    : firework = GachaFireworkPattern(
        burstSeed ?? math.Random().nextInt(1 << 30),
      ),
      boost = (json['specialBoost'] as Map<String, dynamic>?) ?? const {},
      landing = (json['landing'] as Map<String, dynamic>?) ?? const {},
      _production = ((json['production'] as Map<String, dynamic>?) ?? const {})
          .map((name, value) => MapEntry(name, _FilmSamples(value))),
      fps = (json['fps'] as num).toDouble(),
      sourceSize = Size(
        (json['width'] as num).toDouble(),
        (json['height'] as num).toDouble(),
      ),
      bounds = (json['bounds'] as List).cast<num>(),
      frames = (json['frames'] as List).cast<Map<String, dynamic>>();
  final double fps;
  final GachaFireworkPattern firework;
  final Map<String, dynamic> boost;
  final Map<String, dynamic> landing;

  final Map<String, _FilmSamples> _production;
  final Size sourceSize;
  final List<num> bounds;
  final List<Map<String, dynamic>> frames;
  /// Duration of the last strike, shared with the Blender landing config.
  int get strikeMs => landing.isEmpty
      ? 80
      : ((landing['windowMs'] as num) -
                (landing['brakeMs'] as num) -
                (landing['holdMs'] as num))
            .toInt();

  static Future<GachaFilmTrack> load() async => GachaFilmTrack.fromJson(
    jsonDecode(await rootBundle.loadString('assets/gacha/film/track.json'))
        as Map<String, dynamic>,
  );

  double sourceMs(double ms, GachaTimeline timeline) {
    final special =
        timeline.result.highest == GachaGrade.special && boost.isNotEmpty;
    final lead = special ? (boost['leadMs'] as num).toDouble() : 0.0;
    for (var i = 0; i < bounds.length - 1; i++) {
      if (ms <= timeline.bounds[i + 1]) {
        final f = timeline.progress(
          ms,
          timeline.bounds[i],
          timeline.bounds[i + 1],
        );
        final base = bounds[i] + (bounds[i + 1] - bounds[i]) * f;
        if (i == 1 && special) {
          final u =
              ((ms - (boost['startMs'] as num)) /
                      ((boost['endMs'] as num) - (boost['startMs'] as num)))
                  .clamp(0.0, 1.0);
          return base + lead * u * u * (3 - 2 * u);
        }
        if (i == 2) {
          final travel = _approachTravel(ms, timeline, lead);
          return (travel <= .89
                  ? 3650 +
                        260 *
                            (1 -
                                math.pow(
                                  (1 - (travel - .84) / .05).clamp(0.0, 1.0),
                                  1 / 3,
                                ))
                  : 3910 +
                        160 *
                            math.pow(
                              ((travel - .89) / .11).clamp(0.0, 1.0),
                              1 / 3,
                            ))
              .toDouble();
        }
        return base;
      }
    }
    return bounds.last.toDouble();
  }

  double _approachTravel(double ms, GachaTimeline tl, double lead) {
    final start = .84 + .05 * (1 - math.pow(1 - lead / 260, 3));
    final duration = tl.impactMs - tl.bounds[2];
    double position(double f) =>
        (start + (1 - start) * (f - .35 * f * f + .35 * f * f * f)).toDouble();
    if (landing.isEmpty) return position((ms - tl.bounds[2]) / duration);
    final window = (landing['windowMs'] as num).toDouble();
    final brake = (landing['brakeMs'] as num).toDouble();
    final launch = brake + (landing['holdMs'] as num);
    final windup = tl.impactMs - window;
    if (ms < windup) return position((ms - tl.bounds[2]) / duration);
    final f = (windup - tl.bounds[2]) / duration;
    final at = position(f);
    final velocity = (1 - start) * (1 - .7 * f + 1.05 * f * f) / duration;
    final age = ms - windup;
    final ready = at + velocity * brake / 2;
    if (age < brake) {
      return (at + velocity * (age - age * age / (2 * brake))).toDouble();
    }
    if (age < launch) return ready.toDouble();
    final u = ((age - launch) / (window - launch)).clamp(0.0, 1.0);
    return (ready + (1 - ready) * math.pow(u, (landing['power'] as num?) ?? 3))
        .toDouble();
  }

  /// Short speed streak on the gold heads, without changing their row/targets.
  double trailScale(double ms, bool reversed) {
    if (!reversed || boost.isEmpty) return 1;
    final u = ((ms - (boost['startMs'] as num)) / (boost['trailMs'] as num))
        .clamp(0.0, 1.0);
    return 1 + (boost['trailStretch'] as num) * (1 - u) * (1 - u);
  }

  Offset point(double ms, GachaTimeline timeline, String key, [int? index]) {
    final source = sourceMs(ms, timeline);
    if ((key == 'one' || key == 'ten') &&
        source < GachaFilmIgnition.formationMs) {
      final target = _sample(
        frames,
        GachaFilmIgnition.formationMs * fps / 1000,
        key,
        index,
      );
      return GachaFilmIgnition.position(
        source,
        target,
        index!,
        key == 'one' ? 1 : 10,
        firework,
      );
    }
    final samples = _production[timeline.result.highest.name];
    if (samples != null) {
      // These are evaluated in Blender at uniform playback timestamps. Do not
      // interpolate the sparse canonical frames through the inverse time warp:
      // that creates uneven motion even when Flutter paints every vsync.
      var frame = ms * samples.fps / 1000;
      if (key == 'one' || key == 'ten') {
        // Contact can fall between two projection samples (SPECIAL: 4570ms).
        // Land exactly at the impact event instead of interpolating through it
        // and leaving the head above the lid when its flash starts.
        final contact = timeline.impactMs * samples.fps / 1000;
        if (frame >= contact) {
          frame = math.max(frame, contact.ceilToDouble());
        } else if (frame.floor() == contact.floor() && contact % 1 != 0) {
          final a = _sample(
            samples.frames,
            contact.floorToDouble(),
            key,
            index,
          );
          final b = _sample(samples.frames, contact.ceilToDouble(), key, index);
          return Offset.lerp(a, b, (frame - contact.floor()) / (contact % 1))!;
        }
      }
      return _sample(samples.frames, frame, key, index);
    }
    return _sample(frames, source * fps / 1000, key, index);
  }

  Offset _sample(
    List<Map<String, dynamic>> samples,
    double frame,
    String key,
    int? index,
  ) {
    final at = frame.clamp(0.0, samples.length - 1.0);
    final a = at.floor(), b = math.min(a + 1, samples.length - 1);
    Offset read(int i) {
      final value = index == null
          ? samples[i][key]
          : (samples[i][key] as List)[index];
      final xy = value as List;
      return Offset((xy[0] as num).toDouble(), (xy[1] as num).toDouble());
    }

    return Offset.lerp(read(a), read(b), at - a)!;
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

class _FilmSamples {
  _FilmSamples(Map<String, dynamic> json)
    : fps = (json['fps'] as num).toDouble(),
      frames = (json['frames'] as List).cast<Map<String, dynamic>>();
  final double fps;
  final List<Map<String, dynamic>> frames;
}
