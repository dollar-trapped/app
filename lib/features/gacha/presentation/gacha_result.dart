import '../data/gacha_models.dart';

enum GachaGrade {
  common,
  rare,
  special;

  static GachaGrade fromServer(String value) => switch (value.toUpperCase()) {
    'RARE' => rare,
    'SPECIAL' => special,
    _ => common,
  };
}

class GachaReward {
  const GachaReward({
    required this.id,
    required this.grade,
    required this.title,
    this.duplicate = false,
    this.chips = 0,
  });
  final String id, title;
  final GachaGrade grade;
  final bool duplicate;
  final int chips;
}

/// A presentation snapshot. No random selection, inventory, or network access.
class GachaResult {
  GachaResult({required List<GachaReward> rewards, this.visualSeed = 42})
    : rewards = List.unmodifiable(rewards) {
    if (rewards.length != 1 && rewards.length != 10) {
      throw ArgumentError('A confirmed draw must contain 1 or 10 rewards');
    }
  }
  factory GachaResult.fromDraws(List<CosmeticDraw> draws) => GachaResult(
    rewards: draws
        .map(
          (draw) => GachaReward(
            id: draw.item.id,
            grade: GachaGrade.fromServer(draw.item.rarity),
            title: draw.item.name,
            duplicate: draw.duplicate,
            chips: draw.chipsGranted,
          ),
        )
        .toList(),
  );
  final List<GachaReward> rewards;
  final int visualSeed;
  GachaGrade get highest => rewards.fold(
    GachaGrade.common,
    (grade, reward) => reward.grade.index > grade.index ? reward.grade : grade,
  );
}
