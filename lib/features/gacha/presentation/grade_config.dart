import 'package:flutter/material.dart';
import 'gacha_result.dart';

enum GachaQuality { high, low }

class GradeConfig {
  const GradeConfig({
    required this.label,
    required this.color,
    required this.particles,
    required this.smoke,
    required this.shake,
    required this.soundKey,
    required this.haptic,
    required this.cardMs,
  });
  final String label, soundKey;
  final Color color;
  final int particles, smoke, cardMs;
  final double shake;
  final int haptic;
  static const defaults = <GachaGrade, GradeConfig>{
    GachaGrade.common: GradeConfig(
      label: 'COMMON',
      color: Color(0xFF65E6A3),
      particles: 72,
      smoke: 18,
      shake: 3,
      soundKey: 'common',
      haptic: 0,
      cardMs: 650,
    ),
    GachaGrade.rare: GradeConfig(
      label: 'RARE',
      color: Color(0xFF69B6FF),
      particles: 140,
      smoke: 30,
      shake: 6,
      soundKey: 'rare',
      haptic: 1,
      cardMs: 900,
    ),
    GachaGrade.special: GradeConfig(
      label: 'SPECIAL',
      color: Color(0xFFFFD361),
      particles: 240,
      smoke: 48,
      shake: 10,
      soundKey: 'special',
      haptic: 2,
      cardMs: 1500,
    ),
  };
}

class QualityConfig {
  const QualityConfig(this.capacity, this.smokeLimit, this.blur, this.rays);
  final int capacity, smokeLimit, rays;
  final double blur;
  static const high = QualityConfig(240, 48, 8, 10);
  static const low = QualityConfig(96, 16, 2, 4);
  static QualityConfig of(GachaQuality value) =>
      value == GachaQuality.high ? high : low;
}

/// Art direction constants, in logical pixels or normalized scene coordinates.
abstract final class GachaStyle {
  static const cardSurface = Color(0xF5091523);
  static const metalHighlight = Color(0xFF8497A2);
  static const metalMid = Color(0xFF314453);
  static const metalShadow = Color(0xFF1A2633);
  static const lidHighlight = Color(0xFF506A7D);
  static const lidShadow = Color(0xFF1A2A38);
  static const edge = Color(0xFF9AB0C0);
  static const silhouette = Color(0xFF02050A);
  static const silhouetteSide = Color(0xFF010309);
  static const caseSide = Color(0xFF101E2A);
  static const interior = Color(0xFF050D17);
  static const lidSilhouette = Color(0xFF03070C);
  static const lidBase = Color(0xFF486274);
  static const fastener = Color(0xFF94A5AE);
  static const rubber = Color(0xFF090E17);
  static const latchInset = Color(0xFF233342);
  static const handle = Color(0xFF080E16);
  static const contactShadow = Color(0xDD000000);
  static const softShadow = Color(0x77000000);
  static const clearShadow = Color(0x00000000);
  static const whiteLight = Color(0xFFFFFFFF);
  static const softLight = Color(0x66FFFFFF);
  static const clearLight = Color(0x00FFFFFF);
  static const smokeCore = Color(0xCC83939E);
  static const smokeEdge = Color(0x77556676);
  static const smokeClear = Color(0x00344556);
  static const skyGround = Color(0xFF071018);
  static const floorNear = Color(0xFF0E1F29);
  static const floorFar = Color(0xFF02060B);
  static const floorLine = Color(0xFF436071);

  static const night = Color(0xFF030916), sky = Color(0xFF122C43);
  static const metal = Color(0xFF364858), metalLight = Color(0xFF708593);
  static const starCount = 72, cloudCount = 12;
  static const horizon = .73, landingX = .5, landingY = .69;
  static const maxCaseWidth = 380.0, caseWidth = .78;
  static const impactLifetime = .8, smokeTravel = 190.0;
  static const tailSamples = 18;
  static const trailPeriodMs = 1600.0, paperRotationMs = 700.0;
  static const impactFlashSeconds = .14, smokeExpandSeconds = 1.1;
  static const shakeDecay = 7.0, shakeFrequencyX = 83.0, shakeFrequencyY = 61.0;
  static const lightLaneSpacing = .085, lightStagger = 20.0;
  static const lightAimStart = .84;
  static const batchMeteorScale = .48;
  // Frontal Blender camera projection, emitted by render_case.py.
  static const caseImageVisibleWidth = .676106;
  static const caseImageCenterX = .5, caseImageGroundY = .736195;
  static const caseLidLeft = .225664, caseLidRight = .774336;
  static const caseLidBack = .456932, caseLidFront = .569654;
  static const worldStartY = .10, worldGroundY = 3.10;
  static const worldFallDistance = worldGroundY - worldStartY;
  static const worldHorizonY = 3.0;
  static const cameraFollowY = .4, cameraLandingEase = .25;
  static const skyParallax = .24, cloudBackParallax = .52;
  static const flightQuietTravel = .84, flightStrikeTravel = .89;
}
