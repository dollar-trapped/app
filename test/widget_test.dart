// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dollar_trapped/app.dart';
import 'package:dollar_trapped/features/home/presentation/pages/my_page.dart';
import 'package:dollar_trapped/features/home/presentation/pages/usd_room_page.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
  testWidgets('opens the USD room when the session is restored', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const DollarTrappedApp(initiallyAuthenticated: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('USD방'), findsOneWidget);
    expect(find.text('최근 1개월'), findsNothing);
  });

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
    expect(find.text('가입하기'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'dollar@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.enterText(find.byType(TextField).at(2), '달러물림');
    await tester.ensureVisible(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pump();
    await tester.ensureVisible(find.byType(Checkbox).at(1));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    await tester.ensureVisible(find.text('가입하기'));
    await tester.tap(find.text('가입하기'));
    await tester.pumpAndSettle();

    expect(find.text('1,346.09원'), findsOneWidget);
    expect(find.text('최근 1개월'), findsOneWidget);

    await tester.fling(find.text('1,346.09원'), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('USD방'), findsOneWidget);
    expect(find.text('● 채팅 오프라인'), findsOneWidget);

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

  testWidgets('removes a blocked author message immediately', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UsdRoomPage(
          repository: MockDollarRepository(),
          onRateBarTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('환율 보고 계신가요?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();

    expect(find.text('환율 보고 계신가요?'), findsNothing);
    expect(find.text('오늘도 달러방 출석합니다.'), findsOneWidget);
  });

  testWidgets('confirms a report for another users message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UsdRoomPage(
          repository: MockDollarRepository(),
          onRateBarTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('환율 보고 계신가요?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('신고'));
    await tester.pumpAndSettle();

    expect(find.text('신고되었습니다.'), findsOneWidget);
  });

  testWidgets(
    'does not show moderation actions for the current users message',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UsdRoomPage(
            repository: MockDollarRepository(),
            onRateBarTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.text('오늘도 달러방 출석합니다.'));
      await tester.pumpAndSettle();

      expect(find.text('신고'), findsNothing);
      expect(find.text('차단'), findsNothing);
    },
  );

  testWidgets('lists and unblocks users from the profile page', (
    WidgetTester tester,
  ) async {
    final repository = MockDollarRepository();
    await repository.blockUser('user-2');
    await tester.pumpWidget(
      MaterialApp(
        home: MyPage(repository: repository, onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('차단 관리'));
    await tester.tap(find.text('차단 관리'));
    await tester.pumpAndSettle();
    expect(find.text('차단 사용자'), findsOneWidget);

    await tester.tap(find.text('차단 해제'));
    await tester.pumpAndSettle();
    expect(find.text('차단한 사용자가 없습니다.'), findsOneWidget);
  });
}
