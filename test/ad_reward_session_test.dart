import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';
import 'package:dollar_trapped/features/gacha/services/ad_reward_session_service.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
  test(
    'diagnostics preserve final response without exposing customData',
    () async {
      final repo = _Repo();
      final service = AdRewardSessionService(
        repo,
        diagnosticsEnabled: true,
        delay: (_) async {},
      );
      await service.create();
      await service.verify();
      await service.verify();
      expect(service.diagnosticText.split('\n\n').length, 30);
      expect(service.diagnosticText, contains('PENDING'));
      expect(service.diagnosticText, isNot(contains('signed-data')));
      repo.status = 'GRANTED';
      expect(await service.verify(), isTrue);
      expect(service.session, isNull);
      expect(service.diagnosticText, contains('GRANTED'));
      service.dispose();
    },
  );
  test(
    'diagnostics record API status and code, not arbitrary error bodies',
    () async {
      final repo = _Repo()..failRead = true;
      final service = AdRewardSessionService(repo, diagnosticsEnabled: true);
      await service.create();
      await expectLater(service.verify(), throwsA(isA<ApiException>()));
      expect(service.diagnosticText, contains('503'));
      expect(service.diagnosticText, contains('REWARD_UNAVAILABLE'));
      expect(service.diagnosticText, isNot(contains('private-body')));
      expect(service.busy, isFalse);
      service.dispose();
    },
  );
  test('diagnostics stay off by default', () async {
    final service = AdRewardSessionService(_Repo());
    await service.create();
    expect(service.diagnosticText, '아직 서버 요청 기록이 없습니다.');
    service.dispose();
  });
  test('ambiguous session creation retries use the same key', () async {
    final repo = _Repo()..failCreate = true;
    final service = AdRewardSessionService(repo);
    await expectLater(service.create(), throwsStateError);
    repo.failCreate = false;
    await service.create();
    expect(repo.keys[0], repo.keys[1]);
    service.dispose();
  });
  test(
    'pending never grants; polling is bounded and can later observe GRANTED',
    () async {
      final repo = _Repo();
      final service = AdRewardSessionService(repo, delay: (_) async {});
      await service.create();
      expect(await service.verify(), isFalse);
      expect(repo.reads, 10);
      expect(service.session, isNotNull);
      repo.status = 'GRANTED';
      expect(await service.verify(), isTrue);
      expect(service.session, isNull);
      service.dispose();
    },
  );
  test('expired session clears; disposal stops polling', () async {
    final repo = _Repo()..status = 'EXPIRED';
    final service = AdRewardSessionService(repo, delay: (_) async {});
    await service.create();
    expect(await service.verify(), isFalse);
    expect(service.session, isNull);
    await service.create();
    service.dispose();
    expect(await service.verify(), isFalse);
    expect(repo.reads, 1);
  });
}

class _Repo extends MockDollarRepository {
  final keys = <String>[];
  bool failCreate = false;
  bool failRead = false;
  int reads = 0;
  String status = 'PENDING';
  AdRewardSession get session => AdRewardSession(
    id: 'session',
    status: status,
    customData: 'signed-data',
    expiresAt: DateTime.utc(2099),
  );
  @override
  Future<AdRewardSession> createAdRewardSession(String requestId) async {
    keys.add(requestId);
    if (failCreate) throw StateError('timeout');
    return session;
  }

  @override
  Future<AdRewardSession> getAdRewardSession(String id) async {
    reads++;
    if (failRead) {
      throw const ApiException(
        statusCode: 503,
        code: 'REWARD_UNAVAILABLE',
        message: 'private-body',
      );
    }
    return session;
  }
}
