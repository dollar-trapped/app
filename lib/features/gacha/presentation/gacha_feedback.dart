import 'package:flutter/services.dart';

enum GachaEvent {
  starlight,
  fall,
  colorHint,
  reversal,
  stillness,
  impact,
  open,
  card,
  finish,
}

abstract class GachaAudio {
  void play(GachaEvent event, String soundKey);
  void stop();
  void dispose();
}

class NoOpGachaAudio implements GachaAudio {
  const NoOpGachaAudio();
  @override
  void play(GachaEvent event, String soundKey) {}
  @override
  void stop() {}
  @override
  void dispose() {}
}

abstract class GachaHaptics {
  void play(GachaEvent event, int strength);
  void dispose();
}

class FlutterGachaHaptics implements GachaHaptics {
  bool enabled = true;
  @override
  void play(GachaEvent event, int strength) {
    if (!enabled ||
        !const {
          GachaEvent.reversal,
          GachaEvent.impact,
          GachaEvent.open,
          GachaEvent.card,
        }.contains(event)) {
      return;
    }
    final future = switch (strength) {
      2 => HapticFeedback.heavyImpact(),
      1 => HapticFeedback.mediumImpact(),
      _ => HapticFeedback.lightImpact(),
    };
    future.catchError((Object _) {});
  }

  @override
  void dispose() {
    enabled = false;
  }
}
