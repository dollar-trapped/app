import 'package:flutter_test/flutter_test.dart';

import 'package:dollar_trapped/core/auth/token_store.dart';

void main() {
  final tokens = TokenPair(
    accessToken: 'access',
    refreshToken: 'refresh',
    accessExpiresAt: DateTime.utc(2026, 9, 17),
    refreshExpiresAt: DateTime.utc(2026, 10, 17),
  );

  test('keeps a remembered login after a fresh app session', () async {
    final persistent = _MemoryTokenStore();
    final firstSession = RememberingTokenStore(persistent);

    firstSession.setRememberSession(true);
    await firstSession.write(tokens);

    final nextSession = RememberingTokenStore(persistent);
    expect((await nextSession.read())?.accessToken, 'access');
  });

  test('does not persist a login when remember login is unchecked', () async {
    final persistent = _MemoryTokenStore();
    final session = RememberingTokenStore(persistent);

    session.setRememberSession(false);
    await session.write(tokens);

    expect((await session.read())?.accessToken, 'access');
    expect(await RememberingTokenStore(persistent).read(), isNull);
  });
}

class _MemoryTokenStore implements TokenStore {
  TokenPair? _tokens;

  @override
  Future<void> clear() async => _tokens = null;

  @override
  Future<TokenPair?> read() async => _tokens;

  @override
  Future<void> write(TokenPair tokens) async => _tokens = tokens;
}
