import 'dart:async';
import 'dart:convert';

import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_config.dart';
import 'package:dollar_trapped/core/realtime/dollar_socket.dart';
import 'package:dollar_trapped/features/auth/presentation/pages/auth_page.dart';
import 'package:dollar_trapped/features/home/presentation/pages/my_page.dart';
import 'package:dollar_trapped/features/home/presentation/pages/usd_room_page.dart';
import 'package:dollar_trapped/features/shared/data/dollar_repository.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('builds the USD room WebSocket URL', () {
    dotenv.loadFromString(envString: 'API_BASE_URL=https://api.example.test');

    expect(
      ApiConfig.webSocketUrl,
      'wss://api.example.test/api/v1/ws?roomId=usd',
    );
  });

  test(
    'logs CONNECTED, AUTH transmission, and AUTH_OK without tokens',
    () async {
      final connection = _FakeConnection();
      final logs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) logs.add(message);
      };
      final socket = DollarSocket(
        url: 'wss://example.test/api/v1/ws?roomId=usd',
        tokenStore: _MemoryTokenStore(_tokens()),
        connector: (_) async => connection,
      );

      try {
        await socket.connect();
        connection.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 60});
        await _flush();
        connection.add({'type': 'AUTH_OK'});
        await _flush();

        expect(
          logs,
          containsAllInOrder([
            '[DollarSocket] CONNECTED',
            '[DollarSocket] AUTH sent',
            '[DollarSocket] AUTH_OK',
          ]),
        );
        expect(logs.join(' '), isNot(contains('access-token')));
      } finally {
        debugPrint = previousDebugPrint;
        await socket.dispose();
      }
    },
  );

  test(
    'follows CONNECTED, AUTH_OK, MESSAGE_ACK, retry, and message deduplication',
    () async {
      final connection = _FakeConnection();
      final socket = DollarSocket(
        url: 'wss://example.test/api/v1/ws',
        tokenStore: _MemoryTokenStore(_tokens()),
        connector: (_) async => connection,
        ackTimeout: const Duration(milliseconds: 10),
      );
      final received = <RealtimeMessage>[];
      final subscription = socket.messages.listen(received.add);

      await socket.connect();
      expect(connection.sent, isEmpty, reason: 'client must not send CONNECT');

      connection.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 60});
      await _flush();
      final auth = _frame(connection.sent.single);
      expect(auth['type'], 'AUTH');
      expect(auth['accessToken'], 'access-token');
      expect(auth['requestId'], _uuidV4);
      expect(auth.containsKey('data'), isFalse);

      connection.add({'type': 'AUTH_OK'});
      await _flush();
      expect(socket.state, DollarSocketState.authenticated);

      connection.add({
        'type': 'MESSAGE',
        'message': {'id': 'server-1', 'content': '첫 메시지'},
      });
      connection.add({
        'type': 'MESSAGE',
        'message': {'id': 'server-1', 'content': '중복 메시지'},
      });
      await _flush();
      expect(received.map((message) => message.content), ['첫 메시지']);

      final clientId = await socket.sendMessage('보낼 메시지');
      final sent = _frame(connection.sent.last);
      expect(sent['type'], 'SEND_MESSAGE');
      expect(sent['clientMessageId'], _uuidV4);
      expect(sent['clientMessageId'], clientId);
      expect(sent['requestId'], _uuidV4);
      expect(sent['content'], '보낼 메시지');

      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(
        _types(connection.sent).where((type) => type == 'SEND_MESSAGE'),
        hasLength(2),
      );
      final retriedClientMessageIds = connection.sent
          .map(_frame)
          .where((frame) => frame['type'] == 'SEND_MESSAGE')
          .map((frame) => frame['clientMessageId']);
      expect(retriedClientMessageIds, everyElement(clientId));

      connection.add({'type': 'MESSAGE_ACK', 'clientMessageId': clientId});
      await _flush();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        _types(connection.sent).where((type) => type == 'SEND_MESSAGE'),
        hasLength(2),
      );

      await subscription.cancel();
      await socket.dispose();
    },
  );

  test(
    'handles ERROR payloads and refreshes for TOKEN_EXPIRED error code',
    () async {
      final connection = _FakeConnection();
      final refreshed = _tokens(access: 'refreshed-access');
      final deleted = <String>[];
      final errors = <SocketError>[];
      final socket = DollarSocket(
        url: 'wss://example.test/api/v1/ws',
        tokenStore: _MemoryTokenStore(_tokens()),
        connector: (_) async => connection,
        tokenRefresher: () async => refreshed,
      );
      final deletionSubscription = socket.deletedMessageIds.listen(deleted.add);
      final errorSubscription = socket.errors.listen(errors.add);

      await socket.connect();
      connection.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 60});
      await _flush();
      connection.add({'type': 'AUTH_OK'});
      connection.add({'type': 'PING'});
      connection.add({'type': 'PONG'});
      connection.add({'type': 'MESSAGE_DELETED', 'messageId': 'server-1'});
      connection.add({
        'type': 'ERROR',
        'error': {
          'code': 'RATE_LIMITED',
          'message': '천천히 보내세요',
          'scope': 'SEND_MESSAGE',
          'retryAfterSeconds': 2,
        },
      });
      connection.add({
        'type': 'ERROR',
        'error': {'code': 'BAD_REQUEST', 'message': '오류'},
      });
      connection.add({
        'type': 'ERROR',
        'error': {'code': 'TOKEN_EXPIRED', 'message': '토큰 만료'},
      });
      await _flush();

      expect(_types(connection.sent), contains('PONG'));
      expect(deleted, ['server-1']);
      expect(errors.map((error) => error.code), [
        'RATE_LIMITED',
        'BAD_REQUEST',
      ]);
      expect(errors.first.scope, 'SEND_MESSAGE');
      expect(errors.first.retryAfter, const Duration(seconds: 2));
      expect(_frame(connection.sent.last)['type'], 'AUTH');
      expect(_frame(connection.sent.last)['accessToken'], 'refreshed-access');

      await deletionSubscription.cancel();
      await errorSubscription.cancel();
      await socket.dispose();
    },
  );

  test('rejects message sending before AUTH_OK', () async {
    final connection = _FakeConnection();
    final socket = DollarSocket(
      url: 'wss://example.test/api/v1/ws',
      tokenStore: _MemoryTokenStore(_tokens()),
      connector: (_) async => connection,
    );
    await socket.connect();
    await expectLater(socket.sendMessage('불가'), throwsStateError);
    await socket.dispose();
  });

  test(
    'handles WebSocket handshake failures without uncaught errors',
    () async {
      final socket = DollarSocket(
        url: 'ws://127.0.0.1:1',
        tokenStore: _MemoryTokenStore(_tokens()),
      );

      await socket.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(socket.state, DollarSocketState.disconnected);
      await socket.dispose();
    },
  );

  test(
    'removes pending message and emits failure after max attempts',
    () async {
      final connection = _FakeConnection();
      final failures = <String>[];
      final socket = DollarSocket(
        url: 'wss://example.test/api/v1/ws',
        tokenStore: _MemoryTokenStore(_tokens()),
        connector: (_) async => connection,
        ackTimeout: const Duration(milliseconds: 5),
        maxSendAttempts: 2,
      );
      final failureSubscription = socket.failedMessageIds.listen(failures.add);
      await socket.connect();
      connection.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 60});
      await _flush();
      connection.add({'type': 'AUTH_OK'});
      await _flush();

      final clientMessageId = await socket.sendMessage('ACK 없는 메시지');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(failures, [clientMessageId]);
      expect(
        _types(connection.sent).where((type) => type == 'SEND_MESSAGE'),
        hasLength(2),
      );
      await failureSubscription.cancel();
      await socket.dispose();
    },
  );

  test('cancels the previous subscription before reconnecting', () async {
    final first = _FakeConnection();
    final second = _FakeConnection();
    final connections = [first, second];
    var connectCount = 0;
    final socket = DollarSocket(
      url: 'wss://example.test/api/v1/ws',
      tokenStore: _MemoryTokenStore(_tokens()),
      connector: (_) async => connections[connectCount++],
      maxReconnectDelay: Duration.zero,
    );

    await socket.connect();
    first.fail(StateError('transport closed'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(first.cancelCount, 1);
    expect(connectCount, 2);
    second.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 60});
    await _flush();
    expect(_frame(second.sent.single)['type'], 'AUTH');
    expect(_frame(second.sent.single)['accessToken'], 'access-token');
    await socket.dispose();
  });

  testWidgets('reconnects when a heartbeat PONG is missing', (tester) async {
    final first = _FakeConnection();
    final second = _FakeConnection();
    final connections = [first, second];
    var connectCount = 0;
    final socket = DollarSocket(
      url: 'wss://example.test/api/v1/ws',
      tokenStore: _MemoryTokenStore(_tokens()),
      connector: (_) async => connections[connectCount++],
      maxReconnectDelay: Duration.zero,
    );

    await socket.connect();
    first.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 1});
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(_types(first.sent), contains('PING'));

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(connectCount, 2);
    expect(first.closeCount, 1);

    await tester.runAsync(socket.dispose);
  });

  testWidgets('keeps the connection when heartbeat PONG arrives', (
    tester,
  ) async {
    final connection = _FakeConnection();
    var connectCount = 0;
    final socket = DollarSocket(
      url: 'wss://example.test/api/v1/ws',
      tokenStore: _MemoryTokenStore(_tokens()),
      connector: (_) async {
        connectCount += 1;
        return connection;
      },
      maxReconnectDelay: Duration.zero,
    );

    await socket.connect();
    connection.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 1});
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    connection.add({'type': 'PONG'});
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(connectCount, 1);
    expect(
      _types(connection.sent).where((type) => type == 'PING'),
      hasLength(2),
    );
    await tester.runAsync(socket.dispose);
  });

  testWidgets(
    'sends through the socket and shows one copy of the echoed MESSAGE',
    (tester) async {
      final connection = _FakeConnection();
      final socket = DollarSocket(
        url: 'wss://example.test/api/v1/ws?roomId=usd',
        tokenStore: _MemoryTokenStore(_tokens()),
        connector: (_) async => connection,
      );
      await tester.pumpWidget(
        Provider<DollarSocket>.value(
          value: socket,
          child: MaterialApp(
            home: UsdRoomPage(
              repository: MockDollarRepository(),
              onRateBarTap: () {},
            ),
          ),
        ),
      );
      await socket.connect();
      connection.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 60});
      await tester.pump();
      connection.add({'type': 'AUTH_OK'});
      await tester.pump();

      await tester.enterText(find.byType(TextField), '실제 전송 메시지');
      await tester.pump();
      await tester.tap(find.text('↑'));
      await tester.pump();

      final sends = connection.sent
          .map(_frame)
          .where((frame) => frame['type'] == 'SEND_MESSAGE')
          .toList();
      expect(sends, hasLength(1));
      final clientMessageId = sends.single['clientMessageId'] as String;
      connection.add({
        'type': 'MESSAGE_ACK',
        'clientMessageId': clientMessageId,
      });
      connection.add({
        'type': 'MESSAGE',
        'message': {
          'id': 'message-live-1',
          'content': '실제 전송 메시지',
          'author': {'nickname': '나', 'usdAmount': '100', 'profitRate': '1.0'},
        },
      });
      connection.add({
        'type': 'MESSAGE',
        'message': {
          'id': 'message-live-1',
          'content': '실제 전송 메시지',
          'author': {'nickname': '나', 'usdAmount': '100', 'profitRate': '1.0'},
        },
      });
      await tester.pump();

      expect(find.text('실제 전송 메시지'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.runAsync(socket.dispose);
    },
  );

  testWidgets('shows the newest chat message below older messages', (
    tester,
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

    final newestY = tester.getCenter(find.text('오늘도 달러방 출석합니다.')).dy;
    final oldestY = tester.getCenter(find.text('다들 성투하세요.')).dy;
    expect(newestY, greaterThan(oldestY));
  });

  testWidgets('does not render a WebSocket message from a blocked author', (
    tester,
  ) async {
    final connection = _FakeConnection();
    final socket = DollarSocket(
      url: 'wss://example.test/api/v1/ws?roomId=usd',
      tokenStore: _MemoryTokenStore(_tokens()),
      connector: (_) async => connection,
    );
    await tester.pumpWidget(
      Provider<DollarSocket>.value(
        value: socket,
        child: MaterialApp(
          home: UsdRoomPage(
            repository: MockDollarRepository(),
            onRateBarTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('환율 보고 계신가요?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('차단'));
    await tester.pumpAndSettle();

    await socket.connect();
    connection.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 60});
    await tester.pump();
    connection.add({'type': 'AUTH_OK'});
    connection.add({
      'type': 'MESSAGE',
      'message': {
        'id': 'message-from-blocked-user',
        'content': '차단 후 실시간 메시지',
        'author': {'id': 'user-2', 'nickname': '이달러'},
      },
    });
    await tester.pump();

    expect(find.text('차단 후 실시간 메시지'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(socket.dispose);
  });

  testWidgets('closes an active WebSocket connection after account deletion', (
    tester,
  ) async {
    final connection = _FakeConnection();
    final socket = DollarSocket(
      url: 'wss://example.test/api/v1/ws?roomId=usd',
      tokenStore: _MemoryTokenStore(_tokens()),
      connector: (_) async => connection,
    );
    await socket.connect();
    connection.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 60});
    await tester.pump();
    connection.add({'type': 'AUTH_OK'});
    await tester.pump();

    await tester.pumpWidget(
      Provider<DollarSocket>.value(
        value: socket,
        child: MaterialApp(
          home: MyPage(repository: MockDollarRepository(), onBack: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('회원 탈퇴'));
    await tester.tap(find.text('회원 탈퇴'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('계속'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('탈퇴하기'));
    await tester.pump(kThemeAnimationDuration);
    await tester.pumpAndSettle();

    expect(find.byType(AuthPage), findsOneWidget);
    expect(connection.closeCount, 1);
  });

  testWidgets(
    'clears the session and shows auth entry when token refresh fails',
    (tester) async {
      final connection = _FakeConnection();
      final tokenStore = _MemoryTokenStore(_tokens());
      final socket = DollarSocket(
        url: 'wss://example.test/api/v1/ws?roomId=usd',
        tokenStore: tokenStore,
        connector: (_) async => connection,
        tokenRefresher: () async => null,
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<DollarSocket>.value(value: socket),
            Provider<TokenStore>.value(value: tokenStore),
            Provider<DollarRepository>.value(value: MockDollarRepository()),
          ],
          child: MaterialApp(
            home: UsdRoomPage(
              repository: MockDollarRepository(),
              onRateBarTap: () {},
            ),
          ),
        ),
      );
      await socket.connect();
      connection.add({'type': 'CONNECTED', 'heartbeatIntervalSeconds': 60});
      await tester.pump();
      connection.add({'type': 'AUTH_OK'});
      await tester.pump();

      connection.add({
        'type': 'ERROR',
        'error': {'code': 'TOKEN_EXPIRED', 'message': '토큰 만료'},
      });
      await tester.pump();
      await tester.pumpAndSettle();

      expect(await tokenStore.read(), isNull);
      expect(find.byType(AuthPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.runAsync(socket.dispose);
    },
  );
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

final _uuidV4 = matches(
  RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ),
);

Map<String, dynamic> _frame(String frame) =>
    Map<String, dynamic>.from(jsonDecode(frame) as Map);

Iterable<String> _types(List<String> frames) =>
    frames.map((frame) => _frame(frame)['type'] as String);

TokenPair _tokens({String access = 'access-token'}) => TokenPair(
  accessToken: access,
  refreshToken: 'refresh-token',
  accessExpiresAt: DateTime.utc(2026, 1, 1),
  refreshExpiresAt: DateTime.utc(2026, 2, 1),
);

class _MemoryTokenStore implements TokenStore {
  _MemoryTokenStore(this._tokens);
  TokenPair? _tokens;
  @override
  Future<void> clear() async => _tokens = null;
  @override
  Future<TokenPair?> read() async => _tokens;
  @override
  Future<void> write(TokenPair tokens) async => _tokens = tokens;
}

class _FakeConnection implements SocketConnection {
  _FakeConnection() {
    _frames = StreamController<dynamic>.broadcast(
      onCancel: () => cancelCount += 1,
    );
  }

  final sent = <String>[];
  late final StreamController<dynamic> _frames;
  int cancelCount = 0;
  int closeCount = 0;
  @override
  Stream<dynamic> get stream => _frames.stream;
  void add(Map<String, dynamic> frame) => _frames.add(jsonEncode(frame));
  void fail(Object error) => _frames.addError(error);
  @override
  Future<void> close() {
    closeCount += 1;
    return _frames.close();
  }

  @override
  void send(String value) => sent.add(value);
}
