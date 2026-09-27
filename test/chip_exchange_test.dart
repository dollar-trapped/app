import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/gacha/data/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/screens/live_gacha_page.dart';
import 'package:dollar_trapped/features/gacha/services/pending_draw_store.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

class _Store implements PendingDrawStore {
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

class _Repo extends MockDollarRepository {
  int chips = 32, tickets = 0;
  bool timeout = false;
  final keys = <String>[];
  final results = <String, ChipExchange>{};
  @override
  Future<CosmeticInventory> getMyCosmetics() async => CosmeticInventory(
    items: [],
    equipment: const CosmeticEquipment(version: 0),
    tickets: tickets,
    dollarChips: chips,
  );
  @override
  Future<ChipExchange> exchangeChips(String key) async {
    keys.add(key);
    final result = results.putIfAbsent(key, () {
      chips -= 10;
      tickets++;
      return ChipExchange(chipsAfter: chips, ticketsAfter: tickets);
    });
    if (timeout) {
      timeout = false;
      throw StateError('response lost');
    }
    return result;
  }
}

void main() {
  testWidgets(
    '32 chips exchanges once and ambiguous retry reuses persisted key',
    (tester) async {
      final repo = _Repo()..timeout = true;
      final store = _Store();
      Widget app() => MaterialApp(
        home: LiveGachaPage(
          repository: repo,
          nickname: '나',
          pendingDrawStore: _Store(),
          pendingExchangeStore: store,
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('exchange-dollar-chips')),
      );
      await tester.tap(find.byKey(const Key('exchange-dollar-chips')));
      await tester.pumpAndSettle();
      expect(repo.chips, 22);
      expect(store.values, isNotEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('교환 결과 다시 확인'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('exchange-dollar-chips')),
      );
      await tester.tap(find.byKey(const Key('exchange-dollar-chips')));
      await tester.pumpAndSettle();
      expect(repo.keys[0], repo.keys[1]);
      expect(repo.chips, 22);
      expect(repo.tickets, 1);
      expect(find.text('22개'), findsOneWidget);
      expect(find.text('1장'), findsOneWidget);
      expect(store.values, isEmpty);
    },
  );
  testWidgets('less than ten chips disables exchange', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LiveGachaPage(
          repository: _Repo()..chips = 9,
          nickname: '나',
          pendingDrawStore: _Store(),
          pendingExchangeStore: _Store(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('exchange-dollar-chips')),
          )
          .onPressed,
      isNull,
    );
  });
}
