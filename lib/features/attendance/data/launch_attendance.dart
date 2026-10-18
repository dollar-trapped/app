import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

/// All dates, eligibility, rewards and balances come from the server.
class AttendanceStatus {
  AttendanceStatus.fromJson(Map<String, dynamic> json)
    : eventId = json['eventId'] as String,
      serverDate = json['serverDate'] as String,
      enabled = json['enabled'] as bool,
      canClaim = json['canClaim'] as bool,
      claimedToday = json['claimedToday'] as bool,
      attendedDays = json['attendedDays'] as int,
      grantedAmount = json['grantedAmount'] as int,
      balance = json['drawEntitlementBalance'] as int,
      outcome = json['outcome'] as String?,
      rewards = List.unmodifiable(
        (json['rewards'] as List).map((raw) {
          final reward = raw as Map;
          if (reward['day'] is! int ||
              reward['claimed'] is! bool ||
              reward['amount'] is! int ||
              (reward['amount'] as int) < 0) {
            throw const FormatException('Invalid attendance reward');
          }
          return reward['amount'] as int;
        }),
      ) {
    if (eventId.isEmpty ||
        DateTime.tryParse(serverDate) == null ||
        attendedDays < 0 ||
        attendedDays > 7 ||
        grantedAmount < 0 ||
        balance < 0 ||
        rewards.length != 7 ||
        (grantedAmount > 0 &&
            (outcome != 'GRANTED' ||
                !claimedToday ||
                attendedDays == 0 ||
                grantedAmount != rewards[attendedDays - 1]))) {
      throw const FormatException('Invalid attendance status');
    }
  }

  final String eventId, serverDate;
  final bool enabled, canClaim, claimedToday;
  final int attendedDays, grantedAmount, balance;
  final String? outcome;
  final List<int> rewards;
}

/// Session-scoped. A failed check must never prevent access to the app.
class LaunchAttendance extends ChangeNotifier {
  LaunchAttendance(this._client);
  final ApiClient _client;
  int _epoch = 0;
  int get epoch => _epoch;
  bool _loading = false, _active = true;
  final _presented = <String>{};
  AttendanceStatus? _pending;
  AttendanceStatus? get pending => _pending;

  void reset() {
    _epoch++;
    _active = false;
    _loading = false;
    _pending = null;
    _presented.clear();
    notifyListeners();
  }

  void activate() => _active = true;

  AttendanceStatus? take() {
    final result = _pending;
    _pending = null;
    return result;
  }

  Future<void> check() async {
    if (!_active || _loading || _pending != null) return;
    final epoch = _epoch;
    _loading = true;
    try {
      var response = await _client.get<Map<String, dynamic>>(
        '/users/me/launch-attendance',
      );
      if (epoch != _epoch) return;
      var status = AttendanceStatus.fromJson(response.data!);
      debugPrint(
        '[Attendance] enabled=${status.enabled} canClaim=${status.canClaim} '
        'claimedToday=${status.claimedToday} attendedDays=${status.attendedDays}',
      );
      if (!status.enabled) return;
      // ENDED can still allow existing participants: use canClaim, not phase.
      if (status.canClaim) {
        response = await _client.post<Map<String, dynamic>>(
          '/users/me/launch-attendance/claims',
        );
        if (epoch != _epoch) return;
        status = AttendanceStatus.fromJson(response.data!);
        debugPrint(
          '[Attendance] outcome=${status.outcome} grantedAmount=${status.grantedAmount}',
        );
      }
      final key = '${status.eventId}:${status.serverDate}';
      if (status.enabled &&
          status.claimedToday &&
          status.attendedDays > 0 &&
          status.outcome == 'GRANTED' &&
          status.grantedAmount > 0 &&
          _presented.add(key)) {
        _pending = status;
      }
    } catch (error) {
      final reason = error is ApiException
          ? '${error.statusCode} ${error.code}'
          : error.runtimeType.toString();
      debugPrint('[Attendance] check failed: $reason');
    } finally {
      if (epoch == _epoch) {
        _loading = false;
        notifyListeners();
      }
    }
  }
}
