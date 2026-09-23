import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/chat/screens/usd_room_page.dart';
import 'package:dollar_trapped/features/chat/widgets/message_actions_sheet.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
  Future<void> open(WidgetTester tester, {MockDollarRepository? repo}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UsdRoomPage(
          repository: repo ?? MockDollarRepository(),
          onRateBarTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.text('환율 보고 계신가요?'));
    await tester.pumpAndSettle();
  }

  testWidgets('hide only removes selected message and can be undone', (
    tester,
  ) async {
    final repo = _Repo();
    await open(tester, repo: repo);
    expect(find.text('숨기기'), findsOneWidget);
    expect(find.text('차단'), findsOneWidget);
    expect(find.text('신고하기'), findsOneWidget);
    await tester.tap(find.text('숨기기'));
    await tester.pumpAndSettle();
    expect(find.text('환율 보고 계신가요?'), findsNothing);
    expect(find.text('숨겨진 메시지'), findsOneWidget);
    expect(find.text('오늘도 달러방 출석합니다.'), findsOneWidget);
    expect(repo.blockCalls, 0);
    expect(repo.reportCalls, 0);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(find.text('환율 보고 계신가요?'), findsOneWidget);
    expect(find.text('숨겨진 메시지'), findsNothing);
  });

  testWidgets('returning to chat refreshes an unblocked author', (
    tester,
  ) async {
    final repo = MockDollarRepository();
    Widget page(bool active) => MaterialApp(
      home: UsdRoomPage(
        repository: repo,
        onRateBarTap: () {},
        isActive: active,
      ),
    );
    await tester.pumpWidget(page(true));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('환율 보고 계신가요?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();
    expect(find.text('환율 보고 계신가요?'), findsNothing);
    await tester.pumpWidget(page(false));
    await tester.pumpAndSettle();
    await repo.unblockUser('user-2');
    await tester.pumpWidget(page(true));
    await tester.pumpAndSettle();
    expect(find.text('환율 보고 계신가요?'), findsOneWidget);
  });

  testWidgets('cancel leaves the message visible', (tester) async {
    await open(tester);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(MessageActionsSheet), findsNothing);
    expect(find.text('환율 보고 계신가요?'), findsOneWidget);
  });

  testWidgets('failed block restores the author messages', (tester) async {
    await open(tester, repo: _Repo()..failBlock = true);
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();
    expect(find.text('환율 보고 계신가요?'), findsOneWidget);
    expect(find.text('차단하지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
  });

  testWidgets('sheet scrolls on narrow screens with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: const Scaffold(body: MessageActionsSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('취소'));
    expect(tester.takeException(), isNull);
  });
}

class _Repo extends MockDollarRepository {
  int blockCalls = 0, reportCalls = 0;
  bool failBlock = false;
  @override
  Future<void> blockUser(String userId) async {
    blockCalls++;
    if (failBlock) throw StateError('offline');
    return super.blockUser(userId);
  }

  @override
  reportMessage(
    String messageId, {
    required String reason,
    String? description,
  }) {
    reportCalls++;
    return super.reportMessage(
      messageId,
      reason: reason,
      description: description,
    );
  }
}
