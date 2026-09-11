import 'package:dollar_trapped/core/auth/session_restorer.dart';
import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('restores a persisted session when the user request succeeds', () async {
    final tokens = _MemoryTokenStore(_tokens());
    final restored = await SessionRestorer(
      tokens,
      MockDollarRepository(),
    ).restore();

    expect(restored, isTrue);
    expect(await tokens.read(), isNotNull);
  });

  test(
    'clears tokens when refresh and session validation are unauthorized',
    () async {
      final tokens = _MemoryTokenStore(_tokens());
      final restored = await SessionRestorer(
        tokens,
        _UnauthorizedRepository(),
      ).restore();

      expect(restored, isFalse);
      expect(await tokens.read(), isNull);
    },
  );
}

TokenPair _tokens() => TokenPair(
  accessToken: 'access',
  refreshToken: 'refresh',
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

class _UnauthorizedRepository extends MockDollarRepository {
  @override
  Future<User> getMe() => Future.error(
    const ApiException(
      statusCode: 401,
      code: 'AUTH_REQUIRED',
      message: '로그인이 필요합니다.',
    ),
  );
}
