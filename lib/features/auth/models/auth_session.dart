import 'package:dollar_trapped/features/shared/data/json_helpers.dart';
import 'package:dollar_trapped/features/profile/models/user.dart';

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
    accessExpiresAt: jsonDate(json, 'accessExpiresAt'),
    refreshExpiresAt: jsonDate(json, 'refreshExpiresAt'),
    user: User.fromJson(Json.from(json['user'] as Map)),
  );
}
