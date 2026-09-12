import '../network/api_client.dart';
import 'token_store.dart';

/// Restores a persisted session through the existing REST refresh endpoint.
class SessionRestorer {
  const SessionRestorer(this._tokenStore, this._apiClient);

  final TokenStore _tokenStore;
  final ApiClient _apiClient;

  Future<bool> restore() async {
    if (await _tokenStore.read() == null) return false;
    try {
      final refreshed = await _apiClient.refreshAccessToken();
      if (refreshed != null) return true;
    } catch (_) {
      // Startup refresh failure always returns the app to signed-out state.
    }
    await _tokenStore.clear();
    return false;
  }
}
