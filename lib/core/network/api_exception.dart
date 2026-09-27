class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details = const [],
    this.requestId,
    this.retryAfter,
  });

  final int? statusCode;
  final String code;
  final String message;
  final List<ApiErrorDetail> details;
  final String? requestId;
  final Duration? retryAfter;

  factory ApiException.fromResponse({
    required int? statusCode,
    required Object? data,
    String fallbackMessage = '요청을 처리하지 못했습니다.',
  }) {
    final response = data is Map ? Map<String, dynamic>.from(data) : null;
    final json = response?['error'] is Map
        ? Map<String, dynamic>.from(response!['error'] as Map)
        : response;
    final retrySeconds = json?['retryAfterSeconds'];
    final details = (json?['details'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (detail) => ApiErrorDetail(
            field: detail['field'] as String? ?? '',
            reason: detail['reason'] as String? ?? '',
          ),
        )
        .where((detail) => detail.field.isNotEmpty || detail.reason.isNotEmpty)
        .toList(growable: false);
    return ApiException(
      statusCode: statusCode,
      code: json?['code'] as String? ?? 'NETWORK_ERROR',
      message: json?['message'] as String? ?? fallbackMessage,
      details: details,
      requestId: json?['requestId'] as String?,
      retryAfter: retrySeconds is num
          ? Duration(seconds: retrySeconds.ceil())
          : null,
    );
  }

  String get userMessage {
    if (details.isEmpty) return message;
    return details
        .map(
          (detail) => detail.field.isEmpty
              ? detail.reason
              : '${detail.field}: ${detail.reason}',
        )
        .join('\n');
  }

  /// Hides only the generic validation prompt outside login and signup.
  /// An empty message still represents a failed request.
  String get actionableUserMessage {
    bool isGeneric(String value) =>
        value.replaceAll(RegExp(r'[\s.!?。]'), '') == '입력값을확인해주세요';
    if (details.isEmpty) return isGeneric(message) ? '' : message;
    return details
        .where((detail) => !isGeneric(detail.reason))
        .map(
          (detail) => detail.field.isEmpty
              ? detail.reason
              : '${detail.field}: ${detail.reason}',
        )
        .join('\n');
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

class ApiErrorDetail {
  const ApiErrorDetail({required this.field, required this.reason});

  final String field;
  final String reason;
}
