import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/exchange/widgets/history_chart.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';

ExchangeRateHistory history(List<(int, String)> samples) => ExchangeRateHistory(
  pair: 'USD-KRW',
  range: '1D',
  interval: '10m',
  from: DateTime.utc(2026, 10, 3),
  to: DateTime.utc(2026, 10, 4),
  isPartial: false,
  points: samples
      .map(
        (sample) => ExchangeRatePoint(
          time: DateTime.utc(2026, 10, 3, 0, sample.$1),
          asOf: DateTime.utc(2026, 10, 3, 0, sample.$1),
          rate: sample.$2,
          source: 'test',
        ),
      )
      .toList(),
);

Future<void> showChart(WidgetTester tester, ExchangeRateHistory data) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: HistoryChartSection(
            future: Future.value(data),
            onRetry: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'tap selects nearest timestamp rather than index and formats Korean time',
    (tester) async {
      await showChart(
        tester,
        history([(60, '1342.50'), (0, '1340'), (10, '1341.20')]),
      );
      final rect = tester.getRect(
        find.byKey(const Key('exchange-rate-history-chart')),
      );
      await tester.tapAt(
        Offset(rect.left + (rect.width - 48) * 0.2, rect.center.dy),
      );
      await tester.pump();
      expect(find.text('2026.10.03 09:10 한국 시간 · 1,341.20원'), findsOneWidget);
      await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
      await tester.pump();
      expect(find.text('2026.10.03 10:00 한국 시간 · 1,342.50원'), findsOneWidget);
    },
  );

  testWidgets('long press scrubs and clamps at chart ends', (tester) async {
    await showChart(tester, history([(0, '1340'), (30, '1341'), (60, '1342')]));
    final rect = tester.getRect(
      find.byKey(const Key('exchange-rate-history-chart')),
    );
    final gesture = await tester.startGesture(
      Offset(rect.left + 10, rect.center.dy),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(Offset(rect.right + 40, rect.center.dy));
    await tester.pump();
    expect(find.text('2026.10.03 10:00 한국 시간 · 1,342.00원'), findsOneWidget);
    await gesture.moveTo(Offset(rect.left - 40, rect.center.dy));
    await tester.pump();
    expect(find.text('2026.10.03 09:00 한국 시간 · 1,340.00원'), findsOneWidget);
    await gesture.up();
  });

  testWidgets(
    'single finite sample is selectable and new history clears the selection',
    (tester) async {
      await showChart(
        tester,
        history([(0, 'NaN'), (10, '1350.25'), (20, 'Infinity')]),
      );
      await tester.tap(find.byKey(const Key('exchange-rate-history-chart')));
      await tester.pump();
      expect(find.text('2026.10.03 09:10 한국 시간 · 1,350.25원'), findsOneWidget);
      await showChart(tester, history([(30, '1360')]));
      expect(find.textContaining('1,350.25원'), findsNothing);
      expect(find.text('차트를 눌러 조회하거나 꾹 누른 채 움직여보세요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
