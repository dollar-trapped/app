import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/chat/widgets/rate_bar.dart';
import 'package:dollar_trapped/features/exchange/models/exchange_rate.dart';

ExchangeRate quote(String current, String? previous, {bool stale = false}) =>
    ExchangeRate(
      pair: 'USD-KRW',
      rate: current,
      previousCloseRate: previous,
      asOf: DateTime.utc(2026, 10, 2),
      fetchedAt: DateTime.utc(2026, 10, 2),
      source: 'test',
      marketStatus: 'OPEN',
      isStale: stale,
    );

void main() {
  for (final entry in [
    ('1346.09', '1354.40', '▼ 8.31 (-0.61%) · 전일 대비', const Color(0xFF2464C4)),
    ('1354.40', '1346.09', '▲ 8.31 (+0.62%) · 전일 대비', const Color(0xFFD63B3B)),
    ('1346.09', '1346.09', '— 0.00 (0.00%) · 전일 대비', const Color(0xFF667069)),
  ]) {
    testWidgets('displays comparison ${entry.$3}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RateBar(rateFuture: Future.value(quote(entry.$1, entry.$2))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('USD/KRW'), findsOneWidget);
      expect(find.text(entry.$3), findsOneWidget);
      expect(tester.widget<Text>(find.text(entry.$3)).style!.color, entry.$4);
    });
  }
  testWidgets('missing or invalid close never fabricates a comparison', (
    tester,
  ) async {
    for (final previous in [null, '0', 'invalid', 'NaN']) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RateBar(rateFuture: Future.value(quote('1356.66', previous))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1,356.66원'), findsOneWidget);
      expect(find.text('전일 대비 정보 없음'), findsOneWidget);
    }
  });
  testWidgets('stale quote keeps the last value visibly identified', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RateBar(
            rateFuture: Future.value(quote('1356.66', '1354.40', stale: true)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('마지막 확인값 · 전일 대비 정보 없음'), findsOneWidget);
  });
  testWidgets('narrow screen and large text fit without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: RateBar(rateFuture: Future.value(quote('1356.66', '1354.40'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
