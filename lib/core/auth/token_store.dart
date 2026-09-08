import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;
}

abstract interface class TokenStore {
  Future<TokenPair?> read();
  Future<void> write(TokenPair tokens);
  Future<void> clear();
}

/// Tokens are deliberately stored in platform secure storage, never in logs or
/// ordinary preferences.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _access = 'auth.access_token';
  static const _refresh = 'auth.refresh_token';
  static const _accessExpiry = 'auth.access_expires_at';
  static const _refreshExpiry = 'auth.refresh_expires_at';
  final FlutterSecureStorage _storage;

  @override
  Future<TokenPair?> read() async {
    final values = await _storage.readAll();
    final access = values[_access];
    final refresh = values[_refresh];
    final accessExpiry = DateTime.tryParse(values[_accessExpiry] ?? '');
    final refreshExpiry = DateTime.tryParse(values[_refreshExpiry] ?? '');
    if (access == null ||
        refresh == null ||
        accessExpiry == null ||
        refreshExpiry == null) {
      return null;
    }
    return TokenPair(
      accessToken: access,
      refreshToken: refresh,
      accessExpiresAt: accessExpiry.toUtc(),
      refreshExpiresAt: refreshExpiry.toUtc(),
    );
  }

  @override
  Future<void> write(TokenPair tokens) async {
    await _storage.write(key: _access, value: tokens.accessToken);
    await _storage.write(key: _refresh, value: tokens.refreshToken);
    await _storage.write(
      key: _accessExpiry,
      value: tokens.accessExpiresAt.toUtc().toIso8601String(),
    );
    await _storage.write(
      key: _refreshExpiry,
      value: tokens.refreshExpiresAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
    await _storage.delete(key: _accessExpiry);
    await _storage.delete(key: _refreshExpiry);
  }
}
