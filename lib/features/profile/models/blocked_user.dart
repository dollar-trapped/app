import 'package:dollar_trapped/features/shared/data/json_helpers.dart';

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
    createdAt: jsonDate(json, 'createdAt'),
  );
}
