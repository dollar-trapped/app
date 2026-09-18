import 'package:flutter/foundation.dart';
import '../../shared/data/dollar_repository.dart';
import '../data/cosmetic_models.dart';
import 'request_id.dart';

/// No client-side grant. Poll only a known session, with a bounded lifetime.
class AdRewardSessionService extends ChangeNotifier {
  AdRewardSessionService(this.repository, {this.delay = Future<void>.delayed});
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
      final result = await repository.createAdRewardSession(_requestId!);
      if (_disposed) return null;
      session = result;
      return result;
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
        final updated = await repository.getAdRewardSession(session!.id);
        if (_disposed) return false;
        session = updated;
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
      return false;
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
