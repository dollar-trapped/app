import 'dart:math' as math;
import 'package:flutter/animation.dart';
import 'gacha_result.dart';
import 'gacha_timeline.dart';
import 'grade_config.dart';

/// One persistent light per confirmed reward; quality never changes this count.
class RewardLight {
  const RewardLight(this.index, this.count, this.reward);
  final int index, count;
  final GachaReward reward;
  double get lane => index - (count - 1) / 2;
  GachaGrade gradeAt(double ms) =>
      reward.grade == GachaGrade.special && ms < GachaTimeline.reversalMs
      ? GachaGrade.rare
      : reward.grade;

  bool isReversed(double ms) =>
      reward.grade == GachaGrade.special && ms >= GachaTimeline.reversalMs;

  int get strikeDelayMs => index * GachaTimeline.strikeSpacingMs;

  /// Distinct points on the original Blender lid, in case-local coordinates.
  /// Adjacent lights alternate front/back rows without crossing into one point.
  Offset target(Size size) {
    final width = math.min(
      size.width * GachaStyle.caseWidth,
      GachaStyle.maxCaseWidth,
    );
    final u = count == 1 ? .5 : (index ~/ 2 + .5) / 5;
    final v = count == 1 ? .5 : (index.isEven ? 1.0 : 0.0);
    return Offset(
      (GachaStyle.caseLidLeft +
              (GachaStyle.caseLidRight - GachaStyle.caseLidLeft) * u -
              GachaStyle.caseImageCenterX) *
          width /
          GachaStyle.caseImageVisibleWidth,
      (GachaStyle.caseLidBack +
              (GachaStyle.caseLidFront - GachaStyle.caseLidBack) * v -
              GachaStyle.caseImageGroundY) *
          width /
          GachaStyle.caseImageVisibleWidth,
    );
  }

  Offset offset(Size size, double travel) {
    final aim = Curves.easeInOutCubic.transform(
      ((travel - GachaStyle.lightAimStart) / (1 - GachaStyle.lightAimStart))
          .clamp(0, 1),
    );
    final spread = .35 + .65 * math.sin(travel * math.pi);
    final sky = Offset(
      lane * size.width * GachaStyle.lightLaneSpacing * spread,
      -lane.abs() * GachaStyle.lightStagger * spread,
    );
    return Offset.lerp(sky, target(size), aim)!;
  }
}
