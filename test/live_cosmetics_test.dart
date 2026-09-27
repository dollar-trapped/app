import 'dart:async';
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
  for (final fail in [false, true]) {
    testWidgets(
      'draw animates while server is pending and handles ${fail ? "failure" : "success"}',
      (tester) async {
        final repo = _DelayedRepo();
        final pending = _MemoryPending();
        await tester.pumpWidget(
          MaterialApp(
            home: LiveGachaPage(
              pendingExchangeStore: _MemoryPending(),
              repository: repo,
              nickname: '닉네임',
              pendingDrawStore: pending,
            ),
          ),
        );
        await _settleAndOpenCard(tester);
        await tester.ensureVisible(find.text('1회 뽑기'));
        await tester.tap(find.text('1회 뽑기'));
        await tester.pump();
        expect(find.byKey(const Key('gacha-draw-pending')), findsOneWidget);
        expect(find.text('어떤 취향을 만나게 될까요?'), findsOneWidget);
        expect(find.text('연출 건너뛰기'), findsNothing);
        await tester.pump(const Duration(seconds: 5));
        expect(find.byKey(const Key('gacha-draw-pending')), findsOneWidget);
        expect(repo.keys, hasLength(1));
        if (fail) {
          repo.response.completeError(StateError('timeout'));
        } else {
          repo.response.complete(
            const CosmeticDraw(
              item: item,
              duplicate: false,
              chipsGranted: 0,
              ticketsAfter: 0,
            ),
          );
        }
        await _settleAndOpenCard(tester);
        expect(find.byKey(const Key('gacha-draw-pending')), findsNothing);
        if (fail) {
          expect(find.text('뽑기 결과 다시 확인'), findsOneWidget);
          expect(await pending.read('user-me'), repo.keys.single);
        } else {
          expect(find.byType(LiveDrawResultPage), findsOneWidget);
          expect(await pending.read('user-me'), isNull);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'draw again spends one ticket with a new request and stops at zero',
    (tester) async {
      final repo = _RepeatRepo();
      await tester.pumpWidget(
        MaterialApp(
          home: LiveGachaPage(
            pendingExchangeStore: _MemoryPending(),
            repository: repo,
            nickname: '닉네임',
            pendingDrawStore: _MemoryPending(),
          ),
        ),
      );
      await _settleAndOpenCard(tester);
      await tester.ensureVisible(find.text('1회 뽑기'));
      await tester.tap(find.text('1회 뽑기'));
      await _settleAndOpenCard(tester);
      expect(find.text('남은 뽑기권 1장 · 1장 사용'), findsOneWidget);
      await tester.ensureVisible(find.text('다시 뽑기'));
      await tester.tap(find.text('다시 뽑기'));
      await _settleAndOpenCard(tester);
      expect(repo.keys, hasLength(2));
      expect(repo.keys.toSet(), hasLength(2));
      expect(repo.tickets, 0);
      expect(find.byType(LiveDrawResultPage), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '다시 뽑기'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('failed repeat draw reuses its pending request on retry', (
    tester,
  ) async {
    final repo = _RepeatRepo()..failSecond = true;
    final pending = _MemoryPending();
    await tester.pumpWidget(
      MaterialApp(
        home: LiveGachaPage(
          pendingExchangeStore: _MemoryPending(),
          repository: repo,
          nickname: '닉네임',
          pendingDrawStore: pending,
        ),
      ),
    );
    await _settleAndOpenCard(tester);
    await tester.ensureVisible(find.text('1회 뽑기'));
    await tester.tap(find.text('1회 뽑기'));
    await _settleAndOpenCard(tester);
    await tester.ensureVisible(find.text('다시 뽑기'));
    await tester.tap(find.text('다시 뽑기'));
    await _settleAndOpenCard(tester);
    expect(repo.tickets, 1);
    expect(await pending.read('user-me'), repo.keys.last);
    await tester.ensureVisible(find.text('뽑기 결과 다시 확인'));
    await tester.tap(find.text('뽑기 결과 다시 확인'));
    await _settleAndOpenCard(tester);
    expect(repo.keys, hasLength(3));
    expect(repo.keys[0], isNot(repo.keys[1]));
    expect(repo.keys[1], repo.keys[2]);
    expect(repo.tickets, 0);
    expect(await pending.read('user-me'), isNull);
  });

  testWidgets(
    'apply preserves other equipped slots and explains new-message styling',
    (tester) async {
      final repo = _Repo();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LiveDrawResultPage(
                      repository: repo,
                      nickname: '닉네임',
                      result: const CosmeticDraw(
                        item: item,
                        duplicate: false,
                        chipsGranted: 0,
                        ticketsAfter: 0,
                      ),
                    ),
                  ),
                ),
                child: const Text('결과 열기'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('결과 열기'));
      await _settleAndOpenCard(tester);
      await tester.ensureVisible(find.text('지금 적용'));
      await tester.tap(find.text('지금 적용'));
      await _settleAndOpenCard(tester);
      expect(repo.saved!.colorId, item.id);
      expect(repo.saved!.fontId, 'font-existing');
      expect(repo.saved!.backgroundId, 'bg-existing');
      expect(repo.saved!.version, 7);
      expect(find.text('장식을 적용했어요. 새로 보내는 채팅부터 반영돼요.'), findsOneWidget);
    },
  );

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
            pendingExchangeStore: _MemoryPending(),
            repository: repo,
            nickname: '닉네임',
            pendingDrawStore: pending,
          ),
        ),
      );
      await _settleAndOpenCard(tester);
      await tester.ensureVisible(find.text('뽑기 결과 다시 확인'));
      await tester.tap(find.text('뽑기 결과 다시 확인'));
      await _settleAndOpenCard(tester);
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
            pendingExchangeStore: _MemoryPending(),
            repository: repo,
            nickname: '닉네임',
            pendingDrawStore: _MemoryPending(),
          ),
        ),
      );
      await _settleAndOpenCard(tester);
      expect(find.text('1장'), findsOneWidget);
      await tester.ensureVisible(find.text('1회 뽑기'));
      await tester.tap(find.text('1회 뽑기'));
      await _settleAndOpenCard(tester);
      expect(find.text('1장'), findsOneWidget);
      await tester.ensureVisible(find.text('뽑기 결과 다시 확인'));
      await tester.tap(find.text('뽑기 결과 다시 확인'));
      await _settleAndOpenCard(tester);
      expect(repo.keys, hasLength(2));
      expect(repo.keys[0], repo.keys[1]);
      expect(find.text('중복 보상으로 달러칩 1개를 받았어요.'), findsOneWidget);
      await tester.ensureVisible(find.text('‹').last);
      await tester.tap(find.text('‹').last);
      await _settleAndOpenCard(tester);
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
      await _settleAndOpenCard(tester);
      await tester.tap(find.text('모두 해제'));
      await tester.pump();
      await tester.ensureVisible(find.text('기본 모습으로 적용'));
      await tester.tap(find.text('기본 모습으로 적용'));
      await _settleAndOpenCard(tester);
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
        pendingExchangeStore: _MemoryPending(),
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
      await _settleAndOpenCard(tester);
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
      equipment: const CosmeticEquipment(
        colorId: 'color-1',
        fontId: 'font-existing',
        backgroundId: 'bg-existing',
        version: 7,
      ),
      tickets: tickets,
      dollarChips: 0,
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
      chipsGranted: 1,
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

class _RepeatRepo extends _Repo {
  _RepeatRepo() {
    tickets = 2;
  }
  bool failSecond = false;
  @override
  Future<CosmeticDraw> drawCosmetic(String key) async {
    keys.add(key);
    if (failSecond && keys.length == 2) throw StateError('timeout');
    tickets--;
    return CosmeticDraw(
      item: item,
      duplicate: false,
      chipsGranted: 0,
      ticketsAfter: tickets,
    );
  }
}

class _DelayedRepo extends _Repo {
  final response = Completer<CosmeticDraw>();
  @override
  Future<CosmeticDraw> drawCosmetic(String key) {
    keys.add(key);
    return response.future;
  }
}

Future<void> _settleAndOpenCard(WidgetTester tester) async {
  await tester.pumpAndSettle();
  if (find.text('카드를 터치해서 열어보세요').evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('gacha-card-touch')));
    await tester.pumpAndSettle();
  }
}
