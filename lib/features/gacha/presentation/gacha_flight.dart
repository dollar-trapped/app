import 'dart:math' as math;
import 'package:flutter/animation.dart';
import 'gacha_timeline.dart';
import 'grade_config.dart';

/// A tall world, followed by a descending camera. The ground starts offscreen.
class GachaFlight {
  const GachaFlight(this.timeline);
  final GachaTimeline timeline;

  double travel(double ms) {
    if (ms >= timeline.impactMs) return 1;
    final falling = timeline.progress(
      ms,
      timeline.bounds[1],
      timeline.bounds[2],
    );
    if (ms < timeline.bounds[2]) {
      return GachaStyle.flightQuietTravel *
          Curves.easeInQuad.transform(falling);
    }
    final strike = timeline.impactMs - GachaTimeline.strikeMs;
    if (ms >= strike) {
      return GachaStyle.flightStrikeTravel +
          (1 - GachaStyle.flightStrikeTravel) *
              Curves.easeInCubic.transform(
                timeline.progress(ms, strike, timeline.impactMs),
              );
    }
    final quiet = Curves.easeOutCubic.transform(
      timeline.progress(ms, timeline.bounds[2], strike),
    );
    return GachaStyle.flightQuietTravel +
        (GachaStyle.flightStrikeTravel - GachaStyle.flightQuietTravel) * quiet;
  }

  static Offset landing(Size size) => Offset(
    size.width * GachaStyle.landingX,
    size.height * GachaStyle.worldGroundY,
  );

  static Offset point(Size size, double travel) {
    final t = travel.clamp(0.0, 1.0);
    final x = .72 * (1 - t) * (1 - t) + .48 * (2 * (1 - t) * t) + .5 * t * t;
    return Offset(
      size.width * x,
      size.height * (GachaStyle.worldStartY + GachaStyle.worldFallDistance * t),
    );
  }

  double cameraY(Size size, double ms) {
    final target = math.max(
      0.0,
      point(size, travel(ms)).dy - size.height * GachaStyle.cameraFollowY,
    );
    final maxY = size.height * (GachaStyle.worldGroundY - GachaStyle.landingY);
    final easeDistance = size.height * GachaStyle.cameraLandingEase;
    if (target < maxY - easeDistance) return target;
    // Ease into the landing composition while the case continues downward.
    return maxY -
        easeDistance +
        easeDistance *
            Curves.easeOutQuad.transform(
              ((target - (maxY - easeDistance)) / (easeDistance * 2)).clamp(
                0,
                1,
              ),
            );
  }
}
