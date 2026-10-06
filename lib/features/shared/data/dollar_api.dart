import '../../gacha/data/wish_ticket_models.dart';
import '../../gacha/data/gacha_models.dart';
import '../../../core/auth/reward_event_claim.dart';
import '../../cosmetics/models/cosmetic_models.dart';
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
  Future<Map<String, dynamic>> getTermsVersions() async =>
      (await _client.get<Map<String, dynamic>>('/terms')).data!;
  @override
  Future<Map<String, dynamic>> getTermsAgreements() async =>
      (await _client.get<Map<String, dynamic>>(
        '/users/me/terms-agreements',
      )).data!;
  @override
  Future<void> agreeToDocument(String document, String version) async {
    await _client.post<void>(
      '/users/me/terms-agreements',
      data: {'document': document, 'version': version},
    );
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String nickname,
    required String verificationToken,
    required String termsVersion,
    required String privacyVersion,
  }) => _auth('/auth/signup', {
    'email': email,
    'password': password,
    'nickname': nickname,
    'verificationToken': verificationToken,
    'termsVersion': termsVersion,
    'privacyVersion': privacyVersion,
  });
  @override
  Future<void> requestEmailVerification({required String email}) async {
    await _client.post<void>(
      '/auth/email/verification',
      data: {'email': email},
      skipAuth: true,
    );
  }

  @override
  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/email/verify',
      data: {'email': email, 'code': code},
      skipAuth: true,
    );
    return response.data!['verificationToken'] as String;
  }

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
    await claimRewardEvents(_client);
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
  Future<void> deleteAccount(String password) async {
    await _client.post<void>(
      '/users/me/deletion',
      data: {'password': password},
    );
    await _tokens.clear();
  }

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
        data: {
          'reason': reason,
          if (description != null) 'description': description,
        },
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

  @override
  Future<void> requestPasswordReset(String email) async {
    await _client.post<void>(
      '/auth/password/verification',
      data: {'email': email},
      skipAuth: true,
    );
  }

  @override
  Future<String> verifyPasswordReset(String email, String code) async {
    final r = await _client.post<Map<String, dynamic>>(
      '/auth/password/verify',
      data: {'email': email, 'code': code},
      skipAuth: true,
    );
    return r.data!['passwordResetToken'] as String;
  }

  @override
  Future<void> resetPassword(String token, String password) async {
    await _client.post<void>(
      '/auth/password/reset',
      data: {'passwordResetToken': token, 'newPassword': password},
      skipAuth: true,
    );
  }

  @override
  Future<CosmeticCatalog> getCosmeticCatalog() async =>
      CosmeticCatalog.fromJson(
        (await _client.get<Map<String, dynamic>>('/cosmetics')).data!,
      );
  @override
  Future<CosmeticInventory> getMyCosmetics() async =>
      CosmeticInventory.fromJson(
        (await _client.get<Map<String, dynamic>>('/users/me/cosmetics')).data!,
      );
  @override
  Future<CosmeticEquipment> equipCosmetics(CosmeticEquipment equipment) async =>
      CosmeticEquipment.fromJson(
        (await _client.put<Map<String, dynamic>>(
          '/users/me/cosmetic-equipment',
          data: equipment.toRequest(),
        )).data!,
      );
  // Proposed contract; the server must opt in through GET.enabled.
  @override
  Future<WishTicketState> getWishTickets() async => WishTicketState.fromJson(
    (await _client.get<Map<String, dynamic>>('/gacha/wish-tickets')).data!,
  );
  @override
  Future<WishTicketReceipt> exchangeWishTicket(String operationId) async {
    final receipt = WishTicketReceipt.fromJson(
      (await _client.post<Map<String, dynamic>>(
        '/gacha/wish-ticket-exchanges',
        data: {'operationId': operationId},
      )).data!,
    );
    if (receipt.operationId != operationId || receipt.item != null) {
      throw const FormatException('Unexpected wish exchange receipt');
    }
    return receipt;
  }

  @override
  Future<WishTicketReceipt> redeemWishTicket(
    String operationId,
    String cosmeticId,
  ) async {
    final receipt = WishTicketReceipt.fromJson(
      (await _client.post<Map<String, dynamic>>(
        '/gacha/wish-ticket-redemptions',
        data: {'operationId': operationId, 'cosmeticId': cosmeticId},
      )).data!,
    );
    if (receipt.operationId != operationId ||
        receipt.item?.id != cosmeticId ||
        receipt.item?.rarity != 'SPECIAL') {
      throw const FormatException('Unexpected wish redemption receipt');
    }
    return receipt;
  }

  @override
  Future<ChipExchange> exchangeChips(String operationId) async =>
      ChipExchange.fromJson(
        (await _client.post<Map<String, dynamic>>(
          '/gacha/chip-exchanges',
          data: {'operationId': operationId},
        )).data!,
      );
  @override
  Future<CosmeticDraw> drawCosmetic(String requestId) async =>
      CosmeticDraw.fromJson(
        (await _client.post<Map<String, dynamic>>(
          '/gacha/draws',
          data: {'drawRequestId': requestId},
        )).data!,
      );
  @override
  Future<CosmeticBatchDraw> drawCosmeticBatch(String requestId) async {
    final result = CosmeticBatchDraw.fromJson(
      (await _client.post<Map<String, dynamic>>(
        '/gacha/batch-draws',
        data: {'drawRequestId': requestId, 'count': 10},
      )).data!,
    );
    if (result.requestId != requestId || result.count != 10) {
      throw const FormatException('Unexpected batch draw response');
    }
    return result;
  }

  @override
  Future<AdRewardSession> createAdRewardSession(String requestId) async =>
      AdRewardSession.fromJson(
        (await _client.post<Map<String, dynamic>>(
          '/ad-reward-sessions',
          data: {'sessionRequestId': requestId},
        )).data!,
      );
  @override
  Future<AdRewardSession> getAdRewardSession(String sessionId) async =>
      AdRewardSession.fromJson(
        (await _client.get<Map<String, dynamic>>(
          '/ad-reward-sessions/${Uri.encodeComponent(sessionId)}',
        )).data!,
      );
}
