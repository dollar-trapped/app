import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/attendance/preview/attendance_preview_page.dart';
import 'package:dollar_trapped/features/gacha/widgets/ticket_reward_dialog.dart';

void main() {
  testWidgets('entry stamps first attendance and shows a one-ticket reward', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AttendancePreviewPage()));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('출시 기념 출석 이벤트'), findsOneWidget);
    expect(find.byKey(const Key('attendance-stamp-1')), findsOneWidget);
    expect(find.text('누적 1 / 7회'), findsOneWidget);
    await tester.tap(find.text('보상 확인'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 1장 획득!'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.byType(TicketRewardDialog), findsNothing);
    expect(find.text('오늘 출석 완료'), findsOneWidget);
  });

  testWidgets('seventh attendance awards eight and completes all twenty', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AttendancePreviewPage(initialRound: 7)),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attendance-stamp-7')), findsOneWidget);
    expect(find.text('20장 모두 받았어요!'), findsOneWidget);
    await tester.tap(find.text('보상 확인'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 8장 획득!'), findsOneWidget);
  });

  testWidgets('already attended entry retains progress and has no new reward', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AttendancePreviewPage(initialRound: 2, alreadyAttended: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('누적 2 / 7회'), findsOneWidget);
    expect(find.text('보상 확인'), findsNothing);
    expect(find.text('오늘 출석 완료'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(find.text('디자인 미리보기 · 실제 뽑기권은 지급되지 않습니다.'), findsOneWidget);
  });

  for (final round in [1, 7]) {
    testWidgets(
      'attendance and reward fit a narrow screen with large text: $round',
      (tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: child!,
            ),
            home: AttendancePreviewPage(initialRound: round),
          ),
        );
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('보상 확인'));
        await tester.tap(find.text('보상 확인'));
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
