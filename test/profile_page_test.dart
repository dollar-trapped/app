import 'package:dollar_trapped/features/profile/screens/my_page.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('position editor saves without changing nickname', (
    tester,
  ) async {
    final repository = MockDollarRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: MyPage(repository: repository, onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('달러칩 0'), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const Key('my-dollar-chip-balance'))).dx,
      lessThan(tester.getCenter(find.text('설정')).dx),
    );
    await tester.ensureVisible(find.text('내 달러 포지션'));
    await tester.tap(find.text('내 달러 포지션'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '3000');
    await tester.tap(find.byTooltip('소수점 입력').first);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      '3000.',
    );
    await tester.enterText(find.byType(TextField).at(0), '3,000.25');
    await tester.enterText(find.byType(TextField).at(1), '1,300.50');
    await tester.ensureVisible(find.text('변경사항 저장'));
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    final user = await repository.getMe();
    expect(user.usdAmount, '3000.25');
    expect(user.averageExchangeRate, '1300.50');
    expect(user.nickname, '초록달러');
    expect(find.text('초록달러'), findsOneWidget);
    await tester.ensureVisible(find.text('내 달러 포지션'));
    await tester.tap(find.text('내 달러 포지션'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
      '3000.25',
    );
    expect(find.textContaining(r'$3000.25'), findsOneWidget);
  });

  testWidgets('narrow enlarged-text profile and settings remain scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: MyPage(repository: MockDollarRepository(), onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('내 달러 포지션'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    expect(find.text('dollar@example.com'), findsOneWidget);
    await tester.ensureVisible(find.text('회원 탈퇴'));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('로그아웃'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings logout returns to authentication', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyPage(repository: MockDollarRepository(), onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();
    expect(find.text('로그인'), findsOneWidget);
  });
}
