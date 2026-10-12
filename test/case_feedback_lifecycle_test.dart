import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_feedback.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_presentation.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_result.dart';

class RecordingAudio implements GachaAudio {
  final events = <GachaEvent>[];
  int stops = 0, disposals = 0;
  @override
  void play(GachaEvent event, String key) {
    events.add(event);
  }

  @override
  void stop() {
    stops++;
  }

  @override
  void dispose() {
    disposals++;
  }
}

class BrokenAudio extends RecordingAudio {
  @override
  void play(GachaEvent event, String key) => throw StateError('unavailable');
  @override
  void stop() => throw StateError('unavailable');
  @override
  void dispose() => throw StateError('unavailable');
}

void main() {
  Widget scene(RecordingAudio audio, {bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: GachaPresentation(
        useBlenderFilm: false,
        audio: audio,
        result: GachaResult(
          rewards: const [
            GachaReward(id: 'x', grade: GachaGrade.special, title: 'reward'),
          ],
        ),
      ),
    ),
  );
  testWidgets('unavailable feedback cannot block skip or resource disposal', (
    tester,
  ) async {
    await tester.pumpWidget(scene(BrokenAudio()));
    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    expect(find.text('확인'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'events cross boundaries once and pause preserves exact progress',
    (tester) async {
      final audio = RecordingAudio();
      await tester.pumpWidget(scene(audio));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2500));
      final state = tester.state<GachaPresentationState>(
        find.byType(GachaPresentation),
      );
      final ms = state.controller.ms;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 10));
      expect(state.controller.ms, ms);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(audio.events, GachaEvent.values);
      expect(audio.stops, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      expect(audio.disposals, 1);
    },
  );
  testWidgets('skip cancels queued feedback and disposes while paused', (
    tester,
  ) async {
    final audio = RecordingAudio();
    await tester.pumpWidget(scene(audio));
    await tester.tap(find.text('건너뛰기'));
    await tester.pump();
    final before = List.of(audio.events);
    await tester.pump(const Duration(seconds: 30));
    expect(audio.events, before);
    expect(audio.events, [GachaEvent.starlight]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpWidget(const SizedBox());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(audio.disposals, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion has no flashes feedback or ticking', (
    tester,
  ) async {
    final audio = RecordingAudio();
    await tester.pumpWidget(scene(audio, reduced: true));
    expect(audio.events, isEmpty);
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('확인'), findsOneWidget);
  });
}
