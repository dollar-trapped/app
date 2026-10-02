import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/auth/screens/auth_page.dart';
import 'package:dollar_trapped/features/auth/screens/sign_up_page.dart';
import 'package:dollar_trapped/features/chat/screens/usd_room_page.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
  for (final bottom in [24.0, 48.0, 80.0]) {
    testWidgets('bottom controls avoid a $bottom px system navigation area', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(top: 24, bottom: bottom);
      tester.view.viewPadding = FakeViewPadding(top: 24, bottom: bottom);
      addTearDown(tester.view.reset);
      final repo = MockDollarRepository();
      for (final entry in <(Widget, Finder)>[
        (const AuthPage(), find.text('비회원으로 둘러보기')),
        (
          SignUpPage(repository: repo),
          find.widgetWithText(ElevatedButton, '다음'),
        ),
        (
          UsdRoomPage(repository: repo, onRateBarTap: () {}),
          find.byKey(const Key('chat-send')),
        ),
      ]) {
        await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: entry.$1));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(entry.$2).bottom,
          lessThanOrEqualTo(800 - bottom),
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'chat composer stays above the keyboard without a second navigation gap',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: UsdRoomPage(
            repository: MockDollarRepository(),
            onRateBarTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final send = tester.getRect(find.byKey(const Key('chat-send')));
      expect(send.bottom, lessThanOrEqualTo(500));
      expect(send.bottom, greaterThan(470));
      expect(tester.takeException(), isNull);
    },
  );
}
