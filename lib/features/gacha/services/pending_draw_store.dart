import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PendingDrawStore {
  Future<String?> read(String userId);
  Future<void> write(String userId, String requestId);
  Future<void> clear(String userId);
}

/// Stores only an idempotency key, scoped to the authenticated account.
class SecurePendingDrawStore implements PendingDrawStore {
  const SecurePendingDrawStore();
  static const _storage = FlutterSecureStorage();
  String _key(String userId) => 'pending_cosmetic_draw_$userId';
  @override
  Future<String?> read(String userId) => _storage.read(key: _key(userId));
  @override
  Future<void> write(String userId, String requestId) =>
      _storage.write(key: _key(userId), value: requestId);
  @override
  Future<void> clear(String userId) => _storage.delete(key: _key(userId));
}
