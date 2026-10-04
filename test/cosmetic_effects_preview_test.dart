import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dollar_trapped/features/gacha/screens/live_gacha_page.dart';
import 'package:dollar_trapped/features/gacha/widgets/cosmetic_catalog_sheet.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
  testWidgets(
    'effects are previewed inside the probability sheet, without a second destination',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      await tester.pumpWidget(
        MaterialApp(
          home: LiveGachaPage(
            repository: MockDollarRepository(),
            nickname: '테스트달러',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('새 장식 미리보기  ›'), findsNothing);
      await tester.ensureVisible(find.text('획득 목록 · 확률 안내  ›'));
      await tester.tap(find.text('획득 목록 · 확률 안내  ›'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CosmeticCatalogSheet), findsOneWidget);
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      await tester.scrollUntilVisible(
        find.text('금박 · 광택 시안'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('디자인 후보'), findsOneWidget);
      expect(find.textContaining('특별 후보'), findsWidgets);
      expect(find.text('개별 확률 0.0000%'), findsNothing);
    },
  );

  testWidgets('combined sheet fits narrow screen and respects reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: true,
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: CosmeticCatalogSheet(
            catalog: CosmeticCatalog(items: [], probabilities: {}),
            nickname: '아주긴이름의달러물림',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(SwitchListTile), 100);
    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isFalse);
    expect(toggle.onChanged, isNull);
    await tester.scrollUntilVisible(find.text('오로라 잉크'), 250);
    expect(find.text('오로라 잉크'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
