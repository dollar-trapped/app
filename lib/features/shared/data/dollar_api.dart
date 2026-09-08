import '../../../core/auth/token_store.dart';
import '../../../core/network/api_client.dart';
import 'api_models.dart';
import 'dollar_repository.dart';

const _unset = Object();

/// Typed REST facade for every v0.1 HTTP endpoint.
class DollarApi implements DollarRepository {
  factory DollarApi({TokenStore? tokenStore}) {
    final tokens = tokenStore ?? SecureTokenStore();
    return DollarApi.withDependencies(ApiClient(tokens), tokens);
  }

  DollarApi.withDependencies(this._client, this._tokens);

  final ApiClient _client;
  final TokenStore _tokens;

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String nickname,
  }) => _auth('/auth/signup', {
    'email': email,
    'password': password,
    'nickname': nickname,
  });
  @override
  Future<AuthSession> logIn({
    required String email,
    required String password,
  }) => _auth('/auth/login', {'email': email, 'password': password});

  Future<AuthSession> _auth(String path, Map<String, String> body) async {
    final response = await _client.post<Map<String, dynamic>>(
      path,
      data: body,
      skipAuth: true,
    );
    final session = AuthSession.fromJson(Json.from(response.data!));
    await _tokens.write(
      TokenPair(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        accessExpiresAt: session.accessExpiresAt,
        refreshExpiresAt: session.refreshExpiresAt,
      ),
    );
    return session;
  }

  @override
  Future<void> logOut() async {
    final tokens = await _tokens.read();
    try {
      if (tokens != null) {
        await _client.post<void>(
          '/auth/logout',
          data: {'refreshToken': tokens.refreshToken},
          skipAuth: true,
        );
      }
    } finally {
      await _tokens.clear();
    }
  }

  @override
  Future<User> getMe() async => User.fromJson(
    Json.from((await _client.get<Map<String, dynamic>>('/users/me')).data!),
  );
  @override
  Future<User> updateMe({
    String? nickname,
    Object? usdAmount = _unset,
    Object? averageExchangeRate = _unset,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) {
      body['nickname'] = nickname;
    }
    if (!identical(usdAmount, _unset)) {
      body['usdAmount'] = usdAmount;
    }
    if (!identical(averageExchangeRate, _unset)) {
      body['averageExchangeRate'] = averageExchangeRate;
    }
    return User.fromJson(
      Json.from(
        (await _client.patch<Map<String, dynamic>>(
          '/users/me',
          data: body,
        )).data!,
      ),
    );
  }

  @override
  Future<void> deleteAccount(String password) =>
      _client.post<void>('/users/me/deletion', data: {'password': password});

  @override
  Future<MessagePage> getMessages({
    int limit = 50,
    String? before,
    String? after,
  }) async {
    assert(before == null || after == null);
    return MessagePage.fromJson(
      Json.from(
        (await _client.get<Map<String, dynamic>>(
          '/rooms/usd/messages',
          queryParameters: {'limit': limit, ?before: before, ?after: after},
        )).data!,
      ),
    );
  }

  @override
  Future<ReportReceipt> reportMessage(
    String messageId, {
    required String reason,
    String? description,
  }) async => ReportReceipt.fromJson(
    Json.from(
      (await _client.post<Map<String, dynamic>>(
        '/messages/$messageId/reports',
        data: {'reason': reason, ?description: description},
      )).data!,
    ),
  );
  @override
  Future<List<BlockedUser>> getBlockedUsers() async {
    final data = Json.from(
      (await _client.get<Map<String, dynamic>>('/users/me/blocks')).data!,
    );
    return (data['items'] as List)
        .map((item) => BlockedUser.fromJson(Json.from(item as Map)))
        .toList();
  }

  @override
  Future<void> blockUser(String userId) =>
      _client.put<void>('/users/me/blocks/$userId');
  @override
  Future<void> unblockUser(String userId) =>
      _client.delete<void>('/users/me/blocks/$userId');
  @override
  Future<ExchangeRate> getUsdKrwRate() async => ExchangeRate.fromJson(
    Json.from(
      (await _client.get<Map<String, dynamic>>(
        '/exchange-rates/USD-KRW',
      )).data!,
    ),
  );
  @override
  Future<ExchangeRateHistory> getUsdKrwHistory(String range) async =>
      ExchangeRateHistory.fromJson(
        Json.from(
          (await _client.get<Map<String, dynamic>>(
            '/exchange-rates/USD-KRW/history',
            queryParameters: {'range': range},
          )).data!,
        ),
      );
}
