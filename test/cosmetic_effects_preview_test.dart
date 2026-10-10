import 'package:dollar_trapped/features/gacha/data/gacha_models.dart';
import 'package:dollar_trapped/features/cosmetics/models/cosmetic_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dollar_trapped/features/gacha/screens/live_gacha_page.dart';
import 'package:dollar_trapped/features/gacha/widgets/cosmetic_catalog_sheet.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';

void main() {
  testWidgets(
    'opening probability sheet refreshes catalog and shows only server items',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({});
      final repository = _CatalogRepo();
      await tester.pumpWidget(
        MaterialApp(
          home: LiveGachaPage(repository: repository, nickname: '테스트달러'),
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
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNotNull,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(repository.catalogCalls, 2);
      await tester.scrollUntilVisible(
        find.text('진홍'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('진홍'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('중복 아이템을 뽑으면'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('디자인 후보'), findsNothing);
      expect(find.textContaining('시안'), findsNothing);
      expect(find.textContaining('획득 불가'), findsNothing);
      expect(find.text('흩날리는 벚꽃'), findsNothing);
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
        home: Scaffold(
          body: CosmeticCatalogSheet(catalog: _catalog, nickname: '아주긴이름의달러물림'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(SwitchListTile), 100);
    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isFalse);
    expect(toggle.onChanged, isNull);
    await tester.scrollUntilVisible(find.text('진홍'), 250);
    expect(find.text('진홍'), findsOneWidget);
    expect(find.text('디자인 후보'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

final _catalog = CosmeticCatalog(
  items: const [
    CosmeticItem(
      id: 'cos_color_special_01',
      type: 'NAME_COLOR',
      name: '황금빛',
      rarity: 'SPECIAL',
      drawable: true,
      appearance: {'nameColor': '#C9971C', 'styleToken': null},
    ),
    CosmeticItem(
      id: 'cos_color_special_02',
      type: 'NAME_COLOR',
      name: '진홍',
      rarity: 'SPECIAL',
      drawable: true,
      appearance: {'nameColor': null, 'styleToken': 'crimson_pulse'},
    ),
  ],
  probabilities: const {'COMMON': 7000, 'RARE': 2500, 'SPECIAL': 500},
);

class _CatalogRepo extends MockDollarRepository {
  int catalogCalls = 0;
  @override
  Future<CosmeticCatalog> getCosmeticCatalog() async {
    catalogCalls++;
    return catalogCalls == 1
        ? const CosmeticCatalog(items: [], probabilities: {})
        : _catalog;
  }
}
