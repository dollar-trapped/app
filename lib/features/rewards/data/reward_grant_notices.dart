import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class RewardGrantNotice {
  const RewardGrantNotice({
    required this.id,
    required this.name,
    required this.amount,
    required this.grantedAt,
    required this.deduplicationKey,
  });
  final String id, name, deduplicationKey;
  final int amount;
  final DateTime grantedAt;

  factory RewardGrantNotice.fromJson(Map json) {
    final id = json['grantNoticeId'],
        name = json['name'],
        amount = json['amount'];
    final date = json['grantedAt'], key = json['deduplicationKey'];
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        amount is! int ||
        amount < 1 ||
        amount > 100 ||
        date is! String ||
        key is! String ||
        key.isEmpty ||
        json['presentation'] != 'GRANT_NOTICE' ||
        !['ADMIN_DIRECT', 'ADMIN_EVENT_BATCH'].contains(json['source'])) {
      throw const FormatException('Invalid grant notice');
    }
    final at = DateTime.tryParse(date);
    if (at == null || !at.isUtc) {
      throw const FormatException('Invalid grant time');
    }
    return RewardGrantNotice(
      id: id,
      name: name,
      amount: amount,
      grantedAt: at,
      deduplicationKey: key,
    );
  }

  String get grantedAtKst {
    final date = grantedAt.add(const Duration(hours: 9));
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}.${two(date.month)}.${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }
}

/// Session-scoped notice queue. Viewing is read-only; only explicit ACK removes.
class RewardGrantNotices extends ChangeNotifier {
  RewardGrantNotices(this._client);
  final ApiClient _client;
  final _queue = Queue<RewardGrantNotice>();
  final _ids = <String>{}, _keys = <String>{};
  String? _cursor;
  bool _started = false, _hasMore = false, _loading = false;
  bool _active = true;
  int _epoch = 0;
  int get epoch => _epoch;
  RewardGrantNotice? get current => _queue.isEmpty ? null : _queue.first;

  void reset() {
    _active = false;
    _epoch++;
    _queue.clear();
    _ids.clear();
    _keys.clear();
    _cursor = null;
    _started = _hasMore = _loading = false;
    notifyListeners();
  }

  void activate() => _active = true;

  Future<void> load({bool refresh = false}) async {
    if (!_active) return;
    if (_loading) return;
    if (refresh) {
      _cursor = null;
      _started = false;
    } else if (_queue.isNotEmpty || (_started && !_hasMore)) {
      return;
    }
    final epoch = _epoch;
    _loading = true;
    _started = true;
    try {
      var restarted = false;
      do {
        final requestedCursor = _cursor;
        Map<String, dynamic> json;
        try {
          final response = await _client.get<Map<String, dynamic>>(
            '/users/me/reward-grant-notices',
            queryParameters: {'limit': 20, 'cursor': ?requestedCursor},
          );
          if (epoch != _epoch) return;
          json = response.data!;
        } on ApiException catch (error) {
          if (epoch != _epoch) return;
          if (!restarted &&
              requestedCursor != null &&
              ((error.statusCode == 410 && error.code == 'CURSOR_EXPIRED') ||
                  (error.statusCode == 400 &&
                      error.code == 'INVALID_CURSOR'))) {
            restarted = true;
            _cursor = null;
            continue;
          }
          rethrow;
        }
        final items = json['items'], page = json['page'];
        if (items is! List || page is! Map || page['hasMore'] is! bool) {
          throw const FormatException('Invalid notice page');
        }
        final hasMore = page['hasMore'] as bool;
        final cursor = page['nextCursor'];
        if (hasMore &&
            (cursor is! String ||
                cursor.isEmpty ||
                cursor == requestedCursor)) {
          throw const FormatException('Invalid notice cursor');
        }
        // Parse the entire page before changing the queue.
        final parsed = items.map((item) {
          if (item is! Map) throw const FormatException('Invalid notice');
          return RewardGrantNotice.fromJson(item);
        }).toList();
        for (final notice in parsed) {
          if (_ids.contains(notice.id) ||
              _keys.contains(notice.deduplicationKey)) {
            continue;
          }
          _ids.add(notice.id);
          _keys.add(notice.deduplicationKey);
          _queue.add(notice);
        }
        _hasMore = hasMore;
        _cursor = hasMore ? cursor as String : null;
        // Continue through duplicate/empty pages without losing later notices.
      } while (_queue.isEmpty && _hasMore);
    } catch (_) {
      if (epoch == _epoch) {
        _hasMore = false;
        debugPrint('지급 안내 조회 실패: 다음 접속 시 다시 확인합니다.');
      }
    } finally {
      if (epoch == _epoch) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> acknowledge(RewardGrantNotice notice) async {
    final epoch = _epoch;
    if (current?.id != notice.id) throw StateError('Notice session changed');
    final response = await _client.post<Map<String, dynamic>>(
      '/users/me/reward-grant-notices/${Uri.encodeComponent(notice.id)}/acknowledgement',
    );
    if (epoch != _epoch) throw StateError('Notice session changed');
    final json = response.data;
    if (json == null ||
        json['grantNoticeId'] != notice.id ||
        json['acknowledged'] != true ||
        json['acknowledgedAt'] is! String ||
        DateTime.tryParse(json['acknowledgedAt'] as String) == null) {
      throw const FormatException('Unconfirmed acknowledgement');
    }
    _queue.removeWhere((item) => item.id == notice.id);
    notifyListeners();
  }
}
