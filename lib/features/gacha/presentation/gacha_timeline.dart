import 'gacha_result.dart';
import 'grade_config.dart';

enum GachaPhase {
  starlight,
  falling,
  stillness,
  impact,
  smoke,
  opening,
  cards,
  afterglow,
  complete,
}

/// All phase boundaries are milliseconds from the first visible frame.
class GachaTimeline {
  GachaTimeline(this.result, this.configs) {
    bounds = switch (result.highest) {
      // Extend only the sky descent (+600ms Common, +1000ms Rare/Special).
      // Preserve the impact, opening and reward-reading intervals afterward.
      GachaGrade.common => const [0, 550, 2350, 2700, 2880, 3250, 3800, 4700],
      GachaGrade.rare => const [0, 550, 3650, 4000, 4180, 4550, 5270, 6370],
      GachaGrade.special => const [0, 550, 3650, 4070, 4260, 4790, 5750, 7250],
    };
    cardStarts = [bounds[6]];
    var end = bounds[7];
    for (var i = 1; i < result.rewards.length; i++) {
      cardStarts.add(end);
      end += configs[result.rewards[i].grade]!.cardMs;
    }
    cardsEnd = end;
  }
  final GachaResult result;
  final Map<GachaGrade, GradeConfig> configs;
  late final List<int> bounds, cardStarts;
  late final int cardsEnd;
  static const reversalMs = 2850, reversalFlashMs = 70, afterglowMs = 450;
  static const strikeMs = 160, strikeSpacingMs = 14, strikeGlowMs = 260;
  static const starFlashMs = 180, blackoutEndMs = 300;
  static const hitStopMs = [60, 80, 100];
  int get totalMs => cardsEnd + afterglowMs;
  int get impactMs => bounds[3];
  int get openingMs => bounds[5];
  GachaPhase phaseAt(double ms) {
    if (ms >= totalMs) return GachaPhase.complete;
    if (ms >= cardsEnd) return GachaPhase.afterglow;
    for (var i = 6; i >= 0; i--) {
      if (ms >= bounds[i]) return GachaPhase.values[i];
    }
    return GachaPhase.starlight;
  }

  double progress(double ms, int start, int end) =>
      ((ms - start) / (end - start)).clamp(0.0, 1.0);
  int cardIndex(double ms) {
    for (var i = cardStarts.length - 1; i >= 0; i--) {
      if (ms >= cardStarts[i]) return i;
    }
    return -1;
  }

  double cardProgress(double ms, int index) => progress(
    ms,
    cardStarts[index],
    index + 1 < cardStarts.length ? cardStarts[index + 1] : cardsEnd,
  );
  GachaGrade visibleGrade(double ms) =>
      result.highest == GachaGrade.special && ms < reversalMs
      ? GachaGrade.rare
      : result.highest;
}
