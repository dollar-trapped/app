// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:dollar_trapped/app.dart';

void main() {
  testWidgets('shows the authentication entry actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DollarTrappedApp());

    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('회원가입'), findsOneWidget);
    expect(find.text('비회원으로 둘러보기'), findsOneWidget);
  });
}
