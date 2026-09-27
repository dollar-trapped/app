import '../network/api_exception.dart';

class ModerationNotice {
  const ModerationNotice({
    required this.id,
    required this.type,
    required this.message,
    this.startsAt,
    this.expiresAt,
  });
  final String id, type, message;
  final DateTime? startsAt, expiresAt;
  bool get suspended => type == 'SUSPENSION';
  bool get blocksChat => suspended || type == 'CHAT_BAN';
  bool get active => expiresAt == null || expiresAt!.isAfter(DateTime.now());
  String get title => suspended
      ? '계정 이용 정지'
      : type == 'CHAT_BAN'
      ? '채팅 이용 제한'
      : '운영 경고';
  String get period =>
      '${_date(startsAt, '시작 시각 미제공')} ~ ${_date(expiresAt, suspended ? '해제 시각 미제공' : '해제 시각 확인 중')}';
  static String _date(DateTime? date, String fallback) {
    if (date == null) return fallback;
    final d = date.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${pad(d.month)}.${pad(d.day)} ${pad(d.hour)}:${pad(d.minute)}';
  }

  static ModerationNotice? fromError(ApiException error) {
    final type = switch (error.code) {
      'CHAT_BANNED' => 'CHAT_BAN',
      'USER_SUSPENDED' ||
      'ACCOUNT_DISABLED' ||
      'ACCOUNT_SUSPENDED' => 'SUSPENSION',
      _ => null,
    };
    if (type == null) return null;
    String? detail(String key) {
      for (final d in error.details) {
        if (d.field == key) return d.reason;
      }
      return null;
    }

    return ModerationNotice(
      id: '$type:${detail('expiresAt') ?? ''}',
      type: type,
      message: detail('userMessage') ?? error.message,
      startsAt: DateTime.tryParse(detail('startsAt') ?? ''),
      expiresAt: DateTime.tryParse(detail('expiresAt') ?? ''),
    );
  }
}

class ModerationStatus {
  const ModerationStatus({this.version = 0, this.notices = const []});
  final int version;
  final List<ModerationNotice> notices;
  factory ModerationStatus.fromJson(Map<String, dynamic> json) {
    final version = (json['version'] as num?)?.toInt() ?? 0;
    final expiry = DateTime.tryParse(json['chatBanExpiresAt'] as String? ?? '');
    return ModerationStatus(
      version: version,
      notices: [
        if (json['suspended'] == true)
          ModerationNotice(
            id: 'suspension:$version',
            type: 'SUSPENSION',
            message: '계정 이용이 정지되었습니다. 관리자 해제 전까지 이용할 수 없습니다.',
            startsAt: DateTime.tryParse(
              json['suspensionStartsAt'] as String? ?? '',
            ),
            expiresAt: DateTime.tryParse(
              json['suspensionExpiresAt'] as String? ?? '',
            ),
          ),
        if (expiry != null)
          ModerationNotice(
            id: 'chat:$version',
            type: 'CHAT_BAN',
            message:
                json['chatBanUserMessage'] as String? ??
                '채팅 이용이 제한되었습니다. 메시지는 읽을 수 있지만 보낼 수 없습니다.',
            startsAt: DateTime.tryParse(
              json['chatBanStartsAt'] as String? ?? '',
            ),
            expiresAt: expiry,
          ),
        for (final warning
            in (json['warnings'] as List? ?? const []).whereType<Map>())
          ModerationNotice(
            id: warning['id'] as String,
            type: 'WARNING',
            message: warning['userMessage'] as String? ?? '운영 정책을 확인해 주세요.',
            startsAt: DateTime.tryParse(warning['createdAt'] as String? ?? ''),
          ),
      ],
    );
  }
}
