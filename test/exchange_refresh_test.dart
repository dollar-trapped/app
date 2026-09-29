import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/features/chat/screens/usd_room_page.dart';
import 'package:dollar_trapped/features/exchange/screens/usd_krw_detail_page.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

class _Repo extends MockDollarRepository {
  int calls = 0;
  @override
  Future<ExchangeRate> getUsdKrwRate() async {
    calls++;
    return ExchangeRate(
      pair: 'USD-KRW',
      rate: calls == 1 ? '1359.14' : '1360.25',
      asOf: DateTime.parse('2026-09-28T23:41:15Z'),
      fetchedAt: DateTime.parse('2026-09-28T23:46:17Z'),
      source: 'test',
      marketStatus: 'UNAVAILABLE',
      isStale: true,
    );
  }
}

void main() {
  for (final room in [false, true]) {
    testWidgets('Korean date and five minute refresh: room=$room', (
      tester,
    ) async {
      final repo = _Repo();
      await tester.pumpWidget(
        MaterialApp(
          home: room
              ? UsdRoomPage(repository: repo, onRateBarTap: () {})
              : UsdKrwDetailPage(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1,359.14'), findsOneWidget);
      expect(
        find.textContaining(room ? '9/29 08:41' : '9월 29일 08:41'),
        findsOneWidget,
      );
      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      expect(find.textContaining('1,360.25'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
