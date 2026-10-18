import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_client.dart';
import 'package:dollar_trapped/features/attendance/data/launch_attendance.dart';
import 'package:dollar_trapped/features/attendance/widgets/launch_attendance_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:dollar_trapped/core/auth/reward_event_notifications.dart';
import 'package:dollar_trapped/features/gacha/widgets/reward_event_listener.dart';

Map<String, dynamic> status({
  bool canClaim = true,
  String phase = 'ACTIVE',
  int days = 0,
  bool today = false,
  String? outcome,
  int granted = 0,
}) => {
  'eventId': 'launch',
  'name': '출시 기념 출석 이벤트',
  'enabled': true,
  'phase': phase,
  'startsAt': '2026-10-01T00:00:00.000Z',
  'endsAt': '2026-10-31T00:00:00.000Z',
  'timeZone': 'Asia/Seoul',
  'serverDate': '2026-10-16',
  'attendedDays': days,
  'totalGrantedAmount': days == 0 ? 0 : 1,
  'claimedToday': today,
  'canClaim': canClaim,
  'nextClaimAt': null,
  'drawEntitlementBalance': 11,
  'outcome': outcome,
  'grantedAmount': granted,
  'rewards': [
    for (var i = 0; i < 7; i++)
      {
        'day': i + 1,
        'amount': [1, 1, 2, 2, 3, 3, 8][i],
        'claimed': i < days,
      },
  ],
};

void main() {
  testWidgets(
    'home checks attendance only after required consent is resolved',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final adapter = _Adapter();
      final attendance = _service(adapter);
      final repository = _ConsentRepository();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: attendance,
          child: MaterialApp(
            home: UsdKrwPage(repository: repository, checkConsent: true),
          ),
        ),
      );
      await tester.pump();
      expect(adapter.methods, isEmpty);
      await tester.runAsync(() async {
        repository.consent.complete({
          'terms': {'reagreementRequired': false},
          'privacy': {'reagreementRequired': false},
        });
      });
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pumpAndSettle();
      expect(adapter.methods, ['GET', 'POST']);
      expect(find.byKey(const Key('attendance-stamp-1')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets('attendance waits for an existing event reward dialog', (
    tester,
  ) async {
    final adapter = _Adapter();
    final attendance = _service(adapter);
    final events = RewardEventNotifications()
      ..add(
        const RewardEventReceipt(
          amount: 3,
          balance: 10,
          events: [GrantedRewardEvent(id: 'event', name: '가입 선물', amount: 3)],
        ),
      );
    await tester.pumpWidget(
      MaterialApp(
        home: LaunchAttendanceListener(
          attendance: attendance,
          child: RewardEventListener(
            notifications: events,
            child: const Scaffold(body: Text('홈')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 3장 획득!'), findsOneWidget);
    expect(find.byKey(const Key('attendance-stamp-1')), findsNothing);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attendance-stamp-1')), findsOneWidget);
    expect(find.text('뽑기권 3장 획득!'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  test(
    'eligible attendance sends bodyless authenticated claim and uses server balance',
    () async {
      final adapter = _Adapter();
      final attendance = _service(adapter);
      await attendance.check();
      expect(adapter.methods, ['GET', 'POST']);
      expect(attendance.pending?.attendedDays, 1);
      expect(attendance.pending?.grantedAmount, 1);
      expect(attendance.pending?.balance, 11);
    },
  );
  test(
    'canClaim permits existing participants after recruitment ends',
    () async {
      final adapter = _Adapter()..info = status(phase: 'ENDED');
      final attendance = _service(adapter);
      await attendance.check();
      expect(attendance.pending?.grantedAmount, 1);
      expect(adapter.methods, ['GET', 'POST']);
    },
  );
  test('inactive event never claims or displays a reward', () async {
    final adapter = _Adapter()
      ..info = {...status(canClaim: false), 'enabled': false};
    final attendance = _service(adapter);
    await attendance.check();
    expect(adapter.methods, ['GET']);
    expect(attendance.pending, isNull);
  });
  test(
    'already claimed today stays quiet on refresh and a fresh app session',
    () async {
      final adapter = _Adapter()
        ..info = status(canClaim: false, days: 1, today: true);
      final attendance = _service(adapter);
      await attendance.check();
      expect(attendance.pending, isNull);
      await attendance.check();
      final freshSession = _service(adapter);
      await freshSession.check();
      expect(adapter.methods, ['GET', 'GET', 'GET']);
      expect(attendance.pending, isNull);
      expect(freshSession.pending, isNull);
    },
  );
  test(
    'already claimed POST response never replays a reward after a concurrent claim',
    () async {
      final adapter = _Adapter()
        ..claim = status(
          canClaim: false,
          days: 1,
          today: true,
          outcome: 'ALREADY_CLAIMED',
        );
      final attendance = _service(adapter);
      await attendance.check();
      expect(adapter.methods, ['GET', 'POST']);
      expect(attendance.pending, isNull);
    },
  );
  test('claim failure stays nonfatal and retries on next check', () async {
    final adapter = _Adapter()..failClaim = true;
    final attendance = _service(adapter);
    await attendance.check();
    expect(attendance.pending, isNull);
    adapter.failClaim = false;
    await attendance.check();
    expect(attendance.pending?.grantedAmount, 1);
  });
  testWidgets(
    'app resume refreshes an already claimed day without reopening a dialog',
    (tester) async {
      final adapter = _Adapter()
        ..info = status(canClaim: false, days: 1, today: true);
      final attendance = _service(adapter);
      await tester.pumpWidget(
        MaterialApp(
          home: LaunchAttendanceListener(
            attendance: attendance,
            child: const Scaffold(body: Text('홈')),
          ),
        ),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(adapter.methods, ['GET']);
      expect(find.byType(Dialog), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );
      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(adapter.methods, ['GET', 'GET']);
      expect(find.byType(Dialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  test(
    'concurrent checks coalesce and reset discards old session responses',
    () async {
      final adapter = _Adapter()..hold = Completer<void>();
      final attendance = _service(adapter);
      final first = attendance.check();
      await Future<void>.delayed(Duration.zero);
      await attendance.check();
      attendance.reset();
      adapter.hold!.complete();
      await first;
      expect(adapter.methods, ['GET']);
      expect(attendance.pending, isNull);
    },
  );
  test('malformed grant never produces reward presentation', () async {
    final adapter = _Adapter()
      ..claim = status(days: 8, today: true, outcome: 'GRANTED', granted: 1);
    final attendance = _service(adapter);
    await attendance.check();
    expect(attendance.pending, isNull);
  });
  testWidgets(
    'confirmed server grant shows stamps, reward, and balance; reset dismisses',
    (tester) async {
      final attendance = _service(_Adapter());
      await tester.runAsync(() => attendance.check());
      await tester.pumpWidget(
        MaterialApp(
          home: LaunchAttendanceListener(
            attendance: attendance,
            child: const Scaffold(body: Text('홈')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attendance-stamp-1')), findsOneWidget);
      await tester.tap(find.text('보상 확인'));
      await tester.pumpAndSettle();
      expect(find.text('뽑기권 1장 획득!'), findsOneWidget);
      expect(find.textContaining('현재 보유 뽑기권 11장'), findsOneWidget);
      attendance.reset();
      await tester.pumpAndSettle();
      expect(find.text('뽑기권 1장 획득!'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _ConsentRepository extends MockDollarRepository {
  final consent = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> getTermsAgreements() => consent.future;
}

LaunchAttendance _service(_Adapter adapter) => LaunchAttendance(
  ApiClient(
    _Tokens(),
    dio: Dio(
      BaseOptions(
        baseUrl: 'https://example.test',
        contentType: Headers.jsonContentType,
      ),
    )..httpClientAdapter = adapter,
  ),
);

class _Tokens implements TokenStore {
  @override
  Future<TokenPair?> read() async => TokenPair(
    accessToken: 'access',
    refreshToken: 'refresh',
    accessExpiresAt: DateTime.utc(2030),
    refreshExpiresAt: DateTime.utc(2030),
  );
  @override
  Future<void> clear() async {}
  @override
  Future<void> write(TokenPair tokens) async {}
}

class _Adapter implements HttpClientAdapter {
  Map<String, dynamic> info = status();
  Map<String, dynamic> claim = status(
    canClaim: false,
    days: 1,
    today: true,
    outcome: 'GRANTED',
    granted: 1,
  );
  bool failClaim = false;
  Completer<void>? hold;
  final methods = <String>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.headers['Authorization'], 'Bearer access');
    expect(options.data, isNull);
    expect(options.queryParameters, isEmpty);
    expect(
      await requestStream?.fold<int>(0, (n, bytes) => n + bytes.length) ?? 0,
      0,
    );
    methods.add(options.method);
    final isClaim = options.method == 'POST';
    expect(
      options.path,
      isClaim
          ? '/users/me/launch-attendance/claims'
          : '/users/me/launch-attendance',
    );
    if (!isClaim) await hold?.future;
    return ResponseBody.fromString(
      jsonEncode(isClaim ? claim : info),
      isClaim && failClaim ? 503 : 200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
