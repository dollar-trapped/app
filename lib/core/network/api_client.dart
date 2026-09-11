import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/token_store.dart';
import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._tokenStore, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              headers: const {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          ) {
    _dio.interceptors.add(_AuthInterceptor(_dio, _tokenStore));
  }

  final Dio _dio;
  final TokenStore _tokenStore;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) => _request<T>(() => _dio.get<T>(path, queryParameters: queryParameters));
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) => _request<T>(
    () => _dio.post<T>(
      path,
      data: data,
      options: Options(extra: {'skipAuth': skipAuth}),
    ),
  );
  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _request<T>(() => _dio.patch<T>(path, data: data));
  Future<Response<T>> put<T>(String path) =>
      _request<T>(() => _dio.put<T>(path));
  Future<Response<T>> delete<T>(String path) =>
      _request<T>(() => _dio.delete<T>(path));

  /// Refreshes persisted tokens for WebSocket TOKEN_EXPIRED handling.
  Future<TokenPair?> refreshAccessToken() async {
    final current = await _tokenStore.read();
    if (current == null) return null;
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': current.refreshToken},
        skipAuth: true,
      );
      final json = response.data!;
      final tokens = TokenPair(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        accessExpiresAt: DateTime.parse(
          json['accessExpiresAt'] as String,
        ).toUtc(),
        refreshExpiresAt: DateTime.parse(
          json['refreshExpiresAt'] as String,
        ).toUtc(),
      );
      await _tokenStore.write(tokens);
      return tokens;
    } catch (_) {
      await _tokenStore.clear();
      return null;
    }
  }

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromResponse(
        statusCode: error.response?.statusCode,
        data: error.response?.data,
        fallbackMessage: error.message ?? '네트워크 연결을 확인해 주세요.',
      );
    }
  }
}

class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this._dio, this._tokenStore);
  final Dio _dio;
  final TokenStore _tokenStore;
  Future<TokenPair?>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }
    final tokens = await _tokenStore.read();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final options = error.requestOptions;
    final isRefresh = options.path.endsWith('/auth/refresh');
    if (error.response?.statusCode != 401 ||
        options.extra['skipAuth'] == true ||
        isRefresh ||
        options.extra['retried'] == true) {
      return handler.next(error);
    }
    try {
      final current = await _tokenStore.read();
      final failedToken = options.headers['Authorization'];
      // A queued request may have failed before another request refreshed.
      final tokens =
          current != null && failedToken == 'Bearer ${current.accessToken}'
          ? await _refresh(current)
          : current;
      if (tokens == null) {
        return handler.next(error);
      }
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      options.extra['retried'] = true;
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (_) {
      handler.next(error);
    }
  }

  Future<TokenPair?> _refresh(TokenPair current) async {
    final pending = _refreshing;
    if (pending != null) {
      return pending;
    }
    final completer = Completer<TokenPair?>();
    _refreshing = completer.future;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': current.refreshToken},
        options: Options(extra: const {'skipAuth': true}),
      );
      final json = response.data!;
      final tokens = TokenPair(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        accessExpiresAt: DateTime.parse(
          json['accessExpiresAt'] as String,
        ).toUtc(),
        refreshExpiresAt: DateTime.parse(
          json['refreshExpiresAt'] as String,
        ).toUtc(),
      );
      await _tokenStore.write(tokens);
      completer.complete(tokens);
    } catch (_) {
      await _tokenStore.clear();
      completer.complete(null);
    } finally {
      _refreshing = null;
    }
    return completer.future;
  }
}
