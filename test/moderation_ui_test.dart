import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/core/moderation/moderation_status.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';
import 'package:dollar_trapped/features/chat/screens/usd_room_page.dart';
import 'package:dollar_trapped/features/auth/screens/login_page.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

class _Repo extends MockDollarRepository {
  ModerationStatus moderation = const ModerationStatus();
  @override
  Future<User> getMe() async {
    final u = await super.getMe();
    return User(
      id: u.id,
      email: u.email,
      nickname: u.nickname,
      usdAmount: u.usdAmount,
      averageExchangeRate: u.averageExchangeRate,
      profitRate: u.profitRate,
      profitRateAsOf: u.profitRateAsOf,
      createdAt: u.createdAt,
      moderation: moderation,
    );
  }
}

class _SuspendedRepo extends MockDollarRepository {
  @override
  Future<AuthSession> logIn({
    required String email,
    required String password,
  }) async => throw const ApiException(
    statusCode: 403,
    code: 'ACCOUNT_DISABLED',
    message: '계정 이용이 정지되었습니다.',
    details: [
      ApiErrorDetail(field: 'userMessage', reason: '반복적인 욕설'),
      ApiErrorDetail(field: 'startsAt', reason: '2026-09-27T00:00:00Z'),
      ApiErrorDetail(field: 'expiresAt', reason: '2026-09-30T00:00:00Z'),
    ],
  );
}

void main() {
  testWidgets('chat ban blocks input and reactivation refresh removes it', (
    tester,
  ) async {
    final repo = _Repo()
      ..moderation = ModerationStatus.fromJson({
        'version': 1,
        'chatBanExpiresAt': DateTime.now()
            .add(const Duration(hours: 2))
            .toUtc()
            .toIso8601String(),
        'warnings': [],
      });
    Widget app(bool active) => MaterialApp(
      home: UsdRoomPage(
        repository: repo,
        isActive: active,
        onRateBarTap: () {},
      ),
    );
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(const Key('chat-send')))
          .onPressed,
      isNull,
    );
    repo.moderation = const ModerationStatus();
    await tester.pumpWidget(app(false));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(true));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('warning shows reason without blocking or repeated dialogs', (
    tester,
  ) async {
    final repo = _Repo()
      ..moderation = ModerationStatus.fromJson({
        'version': 2,
        'warnings': [
          {
            'id': 'warning-1',
            'userMessage': '도배를 중단해 주세요.',
            'createdAt': '2026-09-27T00:00:00Z',
          },
        ],
      });
    await tester.pumpWidget(
      MaterialApp(
        home: UsdRoomPage(repository: repo, onRateBarTap: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('도배를 중단해 주세요.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('suspended login shows server reason and supplied dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginPage(repository: _SuspendedRepo())),
    );
    await tester.enterText(find.byType(TextField).at(0), 'me@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, '로그인'));
    await tester.tap(find.widgetWithText(ElevatedButton, '로그인'));
    await tester.pumpAndSettle();
    expect(find.text('계정 이용 정지'), findsOneWidget);
    expect(find.text('반복적인 욕설'), findsOneWidget);
    expect(find.textContaining('2026.09.30'), findsOneWidget);
  });
}
