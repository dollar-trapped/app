typedef Json = Map<String, dynamic>;

DateTime _date(Json json, String key) =>
    DateTime.parse(json[key] as String).toUtc();
String? _string(Json json, String key) => json[key] as String?;

class User {
  const User({
    required this.id,
    required this.email,
    required this.nickname,
    required this.usdAmount,
    required this.averageExchangeRate,
    required this.profitRate,
    required this.profitRateAsOf,
    required this.createdAt,
  });
  final String id, email, nickname;
  final String? usdAmount, averageExchangeRate, profitRate;
  final DateTime? profitRateAsOf;
  final DateTime createdAt;
  factory User.fromJson(Json json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    nickname: json['nickname'] as String,
    usdAmount: _string(json, 'usdAmount'),
    averageExchangeRate: _string(json, 'averageExchangeRate'),
    profitRate: _string(json, 'profitRate'),
    profitRateAsOf: json['profitRateAsOf'] == null
        ? null
        : _date(json, 'profitRateAsOf'),
    createdAt: _date(json, 'createdAt'),
  );
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
    required this.user,
  });
  final String accessToken, refreshToken;
  final DateTime accessExpiresAt, refreshExpiresAt;
  final User user;
  factory AuthSession.fromJson(Json json) => AuthSession(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    accessExpiresAt: _date(json, 'accessExpiresAt'),
    refreshExpiresAt: _date(json, 'refreshExpiresAt'),
    user: User.fromJson(Json.from(json['user'] as Map)),
  );
}

class MessageAuthor {
  const MessageAuthor({
    required this.id,
    required this.nickname,
    required this.usdAmount,
    required this.profitRate,
    required this.profitRateAsOf,
  });
  final String? id, usdAmount, profitRate;
  final String nickname;
  final DateTime? profitRateAsOf;
  factory MessageAuthor.fromJson(Json json) => MessageAuthor(
    id: _string(json, 'id'),
    nickname: json['nickname'] as String,
    usdAmount: _string(json, 'usdAmount'),
    profitRate: _string(json, 'profitRate'),
    profitRateAsOf: json['profitRateAsOf'] == null
        ? null
        : _date(json, 'profitRateAsOf'),
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.cursor,
    required this.roomId,
    required this.author,
    required this.content,
    required this.createdAt,
  });
  final String id, cursor, roomId, content;
  final MessageAuthor author;
  final DateTime createdAt;
  factory ChatMessage.fromJson(Json json) => ChatMessage(
    id: json['id'] as String,
    cursor: json['cursor'] as String,
    roomId: json['roomId'] as String,
    author: MessageAuthor.fromJson(Json.from(json['author'] as Map)),
    content: json['content'] as String,
    createdAt: _date(json, 'createdAt'),
  );
}

class MessagePage {
  const MessagePage({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
    required this.latestCursor,
  });
  final List<ChatMessage> items;
  final bool hasMore;
  final String? nextCursor;
  final String latestCursor;
  factory MessagePage.fromJson(Json json) {
    final page = Json.from(json['page'] as Map);
    return MessagePage(
      items: (json['items'] as List)
          .map((item) => ChatMessage.fromJson(Json.from(item as Map)))
          .toList(),
      hasMore: page['hasMore'] as bool,
      nextCursor: _string(page, 'nextCursor'),
      latestCursor: page['latestCursor'] as String,
    );
  }
}

class BlockedUser {
  const BlockedUser({
    required this.userId,
    required this.nickname,
    required this.createdAt,
  });
  final String userId, nickname;
  final DateTime createdAt;
  factory BlockedUser.fromJson(Json json) => BlockedUser(
    userId: json['userId'] as String,
    nickname: json['nickname'] as String,
    createdAt: _date(json, 'createdAt'),
  );
}

class ExchangeRate {
  const ExchangeRate({
    required this.pair,
    required this.rate,
    required this.asOf,
    required this.fetchedAt,
    required this.source,
    required this.marketStatus,
    required this.isStale,
  });
  final String pair, rate, source, marketStatus;
  final DateTime asOf, fetchedAt;
  final bool isStale;
  factory ExchangeRate.fromJson(Json json) => ExchangeRate(
    pair: json['pair'] as String,
    rate: json['rate'] as String,
    asOf: _date(json, 'asOf'),
    fetchedAt: _date(json, 'fetchedAt'),
    source: json['source'] as String,
    marketStatus: json['marketStatus'] as String,
    isStale: json['isStale'] as bool,
  );
}

class ExchangeRateHistory {
  const ExchangeRateHistory({
    required this.pair,
    required this.range,
    required this.interval,
    required this.from,
    required this.to,
    required this.points,
    required this.isPartial,
  });
  final String pair, range, interval;
  final DateTime from, to;
  final List<ExchangeRatePoint> points;
  final bool isPartial;
  factory ExchangeRateHistory.fromJson(Json json) {
    // Keep every chart consumer independent from the server's delivery order.
    final points =
        (json['points'] as List)
            .map((item) => ExchangeRatePoint.fromJson(Json.from(item as Map)))
            .toList()
          ..sort((left, right) => left.time.compareTo(right.time));
    return ExchangeRateHistory(
      pair: json['pair'] as String,
      range: json['range'] as String,
      interval: json['interval'] as String,
      from: _date(json, 'from'),
      to: _date(json, 'to'),
      points: points,
      isPartial: json['isPartial'] as bool,
    );
  }
}

class ExchangeRatePoint {
  const ExchangeRatePoint({
    required this.time,
    required this.rate,
    required this.asOf,
    required this.source,
  });
  final DateTime time, asOf;
  final String rate, source;
  factory ExchangeRatePoint.fromJson(Json json) => ExchangeRatePoint(
    time: _date(json, 'time'),
    rate: json['rate'] as String,
    asOf: _date(json, 'asOf'),
    source: json['source'] as String,
  );
}

class ReportReceipt {
  const ReportReceipt({
    required this.id,
    required this.messageId,
    required this.createdAt,
  });
  final String id, messageId;
  final DateTime createdAt;
  factory ReportReceipt.fromJson(Json json) => ReportReceipt(
    id: json['id'] as String,
    messageId: json['messageId'] as String,
    createdAt: _date(json, 'createdAt'),
  );
}
