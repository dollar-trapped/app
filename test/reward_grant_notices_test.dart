import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/auth/reward_event_notifications.dart';
import 'package:dollar_trapped/features/gacha/widgets/reward_event_listener.dart';
import 'package:dollar_trapped/features/gacha/widgets/ticket_reward_dialog.dart';
import 'package:dollar_trapped/core/network/api_client.dart';
import 'package:dollar_trapped/features/rewards/data/reward_grant_notices.dart';
import 'package:dollar_trapped/features/rewards/widgets/reward_grant_notice_listener.dart';

Map<String, dynamic> _notice(String id, {String? key}) => {
  'grantNoticeId': id,
  'name': '테스트 뽑기권 지급',
  'amount': 3,
  'grantedAt': '2026-10-14T02:00:00.000Z',
  'source': 'ADMIN_DIRECT',
  'sourceId': 'grt_$id',
  'eventId': null,
  'presentation': 'GRANT_NOTICE',
  'deduplicationKey': key ?? 'admin-grant:$id',
};
Map<String, dynamic> _page(
  List<Map<String, dynamic>> items, {
  String? cursor,
}) => {
  'items': items,
  'page': {'hasMore': cursor != null, 'nextCursor': cursor},
};

void main() {
  test(
    'reading a notice does not acknowledge; ack removes it only on confirmed success',
    () async {
      final adapter = _Adapter();
      final notices = _service(adapter);
      await notices.load();
      expect(notices.current?.id, 'rgn_1');
      expect(adapter.acks, 0);
      adapter.failAck = true;
      await expectLater(notices.acknowledge(notices.current!), throwsException);
      expect(notices.current?.id, 'rgn_1');
      adapter.failAck = false;
      await notices.acknowledge(notices.current!);
      expect(notices.current, isNull);
      expect(adapter.ackIds, ['rgn_1', 'rgn_1']);
    },
  );

  test(
    'pagination uses the same limit and suppresses repeated real-grant keys',
    () async {
      final adapter = _Adapter()
        ..pages = [
          _page([_notice('rgn_1')], cursor: 'cursor-1'),
          _page([
            _notice('repeat', key: 'admin-grant:rgn_1'),
            _notice('rgn_2'),
          ]),
        ];
      final notices = _service(adapter);
      await notices.load();
      await notices.acknowledge(notices.current!);
      await notices.load();
      expect(notices.current?.id, 'rgn_2');
      expect(adapter.queries, [
        {'limit': 20},
        {'limit': 20, 'cursor': 'cursor-1'},
      ]);
    },
  );

  test(
    'expired cursor restarts the first page without repeating acknowledged grants',
    () async {
      final adapter = _Adapter()..expireCursor = true;
      final notices = _service(adapter);
      await notices.load();
      await notices.acknowledge(notices.current!);
      await notices.load();
      expect(adapter.queries.last, {'limit': 20});
      expect(notices.current?.id, 'rgn_2');
    },
  );

  test('account reset drops old in-flight list results', () async {
    final adapter = _Adapter()..holdList = Completer<void>();
    final notices = _service(adapter);
    final loading = notices.load();
    await Future<void>.delayed(Duration.zero);
    notices.reset();
    adapter.holdList!.complete();
    await loading;
    expect(notices.current, isNull);
  });

  test(
    'HTTP success with the wrong receipt ID never hides a pending notice',
    () async {
      final adapter = _Adapter()..wrongAck = true;
      final notices = _service(adapter);
      await notices.load();
      await expectLater(
        notices.acknowledge(notices.current!),
        throwsFormatException,
      );
      expect(notices.current?.id, 'rgn_1');
    },
  );

  test('account reset invalidates an in-flight acknowledgement', () async {
    final adapter = _Adapter()..holdAck = Completer<void>();
    final notices = _service(adapter);
    await notices.load();
    final result = expectLater(
      notices.acknowledge(notices.current!),
      throwsStateError,
    );
    await Future<void>.delayed(Duration.zero);
    notices.reset();
    adapter.holdAck!.complete();
    await result;
    expect(notices.current, isNull);
  });

  test('unsupported API is nonfatal and retries on refresh', () async {
    final adapter = _Adapter()..listStatus = 404;
    final notices = _service(adapter);
    await notices.load();
    expect(notices.current, isNull);
    adapter.listStatus = 200;
    await notices.load(refresh: true);
    expect(notices.current?.id, 'rgn_1');
  });

  testWidgets('failed confirmation keeps modal open with same-ID retry', (
    tester,
  ) async {
    final adapter = _Adapter()..failAck = true;
    final notices = _service(adapter);
    await tester.runAsync(() => notices.load());
    await tester.pumpWidget(
      MaterialApp(
        home: RewardGrantNoticeListener(
          notices: notices,
          child: const Scaffold(body: Text('홈')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 3장 획득!'), findsOneWidget);
    expect(find.textContaining('2026.10.14 11:00'), findsOneWidget);
    expect(adapter.acks, 0);
    await tester.runAsync(() async {
      await tester.tap(find.text('확인'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    expect(find.text('다시 확인'), findsOneWidget);
    expect(notices.current?.id, 'rgn_1');
    adapter.failAck = false;
    await tester.tap(find.text('다시 확인'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(adapter.ackIds, ['rgn_1', 'rgn_1']);
    expect(notices.current, isNull);
    expect(find.text('뽑기권 3장 획득!'), findsNothing);
  });

  testWidgets('event and administrator rewards are shown one modal at a time', (
    tester,
  ) async {
    final notices = _service(_Adapter());
    final events = RewardEventNotifications()
      ..add(
        const RewardEventReceipt(
          amount: 1,
          balance: 8,
          events: [GrantedRewardEvent(id: 'evt-new', name: '새 이벤트', amount: 1)],
        ),
      );
    await tester.runAsync(() => notices.load());
    await tester.pumpWidget(
      MaterialApp(
        home: RewardGrantNoticeListener(
          notices: notices,
          child: RewardEventListener(
            notifications: events,
            child: const Scaffold(body: Text('홈')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TicketRewardDialog), findsOneWidget);
    expect(find.text('테스트 뽑기권 지급'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TicketRewardDialog), findsOneWidget);
    expect(find.text('뽑기권 1장 획득!'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(TicketRewardDialog), findsNothing);
  });

  testWidgets('account reset dismisses the previous account reward modal', (
    tester,
  ) async {
    final notices = _service(_Adapter());
    await tester.runAsync(() => notices.load());
    await tester.pumpWidget(
      MaterialApp(
        home: RewardGrantNoticeListener(
          notices: notices,
          child: const Scaffold(body: Text('홈')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 3장 획득!'), findsOneWidget);
    notices.reset();
    await tester.pumpAndSettle();
    expect(find.text('뽑기권 3장 획득!'), findsNothing);
  });
}

RewardGrantNotices _service(_Adapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://example.test',
      contentType: Headers.jsonContentType,
    ),
  )..httpClientAdapter = adapter;
  return RewardGrantNotices(ApiClient(_Tokens(), dio: dio));
}

class _Tokens implements TokenStore {
  @override
  Future<TokenPair?> read() async => TokenPair(
    accessToken: 'test-access',
    refreshToken: 'test-refresh',
    accessExpiresAt: DateTime.utc(2030),
    refreshExpiresAt: DateTime.utc(2030),
  );
  @override
  Future<void> clear() async {}
  @override
  Future<void> write(TokenPair value) async {}
}

class _Adapter implements HttpClientAdapter {
  List<Map<String, dynamic>> pages = [
    _page([_notice('rgn_1')]),
  ];
  final queries = <Map<String, dynamic>>[];
  final ackIds = <String>[];
  bool failAck = false, expireCursor = false, wrongAck = false;
  int listStatus = 200;
  Completer<void>? holdList, holdAck;
  int get acks => ackIds.length;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(options.headers['Authorization'], 'Bearer test-access');
    expect(options.data, isNull);
    final bodyBytes =
        await requestStream?.fold<int>(
          0,
          (size, chunk) => size + chunk.length,
        ) ??
        0;
    expect(
      bodyBytes,
      0,
      reason: 'notice GET and ACK must send no body, including JSON {}',
    );
    Object body;
    var status = 200;
    if (options.method == 'GET') {
      expect(options.path, '/users/me/reward-grant-notices');
      queries.add(Map.from(options.queryParameters));
      await holdList?.future;
      status = listStatus;
      if (expireCursor && options.queryParameters['cursor'] != null) {
        body = {
          'error': {'code': 'CURSOR_EXPIRED', 'message': 'expired'},
        };
        status = 410;
        expireCursor = false;
        pages = [
          _page([_notice('rgn_1'), _notice('rgn_2')]),
        ];
      } else if (expireCursor) {
        body = _page([_notice('rgn_1')], cursor: 'expired-cursor');
      } else {
        body = pages.length > 1 ? pages.removeAt(0) : pages.single;
      }
    } else {
      expect(options.method, 'POST');
      expect(options.queryParameters, isEmpty);
      expect(options.uri.query, isEmpty);
      final id = options.path.split('/')[4];
      expect(
        options.path,
        '/users/me/reward-grant-notices/$id/acknowledgement',
      );
      ackIds.add(id);
      await holdAck?.future;
      status = failAck ? 503 : 200;
      body = failAck
          ? {
              'error': {'code': 'TEMPORARY_FAILURE', 'message': 'temporary'},
            }
          : {
              'grantNoticeId': wrongAck ? 'other-id' : id,
              'acknowledged': true,
              'acknowledgedAt': '2026-10-14T02:03:00.000Z',
            };
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
