import 'dart:async';

import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:dollar_trapped/core/theme/app_theme.dart';
import 'package:dollar_trapped/features/chat/widgets/chat_message_bubble.dart';
import 'package:dollar_trapped/features/chat/widgets/message_list.dart';
import 'package:dollar_trapped/features/chat/widgets/rate_bar.dart';
import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:dollar_trapped/features/exchange/widgets/exchange_quote.dart';
import 'package:dollar_trapped/features/exchange/widgets/history_chart.dart';
import 'package:dollar_trapped/features/gacha/data/wish_ticket_models.dart';
import 'package:dollar_trapped/features/gacha/screens/live_gacha_page.dart';
import 'package:dollar_trapped/features/gacha/screens/wish_ticket_page.dart';
import 'package:dollar_trapped/features/inventory/screens/owned_cosmetics_page.dart';
import 'package:dollar_trapped/features/profile/screens/blocked_users_page.dart';
import 'package:dollar_trapped/features/profile/screens/my_page.dart';
import 'package:dollar_trapped/features/profile/screens/profile_edit_page.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:dollar_trapped/features/shared/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(
  Widget child, {
  bool dark = false,
  bool reducedMotion = true,
  double textScale = 1,
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reducedMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: child,
);

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  testWidgets('one accessible loading label replaces placeholder semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const Skeleton(label: '정보 불러오는 중', child: Text('자리 표시자'))),
    );
    expect(find.bySemanticsLabel('정보 불러오는 중'), findsOneWidget);
    expect(find.bySemanticsLabel('자리 표시자'), findsNothing);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('animation respects motion setting, hidden pages, and disposal', (
    tester,
  ) async {
    Widget content({bool ticker = true, bool active = true}) => TickerMode(
      enabled: ticker,
      child: Skeleton(
        active: active,
        label: '정보 불러오는 중',
        child: const SkeletonBox(width: 100, height: 20),
      ),
    );
    await tester.pumpWidget(_app(content(), reducedMotion: false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(_app(content(ticker: false), reducedMotion: false));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(_app(content(), reducedMotion: false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(_app(content(), reducedMotion: true));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(_app(content(active: false), reducedMotion: false));
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'placeholder colors follow the theme and text height follows text size',
    (tester) async {
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          _app(
            const Scaffold(body: SkeletonLine(width: 100, height: 20)),
            dark: dark,
            textScale: 1.5,
          ),
        );
        await tester.pumpAndSettle();
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(SkeletonBox),
            matching: find.byType(Container),
          ),
        );
        final colors = dark ? AppColors.dark : AppColors.light;
        expect(
          (container.decoration! as BoxDecoration).color,
          Color.lerp(colors.surface, colors.line, .65),
        );
        expect(tester.getSize(find.byType(SkeletonBox)).height, 30);
      }
    },
  );

  final pages = <String, Widget Function(_PendingRepository)>{
    'profile': (repo) => MyPage(repository: repo, onBack: () {}),
    'nickname editor': (repo) =>
        ProfileEditPage(repository: repo, section: ProfileEditSection.nickname),
    'position editor': (repo) =>
        ProfileEditPage(repository: repo, section: ProfileEditSection.position),
    'blocked users': (repo) => BlockedUsersPage(repository: repo),
    'gacha': (repo) => LiveGachaPage(repository: repo, nickname: '초록달러'),
    'wish tickets': (repo) =>
        WishTicketPage(repository: repo, nickname: '초록달러'),
    'inventory': (repo) => OwnedCosmeticsPage(
      repository: repo,
      nickname: '초록달러',
      onOpenGacha: (_) async {},
    ),
  };
  for (final entry in pages.entries) {
    testWidgets(
      '${entry.key} shows initial placeholders then actual data in both themes',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final dark in [false, true]) {
          final repo = _PendingRepository();
          await tester.pumpWidget(
            _app(entry.value(repo), dark: dark, textScale: 1.5),
          );
          await tester.pump();
          expect(find.byType(Skeleton), findsWidgets);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.text('아직 모은 글자색이 없어요.'), findsNothing);
          expect(find.text('차단한 사용자가 없습니다.'), findsNothing);
          if (entry.key == 'gacha') {
            expect(
              tester
                  .widget<FilledButton>(
                    find.widgetWithText(FilledButton, '1회 뽑기'),
                  )
                  .onPressed,
              isNull,
            );
            expect(find.byKey(const Key('gacha-ticket-balance')), findsNothing);
          }
          expect(tester.takeException(), isNull);
          await repo.complete();
          await tester.pumpAndSettle();
          final active = tester
              .widgetList<Skeleton>(find.byType(Skeleton))
              .where((widget) => widget.active);
          expect(active, isEmpty);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );
  }

  testWidgets('failed profile read exits loading and retry can recover', (
    tester,
  ) async {
    final repo = _PendingRepository();
    await tester.pumpWidget(_app(MyPage(repository: repo, onBack: () {})));
    repo.user.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.byType(Skeleton), findsNothing);
    expect(find.textContaining('내 정보를 불러오지 못했어요.'), findsOneWidget);
    repo.user = Completer<User>();
    await tester.tap(find.textContaining('다시 시도'));
    await tester.pump();
    expect(find.byType(Skeleton), findsWidgets);
    await repo.complete();
    await tester.pumpAndSettle();
    expect(find.text('초록달러'), findsOneWidget);
  });

  testWidgets(
    'failed inventory read ends profile placeholders without hiding account data',
    (tester) async {
      final repo = _PendingRepository();
      await tester.pumpWidget(_app(MyPage(repository: repo, onBack: () {})));
      repo.user.complete(await MockDollarRepository().getMe());
      await tester.pump();
      expect(find.text('초록달러'), findsOneWidget);
      expect(find.byType(Skeleton), findsWidgets);
      repo.inventory.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);
      expect(find.text('초록달러'), findsOneWidget);
      expect(find.text('달러칩 —'), findsOneWidget);
    },
  );

  testWidgets('quote and rate bar keep existing values during refresh', (
    tester,
  ) async {
    final quote = await MockDollarRepository().getUsdKrwRate();
    for (final compact in [false, true]) {
      final first = Completer<ExchangeRate>();
      Widget page(Future<ExchangeRate> future) => _app(
        Scaffold(
          body: compact
              ? RateBar(rateFuture: future)
              : ExchangeQuote(rateFuture: future, onRetry: () {}),
        ),
      );
      await tester.pumpWidget(page(first.future));
      expect(find.byType(Skeleton), findsOneWidget);
      first.complete(quote);
      await tester.pumpAndSettle();
      expect(find.text('1,346.09원'), findsOneWidget);
      final refresh = Completer<ExchangeRate>();
      await tester.pumpWidget(page(refresh.future));
      await tester.pump();
      expect(find.byType(Skeleton), findsNothing);
      expect(find.text('1,346.09원'), findsOneWidget);
      refresh.complete(quote);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
    'chart keeps loaded history during refresh and exits placeholders on errors',
    (tester) async {
      final history = await MockDollarRepository().getUsdKrwHistory('1M');
      final first = Completer<ExchangeRateHistory>();
      Widget page(Future<ExchangeRateHistory> future) => _app(
        Scaffold(
          body: HistoryChartSection(future: future, onRetry: () {}),
        ),
      );
      await tester.pumpWidget(page(first.future));
      expect(find.byType(Skeleton), findsOneWidget);
      first.complete(history);
      await tester.pumpAndSettle();
      final chart = find.byKey(const Key('exchange-rate-history-chart'));
      expect(chart, findsOneWidget);
      final refresh = Completer<ExchangeRateHistory>();
      await tester.pumpWidget(page(refresh.future));
      await tester.pump();
      expect(chart, findsOneWidget);
      expect(find.byType(Skeleton), findsNothing);
      refresh.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('차트 다시 시도'), findsOneWidget);
      expect(find.byType(Skeleton), findsNothing);
    },
  );

  testWidgets(
    'chat retains history while refreshing instead of replacing it with placeholders',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final first = Completer<MessagePage>();
      Widget page(Future<MessagePage> future) => _app(
        Scaffold(
          body: MessageList(
            future: future,
            realtimeMessages: const [],
            blockedUserIds: const {},
            currentUserId: 'user-me',
            scrollController: scroll,
            onRetry: () {},
            onModerate:
                ({
                  required String messageId,
                  required String authorId,
                }) async {},
          ),
        ),
      );
      await tester.pumpWidget(page(first.future));
      expect(find.byType(Skeleton), findsOneWidget);
      first.complete(await MockDollarRepository().getMessages());
      await tester.pumpAndSettle();
      expect(find.byType(ChatMessageBubble), findsWidgets);
      final refresh = Completer<MessagePage>();
      await tester.pumpWidget(page(refresh.future));
      await tester.pump();
      expect(find.byType(ChatMessageBubble), findsWidgets);
      expect(find.byType(Skeleton), findsNothing);
      refresh.complete(await MockDollarRepository().getMessages());
      await tester.pumpAndSettle();
    },
  );
}

class _PendingRepository extends MockDollarRepository {
  var user = Completer<User>();
  final inventory = Completer<CosmeticInventory>();
  final rate = Completer<ExchangeRate>();
  final blocked = Completer<List<BlockedUser>>();
  final wish = Completer<WishTicketState>();

  @override
  Future<User> getMe() => user.future;
  @override
  Future<CosmeticInventory> getMyCosmetics() => inventory.future;
  @override
  Future<ExchangeRate> getUsdKrwRate() => rate.future;
  @override
  Future<List<BlockedUser>> getBlockedUsers() => blocked.future;
  @override
  Future<WishTicketState> getWishTickets() => wish.future;

  Future<void> complete() async {
    if (!user.isCompleted) user.complete(await super.getMe());
    if (!inventory.isCompleted) {
      inventory.complete(await super.getMyCosmetics());
    }
    if (!rate.isCompleted) rate.complete(await super.getUsdKrwRate());
    if (!blocked.isCompleted) blocked.complete(await super.getBlockedUsers());
    if (!wish.isCompleted) wish.complete(await super.getWishTickets());
  }
}
