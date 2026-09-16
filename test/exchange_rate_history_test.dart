import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_client.dart';
import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/features/shared/data/dollar_api.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sorts history points by server timestamp', () {
    final history = ExchangeRateHistory.fromJson({
      'pair': 'USD-KRW',
      'range': '1D',
      'interval': '10m',
      'from': '2026-09-11T00:00:00Z',
      'to': '2026-09-11T00:20:00Z',
      'isPartial': false,
      'points': [
        _pointJson('2026-09-11T00:20:00Z', '1342.00'),
        _pointJson('2026-09-11T00:00:00Z', '1340.00'),
        _pointJson('2026-09-11T00:10:00Z', '1341.00'),
      ],
    });

    expect(history.pair, 'USD-KRW');
    expect(history.points.map((point) => point.time.toIso8601String()), [
      '2026-09-11T00:00:00.000Z',
      '2026-09-11T00:10:00.000Z',
      '2026-09-11T00:20:00.000Z',
    ]);
  });

  test('requests history with the selected API range', () async {
    final adapter = _HistoryAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'));
    dio.httpClientAdapter = adapter;
    final repository = DollarApi.withDependencies(
      ApiClient(_MemoryTokenStore(), dio: dio),
      _MemoryTokenStore(),
    );

    final history = await repository.getUsdKrwHistory('1D');

    expect(adapter.path, '/api/v1/exchange-rates/USD-KRW/history');
    expect(adapter.range, '1D');
    expect(history.interval, '10m');
    expect(history.points, hasLength(144));
  });

  testWidgets('loads 1M by default and maps all three history tabs', (
    tester,
  ) async {
    final repository = _HistoryRepository();
    await _pumpRatePage(tester, repository);

    expect(repository.ranges, ['1M']);
    await tester.tap(find.text('1일'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1주'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1개월'));
    await tester.pumpAndSettle();

    expect(repository.ranges, ['1M', '1D', '1W', '1M']);
  });

  testWidgets('shows loading and empty history states without a chart', (
    tester,
  ) async {
    final repository = _HistoryRepository(pending: true);
    await tester.pumpWidget(
      MaterialApp(home: UsdKrwPage(repository: repository)),
    );
    await tester.pump();

    expect(find.text('환율 이력을 불러오는 중이에요.'), findsOneWidget);
    expect(find.byKey(const Key('exchange-rate-history-chart')), findsNothing);

    repository.complete(_history(points: const []));
    await tester.pumpAndSettle();
    expect(find.text('환율 데이터가 없어요.'), findsOneWidget);
    expect(find.byKey(const Key('exchange-rate-history-chart')), findsNothing);
  });

  testWidgets('shows a retry action when history loading fails', (
    tester,
  ) async {
    final repository = _HistoryRepository(failuresBeforeSuccess: 1);
    await _pumpRatePage(tester, repository);

    expect(find.text('환율 이력을 불러오지 못했어요.'), findsOneWidget);
    await tester.tap(find.text('차트 다시 시도'));
    await tester.pumpAndSettle();

    expect(repository.ranges, ['1M', '1M']);
    expect(
      find.byKey(const Key('exchange-rate-history-chart')),
      findsOneWidget,
    );
  });

  testWidgets('renders a single history point without drawing a line', (
    tester,
  ) async {
    final repository = _HistoryRepository(
      result: _history(points: [_point(DateTime.utc(2026, 9, 11), '1340.00')]),
    );
    await _pumpRatePage(tester, repository);

    expect(
      find.byKey(const Key('exchange-rate-history-chart')),
      findsOneWidget,
    );
    expect(find.text('데이터가 한 건만 있어요.'), findsOneWidget);
  });
}

Map<String, dynamic> _pointJson(String time, String rate) => {
  'time': time,
  'asOf': time,
  'rate': rate,
  'source': 'server',
};

ExchangeRatePoint _point(DateTime time, String rate) =>
    ExchangeRatePoint(time: time, asOf: time, rate: rate, source: 'server');

ExchangeRateHistory _history({required List<ExchangeRatePoint> points}) =>
    ExchangeRateHistory(
      pair: 'USD-KRW',
      range: '1M',
      interval: '1d',
      from: DateTime.utc(2026, 8, 12),
      to: DateTime.utc(2026, 9, 11),
      points: points,
      isPartial: false,
    );

Future<void> _pumpRatePage(
  WidgetTester tester,
  _HistoryRepository repository,
) async {
  await tester.pumpWidget(
    MaterialApp(home: UsdKrwPage(repository: repository)),
  );
  await tester.pumpAndSettle();
}

class _HistoryRepository extends MockDollarRepository {
  _HistoryRepository({
    this.pending = false,
    this.failuresBeforeSuccess = 0,
    ExchangeRateHistory? result,
  }) : result =
           result ??
           _history(
             points: [
               _point(DateTime.utc(2026, 9, 10), '1339.00'),
               _point(DateTime.utc(2026, 9, 11), '1341.00'),
             ],
           );

  final bool pending;
  int failuresBeforeSuccess;
  final ExchangeRateHistory result;
  final ranges = <String>[];
  final _completer = Completer<ExchangeRateHistory>();

  @override
  Future<ExchangeRateHistory> getUsdKrwHistory(String range) {
    ranges.add(range);
    if (pending && !_completer.isCompleted) return _completer.future;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      return Future.error(StateError('history failed'));
    }
    return Future.value(result);
  }

  void complete(ExchangeRateHistory history) => _completer.complete(history);
}

class _MemoryTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}

  @override
  Future<TokenPair?> read() async => null;

  @override
  Future<void> write(TokenPair tokens) async {}
}

class _HistoryAdapter implements HttpClientAdapter {
  String? path;
  String? range;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.uri.path;
    range = options.uri.queryParameters['range'];
    final points = List.generate(144, (index) {
      final time = DateTime.utc(2026, 9, 11).add(Duration(minutes: index * 10));
      return _pointJson(time.toIso8601String(), '${1340 + index / 100}');
    });
    return ResponseBody.fromString(
      jsonEncode({
        'pair': 'USD-KRW',
        'range': '1D',
        'interval': '10m',
        'from': '2026-09-11T00:00:00Z',
        'to': '2026-09-11T23:50:00Z',
        'points': points,
        'isPartial': false,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
