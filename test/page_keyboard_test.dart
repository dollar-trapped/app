import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';
import 'package:dollar_trapped/features/chat/widgets/rate_bar.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
  for (final swipe in [true, false]) {
    testWidgets(
      'leaving chat by ${swipe ? "swipe" : "rate bar"} dismisses keyboard',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: UsdKrwPage(
              repository: MockDollarRepository(),
              initialPage: 2,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '작성 중인 메시지');
        expect(tester.testTextInput.isVisible, isTrue);
        final input = tester.widget<EditableText>(find.byType(EditableText));
        expect(input.focusNode.hasFocus, isTrue);
        if (swipe) {
          await tester.drag(find.byType(PageView), const Offset(650, 0));
        } else {
          await tester.tap(find.byType(RateBar));
        }
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        expect(input.focusNode.hasFocus, isFalse);
        await tester.drag(find.byType(PageView), const Offset(-650, 0));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);
        expect(find.text('작성 중인 메시지'), findsOneWidget);
      },
    );
  }
}
