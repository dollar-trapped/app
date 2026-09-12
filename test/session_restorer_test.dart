import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dollar_trapped/core/auth/session_restorer.dart';
import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('does not refresh when no persisted tokens exist', () async {
    final tokens = _MemoryTokenStore(null);
    final adapter = _RefreshAdapter(statusCode: 200);
    final restored = await SessionRestorer(
      tokens,
      _client(tokens, adapter),
    ).restore();

    expect(restored, isFalse);
    expect(adapter.requestCount, 0);
  });

  test('restores the session with refreshed tokens', () async {
    final tokens = _MemoryTokenStore(_tokens());
    final adapter = _RefreshAdapter(statusCode: 200);
    final restored = await SessionRestorer(
      tokens,
      _client(tokens, adapter),
    ).restore();

    expect(restored, isTrue);
    expect(adapter.requestCount, 1);
    expect(adapter.lastPath, '/auth/refresh');
    expect(adapter.lastBody, {'refreshToken': 'old-refresh'});
    expect((await tokens.read())?.accessToken, 'new-access');
    expect((await tokens.read())?.refreshToken, 'new-refresh');
  });

  test('clears persisted tokens when refresh fails', () async {
    final tokens = _MemoryTokenStore(_tokens());
    final adapter = _RefreshAdapter(statusCode: 401);
    final restored = await SessionRestorer(
      tokens,
      _client(tokens, adapter),
    ).restore();

    expect(restored, isFalse);
    expect(adapter.requestCount, 1);
    expect(await tokens.read(), isNull);
  });
}

ApiClient _client(TokenStore tokens, HttpClientAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
  dio.httpClientAdapter = adapter;
  return ApiClient(tokens, dio: dio);
}

TokenPair _tokens() => TokenPair(
  accessToken: 'old-access',
  refreshToken: 'old-refresh',
  accessExpiresAt: DateTime.utc(2026, 1, 1),
  refreshExpiresAt: DateTime.utc(2026, 2, 1),
);

class _MemoryTokenStore implements TokenStore {
  _MemoryTokenStore(this._value);

  TokenPair? _value;

  @override
  Future<void> clear() async => _value = null;

  @override
  Future<TokenPair?> read() async => _value;

  @override
  Future<void> write(TokenPair tokens) async => _value = tokens;
}

class _RefreshAdapter implements HttpClientAdapter {
  _RefreshAdapter({required this.statusCode});

  final int statusCode;
  int requestCount = 0;
  String? lastPath;
  Object? lastBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount += 1;
    lastPath = options.path;
    final requestBytes = await requestStream?.fold<List<int>>(
      <int>[],
      (bytes, chunk) => bytes..addAll(chunk),
    );
    if (requestBytes != null) {
      lastBody = jsonDecode(utf8.decode(requestBytes));
    }
    final body = statusCode == 200
        ? {
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'accessExpiresAt': '2026-03-01T00:00:00Z',
            'refreshExpiresAt': '2026-04-01T00:00:00Z',
          }
        : {
            'error': {'code': 'INVALID_REFRESH_TOKEN', 'message': '만료된 토큰'},
          };
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
