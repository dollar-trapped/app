// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
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

    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('달러방에서 만나요.'), findsOneWidget);
    expect(find.text('가입하고 이메일 인증'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'dollar@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.enterText(find.byType(TextField).at(2), '달러물림');
    await tester.ensureVisible(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pump();
    await tester.ensureVisible(find.byType(Checkbox).at(1));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    await tester.ensureVisible(find.text('가입하고 이메일 인증'));
    await tester.tap(find.text('가입하고 이메일 인증'));
    await tester.pumpAndSettle();

    expect(find.text('메일함을 확인해주세요.'), findsOneWidget);
    expect(find.text('dollar@example.com'), findsOneWidget);
  });
}
