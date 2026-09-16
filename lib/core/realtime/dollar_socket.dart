import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/token_store.dart';
import '../network/api_client.dart';

/// Transport CONNECT is followed by server CONNECTED, then client AUTH.
enum DollarSocketState {
  disconnected,
  connecting,
  connected,
  authenticating,
  authenticated,
  reconnecting,
}

class RealtimeMessage {
  const RealtimeMessage({
    required this.id,
    required this.content,
    required this.data,
  });
  final String id;
  final String content;
  final Map<String, dynamic> data;
}

class SocketError {
  const SocketError({
    required this.code,
    required this.message,
    this.scope,
    this.retryAfter,
  });
  final String code;
  final String message;
  final String? scope;
  final Duration? retryAfter;
}

abstract interface class SocketConnection {
  Stream<dynamic> get stream;
  void send(String value);
  Future<void> close();
}

typedef SocketConnector = Future<SocketConnection> Function(Uri url);
typedef TokenRefresher = Future<TokenPair?> Function();

/// USD room WebSocket client implementing the server's top-level frame schema.
///
/// The server sends CONNECTED first. AUTH and SEND_MESSAGE are top-level
/// requests (never `{type, data}` envelopes). SEND_MESSAGE retries retain the
/// same UUID v4 clientMessageId, while each transmission gets a requestId.
class DollarSocket {
  DollarSocket({
    required String url,
    required this.tokenStore,
    SocketConnector? connector,
    TokenRefresher? tokenRefresher,
    this.ackTimeout = const Duration(seconds: 5),
    this.maxSendAttempts = 3,
    this.maxReconnectDelay = const Duration(seconds: 30),
  }) : _url = Uri.parse(url),
       _connector = connector ?? _connectChannel,
       _tokenRefresher =
           tokenRefresher ?? (() => ApiClient(tokenStore).refreshAccessToken());

  final Uri _url;
  final TokenStore tokenStore;
  final SocketConnector _connector;
  final TokenRefresher _tokenRefresher;
  final Duration ackTimeout;
  final int maxSendAttempts;
  final Duration maxReconnectDelay;
  final _states = StreamController<DollarSocketState>.broadcast();
  final _messages = StreamController<RealtimeMessage>.broadcast();
  final _errors = StreamController<SocketError>.broadcast();
  final _deletedMessageIds = StreamController<String>.broadcast();
  final _failedMessageIds = StreamController<String>.broadcast();
  final _seenMessageIds = <String>{};
  final _pending = <String, _PendingMessage>{};
  final _random = Random.secure();

  SocketConnection? _connection;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Future<bool>? _refreshingAuthentication;
  DollarSocketState _state = DollarSocketState.disconnected;
  int _reconnectAttempts = 0;
  bool _awaitingPong = false;
  bool _disposed = false;

  Stream<DollarSocketState> get states => _states.stream;
  Stream<RealtimeMessage> get messages => _messages.stream;
  Stream<SocketError> get errors => _errors.stream;
  Stream<String> get deletedMessageIds => _deletedMessageIds.stream;
  Stream<String> get failedMessageIds => _failedMessageIds.stream;
  DollarSocketState get state => _state;

  Future<void> connect() async {
    if (_state != DollarSocketState.disconnected) return;
    _setState(DollarSocketState.connecting);
    try {
      // A reconnect must detach the previous stream before installing a new
      // listener, otherwise a late onDone can affect the replacement socket.
      await _subscription?.cancel();
      _subscription = null;
      _connection = await _connector(_url);
      _subscription = _connection!.stream.listen(
        _onFrame,
        onError: _onTransportClosed,
        onDone: _onTransportClosed,
      );
      // The server sends CONNECTED; no client CONNECT frame exists in the API.
    } catch (_) {
      _setState(DollarSocketState.disconnected);
      _scheduleReconnect();
    }
  }

  Future<String> sendMessage(String content) async {
    if (_state != DollarSocketState.authenticated) {
      throw StateError('WebSocket 인증이 완료되지 않았습니다.');
    }
    final clientMessageId = _uuidV4();
    final pending = _PendingMessage(
      clientMessageId: clientMessageId,
      content: content,
    );
    _pending[clientMessageId] = pending;
    _sendPending(pending);
    return clientMessageId;
  }

  void _onFrame(dynamic frame) async {
    try {
      final decoded = jsonDecode(frame as String);
      if (decoded is! Map) return;
      final event = Map<String, dynamic>.from(decoded);
      switch (event['type'] as String?) {
        case 'CONNECTED':
          debugPrint('[DollarSocket] CONNECTED');
          _reconnectAttempts = 0;
          _setState(DollarSocketState.connected);
          _startHeartbeat(event['heartbeatIntervalSeconds']);
          await _authenticate();
          break;
        case 'AUTH_OK':
          debugPrint('[DollarSocket] AUTH_OK');
          _setState(DollarSocketState.authenticated);
          _resumePendingMessages();
          break;
        case 'MESSAGE':
          _emitMessage(event);
          break;
        case 'MESSAGE_ACK':
          _acknowledge(event['clientMessageId'] as String?);
          break;
        case 'PING':
          _send({'type': 'PONG'});
          break;
        case 'PONG':
          _awaitingPong = false;
          break;
        case 'ERROR':
          await _handleError(event);
          break;
        case 'MESSAGE_DELETED':
          _deleteMessage(event);
          break;
      }
    } catch (_) {
      // Ignore malformed frames without tearing down a healthy transport.
    }
  }

  Future<void> _authenticate([TokenPair? suppliedTokens]) async {
    final tokens = suppliedTokens ?? await tokenStore.read();
    if (tokens == null || _connection == null) return;
    _setState(DollarSocketState.authenticating);
    _send({
      'type': 'AUTH',
      'requestId': _uuidV4(),
      'accessToken': tokens.accessToken,
    });
    // Log only the protocol transition; never print the access token.
    debugPrint('[DollarSocket] AUTH sent');
  }

  Future<bool> _refreshAndAuthenticate() {
    final active = _refreshingAuthentication;
    if (active != null) return active;
    final task = _refreshAndAuthenticateInternal();
    _refreshingAuthentication = task;
    return task.whenComplete(() => _refreshingAuthentication = null);
  }

  Future<bool> _refreshAndAuthenticateInternal() async {
    final refreshed = await _tokenRefresher();
    if (refreshed == null) {
      await tokenStore.clear();
      _setState(DollarSocketState.connected);
      return false;
    }
    await _authenticate(refreshed);
    return true;
  }

  void _startHeartbeat(Object? rawInterval) {
    _heartbeatTimer?.cancel();
    final seconds = rawInterval is num ? rawInterval.toInt() : 0;
    if (seconds <= 0) return;
    // CONNECTED is the sole source of heartbeat cadence in the server spec.
    _heartbeatTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      if (_awaitingPong) {
        _onTransportClosed(
          TimeoutException('WebSocket heartbeat PONG timeout'),
        );
        return;
      }
      _awaitingPong = true;
      _send({'type': 'PING'});
    });
  }

  void _emitMessage(Map<String, dynamic> event) {
    final rawMessage = event['message'];
    if (rawMessage is! Map) return;
    final message = Map<String, dynamic>.from(rawMessage);
    final id = message['id'] as String?;
    final content = message['content'] as String?;
    if (id == null || content == null || !_seenMessageIds.add(id)) return;
    _messages.add(RealtimeMessage(id: id, content: content, data: message));
  }

  void _deleteMessage(Map<String, dynamic> event) {
    final messageId = event['messageId'] as String?;
    if (messageId == null) return;
    _seenMessageIds.remove(messageId);
    _deletedMessageIds.add(messageId);
  }

  Future<void> _handleError(Map<String, dynamic> event) async {
    final rawError = event['error'];
    if (rawError is! Map) return;
    final error = Map<String, dynamic>.from(rawError);
    final code = error['code'] as String?;
    final message = error['message'] as String?;
    if (code == null || message == null) return;
    final retrySeconds = error['retryAfterSeconds'];
    final socketError = SocketError(
      code: code,
      message: message,
      scope: error['scope'] as String?,
      retryAfter: retrySeconds is num
          ? Duration(seconds: retrySeconds.ceil())
          : null,
    );
    if (code == 'TOKEN_EXPIRED') {
      final recovered = await _refreshAndAuthenticate();
      if (!recovered) _errors.add(socketError);
      return;
    }
    _errors.add(socketError);
  }

  void _acknowledge(String? clientMessageId) {
    if (clientMessageId == null) return;
    final pending = _pending.remove(clientMessageId);
    pending?.timer?.cancel();
  }

  void _sendPending(_PendingMessage pending) {
    if (_connection == null) return;
    if (pending.attempts >= maxSendAttempts) {
      _failPending(pending);
      return;
    }
    pending.attempts += 1;
    _send({
      'type': 'SEND_MESSAGE',
      'requestId': _uuidV4(),
      'clientMessageId': pending.clientMessageId,
      'content': pending.content,
    });
    pending.timer?.cancel();
    pending.timer = Timer(ackTimeout, () => _sendPending(pending));
  }

  void _failPending(_PendingMessage pending) {
    if (!identical(_pending[pending.clientMessageId], pending)) return;
    pending.timer?.cancel();
    _pending.remove(pending.clientMessageId);
    _failedMessageIds.add(pending.clientMessageId);
  }

  void _resumePendingMessages() {
    for (final pending in _pending.values) {
      pending.timer?.cancel();
      // Reuse the client UUID after reconnect so server idempotency holds.
      _sendPending(pending);
    }
  }

  void _send(Map<String, Object> frame) => _connection?.send(jsonEncode(frame));

  void _onTransportClosed([Object? _]) {
    if (_disposed) return;
    final previousSubscription = _subscription;
    final previousConnection = _connection;
    _subscription = null;
    _connection = null;
    if (previousSubscription != null) {
      unawaited(previousSubscription.cancel());
    }
    if (previousConnection != null) {
      unawaited(_closeSilently(previousConnection));
    }
    _heartbeatTimer?.cancel();
    _awaitingPong = false;
    _setState(DollarSocketState.reconnecting);
    _scheduleReconnect();
  }

  Future<void> _closeSilently(SocketConnection connection) async {
    try {
      await connection.close();
    } catch (_) {
      // The transport may already be closed when onDone reaches this method.
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectTimer != null) return;
    final exponent = min(_reconnectAttempts++, 5);
    final delay = Duration(
      seconds: min(1 << exponent, maxReconnectDelay.inSeconds),
    );
    _reconnectTimer = Timer(delay, () async {
      _reconnectTimer = null;
      if (_disposed) return;
      _setState(DollarSocketState.disconnected);
      await connect();
    });
  }

  void _setState(DollarSocketState value) {
    _state = value;
    if (!_states.isClosed) _states.add(value);
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> dispose() async {
    await disconnect();
    for (final pending in _pending.values) {
      pending.timer?.cancel();
    }
    _pending.clear();
    await _subscription?.cancel();
    await _states.close();
    await _messages.close();
    await _errors.close();
    await _deletedMessageIds.close();
    await _failedMessageIds.close();
  }

  /// Stops the transport and prevents reconnects while retaining streams for
  /// an owning widget to dispose later.
  Future<void> disconnect() async {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    final connection = _connection;
    _connection = null;
    await connection?.close();
  }

  static Future<SocketConnection> _connectChannel(Uri url) async {
    final channel = WebSocketChannel.connect(url);
    try {
      await channel.ready;
      return _WebSocketChannelConnection(channel);
    } catch (_) {
      unawaited(channel.sink.close());
      rethrow;
    }
  }
}

class _PendingMessage {
  _PendingMessage({required this.clientMessageId, required this.content});
  final String clientMessageId;
  final String content;
  int attempts = 0;
  Timer? timer;
}

class _WebSocketChannelConnection implements SocketConnection {
  _WebSocketChannelConnection(this._channel);
  final WebSocketChannel _channel;
  @override
  Stream<dynamic> get stream => _channel.stream;
  @override
  void send(String value) => _channel.sink.add(value);
  @override
  Future<void> close() => _channel.sink.close();
}
