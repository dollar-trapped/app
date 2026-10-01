import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/widgets/ticket_reward_dialog.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('reward can close immediately, reduced motion=$reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showTicketReward(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('광고 보상 도착!'), findsOneWidget);
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byType(TweenAnimationBuilder<double>),
            )
            .duration,
        reduced ? Duration.zero : const Duration(milliseconds: 1400),
      );
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.byType(TicketRewardDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
