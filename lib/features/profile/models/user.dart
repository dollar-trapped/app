import '../../../core/moderation/moderation_status.dart';
import 'package:dollar_trapped/features/shared/data/json_helpers.dart';

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
    this.moderation = const ModerationStatus(),
  });
  final ModerationStatus moderation;
  final String id, email, nickname;
  final String? usdAmount, averageExchangeRate, profitRate;
  final DateTime? profitRateAsOf;
  final DateTime createdAt;
  factory User.fromJson(Json json) => User(
    moderation: ModerationStatus.fromJson(
      Map<String, dynamic>.from(json['moderation'] as Map? ?? const {}),
    ),
    id: json['id'] as String,
    email: json['email'] as String,
    nickname: json['nickname'] as String,
    usdAmount: jsonString(json, 'usdAmount'),
    averageExchangeRate: jsonString(json, 'averageExchangeRate'),
    profitRate: jsonString(json, 'profitRate'),
    profitRateAsOf: json['profitRateAsOf'] == null
        ? null
        : jsonDate(json, 'profitRateAsOf'),
    createdAt: jsonDate(json, 'createdAt'),
  );
}
