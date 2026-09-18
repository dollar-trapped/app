import 'package:dollar_trapped/features/gacha/services/pending_draw_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/data/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/screens/live_gacha_page.dart';
import 'package:dollar_trapped/features/gacha/screens/owned_cosmetics_page.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';

const item = CosmeticItem(
  id: 'color-1',
  type: 'NAME_COLOR',
  name: '파랑',
  rarity: 'COMMON',
  appearance: {'nameColor': '#4477CC'},
);
void main() {
  testWidgets(
    'a stored draw request can be recovered after reopening with zero tickets',
    (tester) async {
      final repo = _Repo()..tickets = 0;
      repo.keys.add('existing-key');
      final pending = _MemoryPending();
      await pending.write('user-me', 'existing-key');
      await tester.pumpWidget(
        MaterialApp(
          home: LiveGachaPage(
            repository: repo,
            nickname: '닉네임',
            pendingDrawStore: pending,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('뽑기 결과 다시 확인'));
      await tester.tap(find.text('뽑기 결과 다시 확인'));
      await tester.pumpAndSettle();
      expect(repo.keys.last, 'existing-key');
      expect(await pending.read('user-me'), isNull);
      expect(find.byType(LiveDrawResultPage), findsOneWidget);
    },
  );

  testWidgets(
    'draw retry preserves request ID and shows server duplicate reward',
    (tester) async {
      final repo = _Repo();
      await tester.pumpWidget(
        MaterialApp(
          home: LiveGachaPage(
            repository: repo,
            nickname: '닉네임',
            pendingDrawStore: _MemoryPending(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1장'), findsOneWidget);
      await tester.ensureVisible(find.text('1회 뽑기'));
      await tester.tap(find.text('1회 뽑기'));
      await tester.pumpAndSettle();
      expect(find.text('1장'), findsOneWidget);
      await tester.ensureVisible(find.text('뽑기 결과 다시 확인'));
      await tester.tap(find.text('뽑기 결과 다시 확인'));
      await tester.pumpAndSettle();
      expect(repo.keys, hasLength(2));
      expect(repo.keys[0], repo.keys[1]);
      expect(find.text('중복 보상으로 설정 토큰 1개를 받았어요.'), findsOneWidget);
      await tester.ensureVisible(find.text('보관만 하기'));
      await tester.tap(find.text('보관만 하기'));
      await tester.pumpAndSettle();
      expect(find.text('0장'), findsOneWidget);
      expect(repo.saved, isNull);
    },
  );
  testWidgets(
    'clear all sends explicit null slots with server version; conflict reloads',
    (tester) async {
      final repo = _Repo()..conflict = true;
      await tester.pumpWidget(
        MaterialApp(
          home: OwnedCosmeticsPage(repository: repo, nickname: '닉네임'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('모두 해제'));
      await tester.pump();
      await tester.ensureVisible(find.text('기본 모습으로 적용'));
      await tester.tap(find.text('기본 모습으로 적용'));
      await tester.pumpAndSettle();
      expect(repo.saved!.version, 7);
      expect(repo.saved!.colorId, isNull);
      expect(repo.saved!.fontId, isNull);
      expect(repo.saved!.backgroundId, isNull);
      expect(repo.loads, 2);
      expect(find.textContaining('최신 상태를 불러왔어요'), findsOneWidget);
    },
  );
  testWidgets('live screens fit narrow screens and large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo();
    for (final page in <Widget>[
      LiveGachaPage(
        repository: repo,
        nickname: '아주긴닉네임을사용해요',
        pendingDrawStore: _MemoryPending(),
      ),
      OwnedCosmeticsPage(repository: repo, nickname: '아주긴닉네임을사용해요'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: page,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}

class _Repo extends MockDollarRepository {
  int tickets = 1, loads = 0;
  bool conflict = false;
  CosmeticEquipment? saved;
  final keys = <String>[];
  @override
  Future<CosmeticInventory> getMyCosmetics() async {
    loads++;
    return CosmeticInventory(
      items: [item],
      equipment: const CosmeticEquipment(colorId: 'color-1', version: 7),
      tickets: tickets,
      settingTokens: 0,
    );
  }

  @override
  Future<CosmeticDraw> drawCosmetic(String key) async {
    keys.add(key);
    if (keys.length == 1) throw StateError('timeout');
    tickets = 0;
    return const CosmeticDraw(
      item: item,
      duplicate: true,
      tokensGranted: 1,
      ticketsAfter: 0,
    );
  }

  @override
  Future<CosmeticEquipment> equipCosmetics(CosmeticEquipment equipment) async {
    saved = equipment;
    if (conflict) {
      throw const ApiException(
        statusCode: 409,
        code: 'VERSION_CONFLICT',
        message: 'conflict',
      );
    }
    return equipment;
  }
}

class _MemoryPending implements PendingDrawStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String userId) async => values[userId];
  @override
  Future<void> write(String userId, String requestId) async {
    values[userId] = requestId;
  }

  @override
  Future<void> clear(String userId) async {
    values.remove(userId);
  }
}
