import 'package:dollar_trapped/features/shared/data/json_helpers.dart';

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
    id: jsonString(json, 'id'),
    nickname: json['nickname'] as String,
    usdAmount: jsonString(json, 'usdAmount'),
    profitRate: jsonString(json, 'profitRate'),
    profitRateAsOf: json['profitRateAsOf'] == null
        ? null
        : jsonDate(json, 'profitRateAsOf'),
  );
}
