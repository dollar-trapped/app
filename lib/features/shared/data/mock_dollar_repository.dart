import '../../gacha/data/wish_ticket_models.dart';
import '../../gacha/data/gacha_models.dart';
import '../../legal/consent_versions.dart';
import '../../cosmetics/models/cosmetic_models.dart';
import 'api_models.dart';
import 'dollar_repository.dart';

/// In-memory API substitute for UI development and deterministic widget tests.
/// It deliberately has the same public contract as [DollarApi].
class MockDollarRepository implements DollarRepository {
  MockDollarRepository({DateTime? now})
    : _now = (now ?? DateTime.now()).toUtc();

  final DateTime _now;
  final List<BlockedUser> _blockedUsers = [];
  late User _user = _userFor(email: 'dollar@example.com', nickname: '초록달러');

  User _userFor({required String email, required String nickname}) => User(
    id: 'user-me',
    email: email,
    nickname: nickname,
    usdAmount: '2000',
    averageExchangeRate: '1279.55',
    profitRate: '5.2',
    profitRateAsOf: _now,
    createdAt: _now.subtract(const Duration(days: 30)),
  );

  AuthSession _session() => AuthSession(
    accessToken: 'mock-access-token',
    refreshToken: 'mock-refresh-token',
    accessExpiresAt: _now.add(const Duration(hours: 1)),
    refreshExpiresAt: _now.add(const Duration(days: 30)),
    user: _user,
  );

  @override
  Future<Map<String, dynamic>> getTermsVersions() async => {
    'termsVersion': bundledTermsVersion,
    'privacyVersion': bundledPrivacyVersion,
  };
  @override
  Future<Map<String, dynamic>> getTermsAgreements() async => {
    'terms': {'reagreementRequired': false},
    'privacy': {'reagreementRequired': false},
  };
  @override
  Future<void> agreeToDocument(String document, String version) async {}

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String nickname,
    required String verificationToken,
    required String termsVersion,
    required String privacyVersion,
  }) async {
    _user = _userFor(email: email, nickname: nickname);
    return _session();
  }

  @override
  Future<void> requestEmailVerification({required String email}) async {}

  @override
  Future<String> verifyEmail({
    required String email,
    required String code,
  }) async => 'mock-verification-token';

  @override
  Future<AuthSession> logIn({
    required String email,
    required String password,
  }) async {
    _user = _userFor(email: email, nickname: _user.nickname);
    return _session();
  }

  @override
  Future<void> logOut() async {}

  @override
  Future<User> getMe() async => _user;

  @override
  Future<User> updateMe({
    String? nickname,
    Object? usdAmount,
    Object? averageExchangeRate,
  }) async {
    _user = User(
      id: _user.id,
      email: _user.email,
      nickname: nickname ?? _user.nickname,
      usdAmount: usdAmount is String ? usdAmount : _user.usdAmount,
      averageExchangeRate: averageExchangeRate is String
          ? averageExchangeRate
          : _user.averageExchangeRate,
      profitRate: _user.profitRate,
      profitRateAsOf: _now,
      createdAt: _user.createdAt,
    );
    return _user;
  }

  @override
  Future<void> deleteAccount(String password) async {}

  @override
  Future<MessagePage> getMessages({
    int limit = 50,
    String? before,
    String? after,
  }) async {
    final messages = <ChatMessage>[
      _message('message-3', 'cursor-3', _user.nickname, '오늘도 달러방 출석합니다.', 2),
      _message('message-2', 'cursor-2', '이달러', '환율 보고 계신가요?', 3),
      _message('message-1', 'cursor-1', '김달러', '다들 성투하세요.', 4),
    ];
    return MessagePage(
      items: messages.take(limit).toList(),
      hasMore: false,
      nextCursor: null,
      latestCursor: messages.first.cursor,
    );
  }

  ChatMessage _message(
    String id,
    String cursor,
    String nickname,
    String content,
    int minutesAgo,
  ) => ChatMessage(
    id: id,
    cursor: cursor,
    roomId: 'usd',
    author: MessageAuthor(
      id: nickname == _user.nickname
          ? _user.id
          : id.replaceFirst('message', 'user'),
      nickname: nickname,
      usdAmount: nickname == _user.nickname ? _user.usdAmount : '2300',
      profitRate: nickname == _user.nickname ? _user.profitRate : '3.2',
      profitRateAsOf: _now,
    ),
    content: content,
    createdAt: _now.subtract(Duration(minutes: minutesAgo)),
  );

  @override
  Future<ReportReceipt> reportMessage(
    String messageId, {
    required String reason,
    String? description,
  }) async => ReportReceipt(
    id: 'report-$messageId',
    messageId: messageId,
    createdAt: _now,
  );

  @override
  Future<List<BlockedUser>> getBlockedUsers() async =>
      List.unmodifiable(_blockedUsers);

  @override
  Future<void> blockUser(String userId) async {
    if (_blockedUsers.every((user) => user.userId != userId)) {
      _blockedUsers.add(
        BlockedUser(userId: userId, nickname: '차단 사용자', createdAt: _now),
      );
    }
  }

  @override
  Future<void> unblockUser(String userId) async {
    _blockedUsers.removeWhere((user) => user.userId == userId);
  }

  @override
  Future<ExchangeRate> getUsdKrwRate() async => ExchangeRate(
    pair: 'USD-KRW',
    rate: '1346.09',
    asOf: _now,
    fetchedAt: _now,
    source: 'mock',
    marketStatus: 'closed',
    isStale: false,
  );

  @override
  Future<ExchangeRateHistory> getUsdKrwHistory(String range) async {
    final points = List.generate(
      5,
      (index) => ExchangeRatePoint(
        time: _now.subtract(Duration(days: 4 - index)),
        asOf: _now,
        rate: (1342.5 + index).toStringAsFixed(2),
        source: 'mock',
      ),
    );
    return ExchangeRateHistory(
      pair: 'USD-KRW',
      range: range,
      interval: '1d',
      from: points.first.time,
      to: points.last.time,
      points: points,
      isPartial: false,
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {}
  @override
  Future<String> verifyPasswordReset(String email, String code) async =>
      'mock-reset-token';
  @override
  Future<void> resetPassword(String token, String password) async {}
  @override
  Future<CosmeticCatalog> getCosmeticCatalog() async =>
      const CosmeticCatalog(items: [], probabilities: {});
  @override
  Future<CosmeticInventory> getMyCosmetics() async => const CosmeticInventory(
    items: [],
    equipment: CosmeticEquipment(version: 0),
    tickets: 0,
    dollarChips: 0,
  );
  @override
  Future<CosmeticEquipment> equipCosmetics(CosmeticEquipment equipment) async =>
      equipment;
  @override
  Future<WishTicketState> getWishTickets() async =>
      const WishTicketState(enabled: false, chips: 0, tickets: 0, options: []);
  @override
  Future<WishTicketReceipt> exchangeWishTicket(String operationId) async =>
      throw StateError('염원의 선택권은 준비 중입니다.');
  @override
  Future<WishTicketReceipt> redeemWishTicket(
    String operationId,
    String cosmeticId,
  ) async => throw StateError('염원의 선택권은 준비 중입니다.');
  @override
  Future<ChipExchange> exchangeChips(String operationId) async =>
      throw StateError('달러칩이 부족합니다.');
  @override
  Future<CosmeticDraw> drawCosmetic(String requestId) async =>
      throw StateError('뽑기권이 없습니다.');
  @override
  Future<CosmeticBatchDraw> drawCosmeticBatch(String requestId) async =>
      throw StateError('뽑기권이 없습니다.');
  @override
  Future<AdRewardSession> createAdRewardSession(String requestId) async =>
      throw StateError('Mock에서는 광고 보상을 지급하지 않습니다.');
  @override
  Future<AdRewardSession> getAdRewardSession(String sessionId) async =>
      throw StateError('Mock 광고 세션이 없습니다.');
}
