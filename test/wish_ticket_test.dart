import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';
import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/gacha/data/wish_ticket_models.dart';
import 'package:dollar_trapped/features/gacha/screens/wish_ticket_page.dart';
import 'package:dollar_trapped/features/gacha/services/pending_draw_store.dart';
import 'package:dollar_trapped/features/gacha/services/wish_ticket_operations.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

const gold = CosmeticItem(
  id: 'gold',
  type: 'NAME_COLOR',
  name: '황금빛',
  rarity: 'SPECIAL',
  drawable: true,
  appearance: {'styleToken': 'golden_shimmer'},
);
const owned = CosmeticItem(
  id: 'owned',
  type: 'NAME_COLOR',
  name: '보유 장식',
  rarity: 'SPECIAL',
  drawable: true,
  appearance: {'nameColor': '#4477CC'},
);

class Store implements PendingDrawStore {
  final saved = <String, String>{};
  bool failRead = false, failWrite = false, failClear = false;
  @override
  Future<String?> read(String userId) async {
    if (failRead) throw StateError('read');
    return saved[userId];
  }

  @override
  Future<void> write(String userId, String value) async {
    if (failWrite) throw StateError('write');
    saved[userId] = value;
  }

  @override
  Future<void> clear(String userId) async {
    if (failClear) throw StateError('clear');
    saved.remove(userId);
  }
}

class Repo extends MockDollarRepository {
  int chips = 100, tickets = 1, mutations = 0, calls = 0;
  bool enabled = true, unavailable = false, lost = false, acquired = false;
  String? failure;
  Completer<void>? gate;
  final receipts = <String, WishTicketReceipt>{};
  final selectedIds = <String>[];
  @override
  Future<WishTicketState> getWishTickets() async {
    if (unavailable) {
      throw const ApiException(
        statusCode: 404,
        code: 'NOT_FOUND',
        message: 'not found',
      );
    }
    return WishTicketState(
      enabled: enabled,
      chips: chips,
      tickets: tickets,
      options: [
        WishTicketOption(item: gold, owned: acquired),
        const WishTicketOption(item: owned, owned: true),
      ],
    );
  }

  Future<WishTicketReceipt> request(String id, String? cosmeticId) async {
    calls++;
    if (gate != null) await gate!.future;
    if (failure != null) {
      throw ApiException(
        statusCode: 409,
        code: failure!,
        message: '다시 선택해 주세요.',
        details: const [
          ApiErrorDetail(field: 'required', reason: '100'),
          ApiErrorDetail(field: 'balance', reason: '99'),
        ],
      );
    }
    if (cosmeticId != null) selectedIds.add(cosmeticId);
    final receipt = receipts.putIfAbsent(id, () {
      mutations++;
      if (cosmeticId == null) {
        chips -= 100;
        tickets++;
      } else {
        tickets--;
        acquired = true;
      }
      return WishTicketReceipt(
        operationId: id,
        chips: chips,
        tickets: tickets,
        item: cosmeticId == null ? null : gold,
      );
    });
    if (lost) {
      lost = false;
      throw StateError('lost response after commit');
    }
    return receipt;
  }

  @override
  Future<WishTicketReceipt> exchangeWishTicket(String operationId) =>
      request(operationId, null);
  @override
  Future<WishTicketReceipt> redeemWishTicket(
    String operationId,
    String cosmeticId,
  ) => request(operationId, cosmeticId);
}

void main() {
  test(
    'exchange recovers after restart without spending another 100 chips',
    () async {
      final repo = Repo()..lost = true;
      final store = Store();
      final first = WishTicketOperations(repo, store, 'account');
      await first.restore();
      await expectLater(first.execute(), throwsStateError);
      final id = first.pending!.id;
      expect(repo.chips, 0);
      final restored = WishTicketOperations(repo, store, 'account');
      await restored.restore();
      expect(restored.pending!.id, id);
      await restored.execute();
      expect(repo.mutations, 1);
      expect(repo.tickets, 2);
      expect(store.saved, isEmpty);
      final other = WishTicketOperations(repo, store, 'other-account');
      await other.restore();
      expect(other.pending, isNull);
    },
  );
  test(
    'redemption restores the selected item and operation, including cleanup failure',
    () async {
      final repo = Repo();
      final store = Store()..failClear = true;
      final first = WishTicketOperations(repo, store, 'a');
      await first.restore();
      await expectLater(first.execute(cosmeticId: 'gold'), throwsStateError);
      expect(repo.tickets, 0);
      store.failClear = false;
      final restored = WishTicketOperations(repo, store, 'a');
      await restored.restore();
      await restored.execute(cosmeticId: 'different-item');
      expect(repo.selectedIds, ['gold', 'gold']);
      expect(repo.mutations, 1);
    },
  );
  test(
    'failed persistence and concurrent invocation cannot submit twice',
    () async {
      final repo = Repo();
      final store = Store()..failWrite = true;
      final ops = WishTicketOperations(repo, store, 'a');
      await ops.restore();
      await expectLater(ops.execute(), throwsStateError);
      expect(repo.calls, 0);
      store.failWrite = false;
      repo.gate = Completer<void>();
      final first = ops.execute();
      await Future<void>.delayed(Duration.zero);
      await expectLater(ops.execute(), throwsStateError);
      expect(repo.calls, 1);
      repo.gate!.complete();
      await first;
    },
  );
  test(
    'definitive rejection clears selection; ambiguous failure retains it',
    () async {
      final repo = Repo()..failure = 'COSMETIC_ALREADY_OWNED';
      final store = Store();
      final ops = WishTicketOperations(repo, store, 'a');
      await ops.restore();
      await expectLater(
        ops.execute(cosmeticId: 'gold'),
        throwsA(isA<ApiException>()),
      );
      expect(ops.pending, isNull);
      expect(store.saved, isEmpty);
      repo.failure = 'INTERNAL_ERROR';
      await expectLater(
        ops.execute(cosmeticId: 'gold'),
        throwsA(isA<ApiException>()),
      );
      expect(ops.pending!.cosmeticId, 'gold');
    },
  );
  test('corrupt storage blocks new operations', () async {
    final store = Store()..saved['a'] = 'invalid';
    final repo = Repo();
    final ops = WishTicketOperations(repo, store, 'a');
    await expectLater(ops.restore(), throwsFormatException);
    await expectLater(ops.execute(), throwsStateError);
    expect(repo.calls, 0);
  });
  for (final code in [
    'INSUFFICIENT_DOLLAR_CHIP',
    'INSUFFICIENT_WISH_TICKET',
    'COSMETIC_ALREADY_OWNED',
    'COSMETIC_NOT_SELECTABLE',
    'WISH_TICKETS_DISABLED',
    'IDEMPOTENCY_CONFLICT',
    'VALIDATION_ERROR',
    'AUTH_REQUIRED',
    'INVALID_TOKEN',
    'TOKEN_EXPIRED',
    'ACCOUNT_DISABLED',
    'RATE_LIMITED',
    'SERVICE_UNAVAILABLE',
  ]) {
    test(
      'pending request handling for $code matches confirmed server guarantee',
      () async {
        final repo = Repo()..failure = code;
        final store = Store();
        final ops = WishTicketOperations(repo, store, 'account');
        await ops.restore();
        await expectLater(
          ops.execute(cosmeticId: 'gold'),
          throwsA(isA<ApiException>()),
        );
        final noCommit = const {
          'INSUFFICIENT_DOLLAR_CHIP',
          'INSUFFICIENT_WISH_TICKET',
          'COSMETIC_ALREADY_OWNED',
          'COSMETIC_NOT_SELECTABLE',
          'WISH_TICKETS_DISABLED',
        }.contains(code);
        expect(ops.pending == null, noCommit);
        expect(store.saved.isEmpty, noCommit);
        if (!noCommit) {
          expect(
            ops.pending!.id,
            matches(
              RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
              ),
            ),
          );
        }
      },
    );
  }
  Future<void> open(WidgetTester tester, Repo repo, {Store? store}) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: WishTicketPage(
          repository: repo,
          nickname: '달러',
          pendingStore: store ?? Store(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('unimplemented server disables exchange and redemption', (
    tester,
  ) async {
    final repo = Repo()..unavailable = true;
    await open(tester, repo);
    expect(find.textContaining('준비하고 있어요'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('wish-exchange')))
          .onPressed,
      isNull,
    );
    expect(repo.calls, 0);
  });
  testWidgets(
    'less than 100 chips disables exchange; owned items cannot be selected',
    (tester) async {
      final repo = Repo()..chips = 99;
      await open(tester, repo);
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('wish-exchange')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('wish-option-owned')),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'exchange cancel spends nothing and confirmation grants a ticket',
    (tester) async {
      final repo = Repo();
      await open(tester, repo);
      await tap(tester, find.byKey(const Key('wish-exchange')));
      await tap(tester, find.text('취소'));
      expect(repo.calls, 0);
      await tap(tester, find.byKey(const Key('wish-exchange')));
      await tap(tester, find.text('100개로 교환'));
      expect(repo.chips, 0);
      expect(repo.tickets, 2);
      expect(find.text('염원의 선택권 1장을 받았어요.'), findsOneWidget);
    },
  );
  testWidgets(
    'selection does not consume until confirmation and becomes owned',
    (tester) async {
      final repo = Repo();
      await open(tester, repo);
      await tap(tester, find.byKey(const ValueKey('wish-option-gold')));
      expect(repo.calls, 0);
      await tap(tester, find.text('선택권 1장으로 획득'));
      await tap(tester, find.text('취소'));
      expect(repo.calls, 0);
      await tap(tester, find.text('선택권 1장으로 획득'));
      await tap(tester, find.text('선택 확정'));
      expect(repo.tickets, 0);
      expect(find.text('염원이 이루어졌어요'), findsOneWidget);
      await tap(tester, find.text('확인'));
      expect(find.text('황금빛 · 보유 중'), findsOneWidget);
      expect(repo.mutations, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'replayed historical balances never replace current GET balances',
    (tester) async {
      final repo = Repo()..lost = true;
      await open(tester, repo);
      await tap(tester, find.byKey(const Key('wish-exchange')));
      await tap(tester, find.text('100개로 교환'));
      expect(repo.mutations, 1);
      // Other activity after the original receipt changes the live account.
      repo.chips = 70;
      repo.tickets = 0;
      await tap(tester, find.text('이전 결과 다시 확인'));
      expect(find.text('내 달러칩  70개'), findsOneWidget);
      expect(find.text('염원의 선택권  0장'), findsOneWidget);
      expect(repo.mutations, 1);
    },
  );
  testWidgets('numeric error details are not shown as form validation', (
    tester,
  ) async {
    final repo = Repo()..failure = 'INSUFFICIENT_DOLLAR_CHIP';
    await open(tester, repo);
    await tap(tester, find.byKey(const Key('wish-exchange')));
    await tap(tester, find.text('100개로 교환'));
    expect(find.text('달러칩이 부족해요. 교환하려면 100개가 필요해요.'), findsOneWidget);
    expect(find.textContaining('required:'), findsNothing);
    expect(find.text('이전 결과 다시 확인'), findsNothing);
  });
  testWidgets('large text and navigation insets fit on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.5),
            padding: const EdgeInsets.only(bottom: 48),
          ),
          child: child!,
        ),
        home: WishTicketPage(
          repository: Repo(),
          nickname: '달러물림',
          pendingStore: Store(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('선택권 1장으로 획득'));
    expect(tester.takeException(), isNull);
  });
}
