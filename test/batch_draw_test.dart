import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:dollar_trapped/features/gacha/screens/batch_draw_result_page.dart';
import 'package:dollar_trapped/features/gacha/screens/live_gacha_page.dart';
import 'package:dollar_trapped/features/gacha/services/pending_draw_store.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(
    WidgetTester tester,
    _DrawRepo repo,
    _Store store, {
    _Store? single,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: LiveGachaPage(
          repository: repo,
          nickname: '달러',
          pendingDrawStore: single ?? _Store(),
          pendingBatchDrawStore: store,
          pendingExchangeStore: _Store(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> draw(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('equal buttons put ten on left and require ten tickets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = _DrawRepo(tickets: 9);
    await open(tester, repo, _Store());
    final ten = find.widgetWithText(FilledButton, '10회 뽑기');
    final one = find.widgetWithText(FilledButton, '1회 뽑기');
    expect(tester.widget<FilledButton>(ten).onPressed, isNull);
    expect(tester.widget<FilledButton>(one).onPressed, isNotNull);
    expect(tester.getSize(ten).width, tester.getSize(one).width);
    expect(tester.getRect(ten).left, lessThan(tester.getRect(one).left));
    expect(repo.requests, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ten draws make one batch request even with double taps', (
    tester,
  ) async {
    final repo = _DrawRepo(tickets: 10);
    final store = _Store();
    await open(tester, repo, store);
    await tester.ensureVisible(find.text('10회 뽑기'));
    final action = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, '10회 뽑기'))
        .onPressed!;
    action();
    action();
    await tester.pumpAndSettle();
    expect(repo.requests.length, 1);
    expect(repo.singleRequests, 0);
    expect(repo.tickets, 0);
    expect(store.pending, isNull);
    final page = tester.widget<BatchDrawResultPage>(
      find.byType(BatchDrawResultPage),
    );
    expect(page.results.length, 10);
    expect(find.text('새 아이템 5개 · 중복 5개'), findsOneWidget);
    expect(find.text('중복 보상 달러칩 5개'), findsOneWidget);
    await draw(tester, '확인');
    expect(find.text('0장'), findsOneWidget);
    expect(find.text('5개'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'lost response restores entire batch after restart without tickets',
    (tester) async {
      final repo = _DrawRepo(tickets: 10, loseResponse: true);
      final store = _Store();
      await open(tester, repo, store);
      await draw(tester, '10회 뽑기');
      expect(repo.requests.length, 1);
      expect(repo.tickets, 0);
      expect(store.pending, repo.requests.single);
      expect(find.byType(BatchDrawResultPage), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '1회 뽑기'))
            .onPressed,
        isNull,
      );
      final original = store.pending;
      await open(tester, repo, store);
      expect(find.text('0장'), findsOneWidget);
      await draw(tester, '10회 결과 다시 확인');
      expect(repo.requests, [original, original]);
      expect(repo.singleRequests, 0);
      expect(repo.tickets, 0);
      expect(store.pending, isNull);
      expect(
        tester
            .widget<BatchDrawResultPage>(find.byType(BatchDrawResultPage))
            .results
            .length,
        10,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed durable write never sends a batch', (tester) async {
    final repo = _DrawRepo(tickets: 10);
    await open(tester, repo, _Store(failWrite: true));
    await draw(tester, '10회 뽑기');
    expect(repo.requests, isEmpty);
    expect(repo.tickets, 10);
    expect(find.byType(BatchDrawResultPage), findsNothing);
    expect(find.text('10회 결과 다시 확인'), findsOneWidget);
  });

  testWidgets('incomplete response keeps key and never falls back to singles', (
    tester,
  ) async {
    final repo = _DrawRepo(tickets: 10, truncated: true);
    final store = _Store();
    await open(tester, repo, store);
    await draw(tester, '10회 뽑기');
    expect(repo.requests.length, 1);
    expect(repo.singleRequests, 0);
    expect(store.pending, isNotNull);
    expect(find.byType(BatchDrawResultPage), findsNothing);
    repo.truncated = false;
    await draw(tester, '10회 결과 다시 확인');
    expect(repo.requests[1], repo.requests[0]);
    expect(repo.tickets, 0);
    expect(
      tester
          .widget<BatchDrawResultPage>(find.byType(BatchDrawResultPage))
          .results
          .length,
      10,
    );
  });

  testWidgets('failed batch key read blocks both draw buttons', (tester) async {
    final repo = _DrawRepo(tickets: 20);
    await open(tester, repo, _Store(failRead: true));
    for (final label in ['10회 뽑기', '1회 뽑기']) {
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, label))
            .onPressed,
        isNull,
      );
    }
    expect(repo.requests, isEmpty);
  });

  testWidgets('legacy pending single draw blocks a new batch', (tester) async {
    final repo = _DrawRepo(tickets: 20);
    await open(
      tester,
      repo,
      _Store(),
      single: _Store()..pending = 'single-pending',
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '10회 뽑기'))
          .onPressed,
      isNull,
    );
    expect(find.text('뽑기 결과 다시 확인'), findsOneWidget);
    expect(repo.requests, isEmpty);
  });
}

class _Store implements PendingDrawStore {
  _Store({this.failWrite = false, this.failRead = false});
  final bool failWrite, failRead;
  String? pending;
  @override
  Future<String?> read(String userId) async {
    if (failRead) throw StateError('storage unavailable');
    return pending;
  }

  @override
  Future<void> write(String userId, String requestId) async {
    if (failWrite) throw StateError('storage unavailable');
    pending = requestId;
  }

  @override
  Future<void> clear(String userId) async => pending = null;
}

class _DrawRepo extends MockDollarRepository {
  _DrawRepo({
    required this.tickets,
    this.loseResponse = false,
    this.truncated = false,
  });
  int tickets, chips = 0, singleRequests = 0;
  bool loseResponse, truncated;
  final requests = <String>[];
  final _results = <String, CosmeticBatchDraw>{};
  @override
  Future<CosmeticInventory> getMyCosmetics() async => CosmeticInventory(
    items: const [],
    equipment: const CosmeticEquipment(version: 1),
    tickets: tickets,
    dollarChips: chips,
  );
  @override
  Future<CosmeticDraw> drawCosmetic(String requestId) async {
    singleRequests++;
    throw StateError('must not call single draw');
  }

  @override
  Future<CosmeticBatchDraw> drawCosmeticBatch(String requestId) async {
    requests.add(requestId);
    if (!_results.containsKey(requestId)) {
      final results = List.generate(10, (i) {
        final duplicate = i.isOdd;
        if (duplicate) chips++;
        return CosmeticDraw(
          item: const CosmeticItem(
            id: 'color',
            type: 'NAME_COLOR',
            name: '파랑',
            rarity: 'COMMON',
            drawable: true,
            appearance: {'nameColor': '#4477CC'},
          ),
          duplicate: duplicate,
          chipsGranted: duplicate ? 1 : 0,
          ticketsAfter: --tickets,
        );
      });
      _results[requestId] = CosmeticBatchDraw(
        requestId: requestId,
        count: 10,
        results: results,
        ticketsAfter: tickets,
        chipsAfter: chips,
      );
      if (loseResponse) {
        loseResponse = false;
        throw StateError('response lost after server committed');
      }
    }
    if (truncated) throw const FormatException('only 9 results received');
    return _results[requestId]!;
  }
}
