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

    await tester.tap(find.text('인증 완료했어요'));
    await tester.pumpAndSettle();

    expect(find.text('1,346.09원'), findsOneWidget);
    expect(find.text('최근 1개월'), findsOneWidget);

    await tester.fling(find.text('1,346.09원'), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('USD방'), findsOneWidget);
    expect(find.text('● 실시간 채팅'), findsOneWidget);

    await tester.fling(find.text('USD방'), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('USD/KRW'), findsOneWidget);

    await tester.fling(find.text('1,346.09원'), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.text('내 달러 포지션 · 선택'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '파란달러');
    await tester.enterText(find.byType(TextField).at(1), '3,000');
    await tester.pump();

    expect(find.text(r'파란달러  $3,000 · +5.2%'), findsOneWidget);
  });
}
