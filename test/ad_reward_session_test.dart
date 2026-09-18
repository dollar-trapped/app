import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/data/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/services/ad_reward_session_service.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
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
    return session;
  }
}
