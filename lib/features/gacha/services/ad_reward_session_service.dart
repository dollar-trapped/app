import 'dart:convert';
import '../../../core/network/api_exception.dart';
import 'package:flutter/foundation.dart';
import '../../shared/data/dollar_repository.dart';
import '../data/cosmetic_models.dart';
import 'request_id.dart';

/// No client-side grant. Poll only a known session, with a bounded lifetime.
class AdRewardSessionService extends ChangeNotifier {
  AdRewardSessionService(
    this.repository, {
    this.delay = Future<void>.delayed,
    this.diagnosticsEnabled = const bool.fromEnvironment(
      'AD_REWARD_DIAGNOSTICS',
    ),
  });
  final bool diagnosticsEnabled;
  final List<String> _diagnostics = [];
  String get diagnosticText =>
      _diagnostics.isEmpty ? '아직 서버 요청 기록이 없습니다.' : _diagnostics.join('\n\n');

  void _record(
    String stage, {
    AdRewardSession? response,
    Object? error,
    int? attempt,
  }) {
    if (!diagnosticsEnabled || _disposed) return;
    // Allowlist only: never log tokens, customData, or arbitrary response bodies.
    final entry = jsonEncode({
      'timeUtc': DateTime.now().toUtc().toIso8601String(),
      'stage': stage,
      'attempt': ?attempt,
      if (response != null) ...{
        'sessionId': response.id,
        'status': response.status,
        'adEventExpiresAt': response.expiresAt.toUtc().toIso8601String(),
        'hasCustomData': response.customData.isNotEmpty,
      },
      if (error is ApiException) ...{
        'httpStatus': error.statusCode,
        'errorCode': error.code,
        'requestId': error.requestId,
      } else if (error != null)
        'errorType': error.runtimeType.toString(),
    });
    _diagnostics.add(entry);
    if (_diagnostics.length > 30) _diagnostics.removeAt(0);
    debugPrint('[AdReward] $entry');
    notifyListeners();
  }

  final DollarRepository repository;
  final Future<void> Function(Duration) delay;
  String? _requestId;
  AdRewardSession? session;
  bool busy = false, _disposed = false;
  Future<AdRewardSession?> create() async {
    if (busy || _disposed) return null;
    busy = true;
    notifyListeners();
    try {
      _requestId ??= newRequestId();
      _record('POST /ad-reward-sessions started');
      final result = await repository.createAdRewardSession(_requestId!);
      if (_disposed) return null;
      session = result;
      _record('create response', response: result);
      return result;
    } catch (error) {
      _record('create failed', error: error);
      rethrow;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  void abandon() {
    session = null;
    _requestId = null;
  }

  Future<bool> verify() async {
    if (busy || _disposed || session == null) return false;
    busy = true;
    notifyListeners();
    try {
      for (var attempt = 0; attempt < 10 && !_disposed; attempt++) {
        _record('GET session started', response: session, attempt: attempt + 1);
        final updated = await repository.getAdRewardSession(session!.id);
        if (_disposed) return false;
        session = updated;
        _record('verify response', response: updated, attempt: attempt + 1);
        if (updated.status == 'GRANTED') {
          abandon();
          return true;
        }
        if (updated.status == 'EXPIRED') {
          abandon();
          return false;
        }
        if (attempt < 9) await delay(const Duration(seconds: 2));
      }
      _record('polling ended without GRANTED', response: session);
      return false;
    } catch (error) {
      _record('verify failed', error: error);
      rethrow;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
