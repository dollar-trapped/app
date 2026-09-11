import '../network/api_exception.dart';
import '../../features/shared/data/dollar_repository.dart';
import 'token_store.dart';

/// Verifies a persisted session before choosing the app's initial route.
/// A 401 response has already had one refresh attempt by [ApiClient].
class SessionRestorer {
  const SessionRestorer(this._tokenStore, this._repository);

  final TokenStore _tokenStore;
  final DollarRepository _repository;

  Future<bool> restore() async {
    if (await _tokenStore.read() == null) return false;
    try {
      await _repository.getMe();
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _tokenStore.clear();
      }
      return false;
    } catch (_) {
      // Keep tokens on transient network failures so the next launch can retry.
      return false;
    }
  }
}
