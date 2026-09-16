import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_client.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';
import 'package:dollar_trapped/features/shared/data/dollar_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'deleting an account clears tokens before another authenticated call',
    () async {
      final tokens = _MemoryTokenStore(_tokens());
      final adapter = _DeletionAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'));
      dio.httpClientAdapter = adapter;
      final api = DollarApi.withDependencies(
        ApiClient(tokens, dio: dio),
        tokens,
      );

      await api.deleteAccount('password123');

      expect(await tokens.read(), isNull);
      await expectLater(api.getMe(), throwsA(isA<ApiException>()));
      expect(adapter.authorizationAfterDeletion, isNull);
    },
  );
}

TokenPair _tokens() => TokenPair(
  accessToken: 'deleted-access-token',
  refreshToken: 'deleted-refresh-token',
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

class _DeletionAdapter implements HttpClientAdapter {
  String? authorizationAfterDeletion;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/users/me/deletion') {
      return ResponseBody.fromString('', 204);
    }
    authorizationAfterDeletion = options.headers['Authorization'] as String?;
    return ResponseBody.fromString(
      jsonEncode({
        'error': {'code': 'UNAUTHORIZED', 'message': '인증이 필요합니다.'},
      }),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
