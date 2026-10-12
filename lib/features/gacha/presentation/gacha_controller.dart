import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'gacha_feedback.dart';
import 'gacha_result.dart';
import 'gacha_timeline.dart';
import 'grade_config.dart';

class GachaController extends ChangeNotifier {
  GachaController({
    required TickerProvider vsync,
    required this.result,
    this.configs = GradeConfig.defaults,
    GachaAudio? audio,
    GachaHaptics? haptics,
  }) : audio = audio ?? const NoOpGachaAudio(),
       haptics = haptics ?? FlutterGachaHaptics() {
    timeline = GachaTimeline(result, configs);
    clock = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: timeline.totalMs),
    )..addListener(_tick);
  }
  final GachaResult result;
  final Map<GachaGrade, GradeConfig> configs;
  final GachaAudio audio;
  final GachaHaptics haptics;
  late final GachaTimeline timeline;
  late final AnimationController clock;
  final _sent = <String>{};
  bool _started = false, _resume = false, _disposed = false, _silent = false;
  double get ms => clock.value * timeline.totalMs;
  bool get complete => clock.value == 1;
  void _feedback(VoidCallback action) {
    try {
      action();
    } catch (_) {
      // Optional device feedback must not hide an already acquired reward.
    }
  }

  void start({bool reduced = false}) {
    if (_started) return;
    _started = true;
    if (reduced) {
      skip();
      return;
    }
    _tick();
    clock.forward();
  }

  void _emit(GachaEvent event, int at, {int? card}) {
    if (ms < at || !_sent.add('${event.name}:${card ?? -1}')) return;
    final grade = card == null
        ? timeline.visibleGrade(at.toDouble())
        : result.rewards[card].grade;
    final config = configs[grade]!;
    if (event == GachaEvent.stillness) _feedback(audio.stop);
    _feedback(() => audio.play(event, '${config.soundKey}.${event.name}'));
    _feedback(() => haptics.play(event, config.haptic));
  }

  void _tick() {
    if (_disposed) return;
    if (!_silent) {
      _emit(GachaEvent.starlight, 0);
      _emit(GachaEvent.fall, timeline.bounds[1]);
      _emit(GachaEvent.colorHint, timeline.bounds[1]);
      if (result.highest == GachaGrade.special) {
        _emit(GachaEvent.reversal, GachaTimeline.reversalMs);
      }
      _emit(GachaEvent.stillness, timeline.bounds[2]);
      _emit(GachaEvent.impact, timeline.impactMs);
      _emit(GachaEvent.open, timeline.openingMs);
      for (var i = 0; i < timeline.cardStarts.length; i++) {
        _emit(GachaEvent.card, timeline.cardStarts[i], card: i);
      }
      _emit(GachaEvent.finish, timeline.totalMs);
    }
    notifyListeners();
  }

  void skip() {
    if (complete || _disposed) return;
    _silent = true;
    _resume = false;
    _feedback(audio.stop);
    clock.value = 1;
  }

  void pause() {
    _resume = _resume || clock.isAnimating;
    clock.stop();
    _feedback(audio.stop);
  }

  void resume() {
    if (_resume && !complete) clock.forward();
    _resume = false;
  }

  @override
  void dispose() {
    _disposed = true;
    clock.dispose();
    _feedback(audio.stop);
    _feedback(audio.dispose);
    _feedback(haptics.dispose);
    super.dispose();
  }
}
