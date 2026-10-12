import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_presentation.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_result.dart';
import 'package:dollar_trapped/features/gacha/presentation/gacha_timeline.dart';
import 'package:dollar_trapped/features/gacha/presentation/grade_config.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets(
    'Blender hybrid gacha real-device frame timings for all 12 scenarios',
    (tester) async {
      for (final quality in GachaQuality.values) {
        for (final grade in GachaGrade.values) {
          for (final count in [1, 10]) {
            final key = '${grade.name}_${count}_${quality.name}';
            const selected = String.fromEnvironment('GACHA_PROFILE_CASES');
            if (selected.isNotEmpty && !selected.split(',').contains(key)) {
              continue;
            }
            final result = GachaResult(
              rewards: [
                for (var i = 0; i < count; i++)
                  GachaReward(
                    id: '$i',
                    grade: i == 0 || i == 6 ? grade : GachaGrade.common,
                    title: '달러의 빛 $i',
                  ),
              ],
            );
            final duration = GachaTimeline(
              result,
              GradeConfig.defaults,
            ).totalMs;
            await binding.watchPerformance(() async {
              await tester.pumpWidget(
                MaterialApp(
                  key: ValueKey(key),
                  home: GachaPresentation(
                    result: result,
                    quality: quality,
                    onFinish: () {},
                  ),
                ),
              );
              final state = tester.state<GachaPresentationState>(
                find.byType(GachaPresentation),
              );
              // Cold activity startup may briefly pause the app. Wait for the
              // actual controller, without advancing or skipping its clock.
              final deadline = DateTime.now().add(
                Duration(milliseconds: duration + 5000),
              );
              while (!state.controller.complete &&
                  DateTime.now().isBefore(deadline)) {
                await tester.pump(const Duration(milliseconds: 100));
              }
              expect(state.controller.complete, isTrue);
              expect(state.film?.ready, isTrue);
              expect(state.film?.failed, isFalse);
              expect(state.resources.lights.length, count);
            }, reportKey: key);
            expect(
              (binding.reportData![key] as Map)['frame_count'],
              greaterThan(30),
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(milliseconds: 100));
            debugPrint(
              'GACHA_SCENARIO $key ${jsonEncode(binding.reportData![key])}',
            );
          }
        }
      }
      debugPrint('GACHA_PROFILE ${jsonEncode(binding.reportData)}');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
