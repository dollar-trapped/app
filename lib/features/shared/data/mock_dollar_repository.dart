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
  Future<AuthSession> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    _user = _userFor(email: email, nickname: nickname);
    return _session();
  }

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
}
