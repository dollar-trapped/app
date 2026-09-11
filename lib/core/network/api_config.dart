import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime API settings.
///
/// Prefer `API_BASE_URL` in `.env`; `API_BASE_KEY` remains supported for the
/// existing local setup. Both a bare host and an `/api/v1` URL are accepted.
abstract final class ApiConfig {
  static String get baseUrl {
    const definedUrl = String.fromEnvironment('API_BASE_URL');
    final configuredUrl = definedUrl.isNotEmpty
        ? definedUrl
        : (dotenv.env['API_BASE_URL'] ?? dotenv.env['API_BASE_KEY'] ?? '');
    if (configuredUrl.isEmpty) {
      throw StateError('API_BASE_URL을 .env 또는 --dart-define으로 설정해 주세요.');
    }

    final withoutTrailingSlash = configuredUrl.replaceFirst(RegExp(r'/+$'), '');
    return withoutTrailingSlash.endsWith('/api/v1')
        ? withoutTrailingSlash
        : '$withoutTrailingSlash/api/v1';
  }

  /// WebSocket endpoint. Set `WS_URL` explicitly when the backend exposes a
  /// different gateway; otherwise it is derived from the REST v1 base URL.
  static String get webSocketUrl {
    const definedUrl = String.fromEnvironment('WS_URL');
    final configuredUrl = definedUrl.isNotEmpty
        ? definedUrl
        : dotenv.env['WS_URL'];
    final rawUrl = configuredUrl != null && configuredUrl.isNotEmpty
        ? configuredUrl.replaceFirst(RegExp(r'/+$'), '')
        : '${baseUrl.replaceFirst(RegExp(r'^https'), 'wss')}/ws';
    final uri = Uri.parse(rawUrl);
    return uri
        .replace(queryParameters: {...uri.queryParameters, 'roomId': 'usd'})
        .toString();
  }

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);
}
