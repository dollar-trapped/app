import '../../gacha/data/cosmetic_models.dart';
import 'package:dollar_trapped/features/shared/data/json_helpers.dart';

class MessageAuthor {
  const MessageAuthor({
    required this.id,
    required this.nickname,
    required this.usdAmount,
    required this.profitRate,
    required this.profitRateAsOf,
    this.cosmetics,
  });
  final MessageCosmetics? cosmetics;
  final String? id, usdAmount, profitRate;
  final String nickname;
  final DateTime? profitRateAsOf;
  factory MessageAuthor.fromJson(Json json) => MessageAuthor(
    cosmetics: json['cosmetics'] is Map
        ? MessageCosmetics.fromJson(
            Map<String, dynamic>.from(json['cosmetics'] as Map),
          )
        : null,
    id: jsonString(json, 'id'),
    nickname: json['nickname'] as String,
    usdAmount: jsonString(json, 'usdAmount'),
    profitRate: jsonString(json, 'profitRate'),
    profitRateAsOf: json['profitRateAsOf'] == null
        ? null
        : jsonDate(json, 'profitRateAsOf'),
  );
}
