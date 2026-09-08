class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.requestId,
    this.retryAfter,
  });

  final int? statusCode;
  final String code;
  final String message;
  final String? requestId;
  final Duration? retryAfter;

  factory ApiException.fromResponse({
    required int? statusCode,
    required Object? data,
    String fallbackMessage = '요청을 처리하지 못했습니다.',
  }) {
    final json = data is Map ? Map<String, dynamic>.from(data) : null;
    final retrySeconds = json?['retryAfterSeconds'];
    return ApiException(
      statusCode: statusCode,
      code: json?['code'] as String? ?? 'NETWORK_ERROR',
      message: json?['message'] as String? ?? fallbackMessage,
      requestId: json?['requestId'] as String?,
      retryAfter: retrySeconds is num
          ? Duration(seconds: retrySeconds.ceil())
          : null,
    );
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
