import 'dart:math' as math;
import 'grade_config.dart';

/// Immutable random coefficients, allocated once per scene, never per frame.
/// Positions are evaluated from absolute scene time so seeking/export is stable.
class GachaParticle {
  GachaParticle(math.Random random)
    : phase = random.nextDouble(),
      spread = random.nextDouble() * 2 - 1,
      speed = .5 + random.nextDouble(),
      size = .6 + random.nextDouble(),
      angle = random.nextDouble() * math.pi * 2;
  final double phase, spread, speed, size, angle;
}

class ParticlePool {
  ParticlePool(int seed, GachaQuality quality) {
    final random = math.Random(seed);
    slots = List.generate(
      QualityConfig.of(quality).capacity,
      (_) => GachaParticle(random),
      growable: false,
    );
  }
  late final List<GachaParticle> slots;
}
