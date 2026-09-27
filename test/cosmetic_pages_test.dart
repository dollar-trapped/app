import 'package:dollar_trapped/features/gacha/screens/cosmetic_gacha_page.dart';
import 'package:dollar_trapped/features/gacha/screens/cosmetic_items_page.dart';
import 'package:dollar_trapped/features/gacha/widgets/nickname_appearance.dart';
import 'package:dollar_trapped/features/profile/screens/my_page.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:dollar_trapped/features/gacha/widgets/cosmetic_preview.dart';
import 'package:dollar_trapped/features/gacha/screens/cosmetic_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sample combinations stay local and reset every category', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CosmeticItemsPage(nickname: '지존도건', samplePreview: true),
      ),
    );
    await tester.tap(find.text('달러 그린'));
    await tester.tap(find.text('글꼴'));
    await tester.pump();
    await tester.tap(find.text('차분한 명조'));
    await tester.tap(find.text('배경'));
    await tester.pump();
    await tester.tap(find.text('얇은 테두리'));
    await tester.pump();
    var preview = tester.widget<CosmeticChatPreview>(
      find.byType(CosmeticChatPreview),
    );
    expect(preview.selection.color, 1);
    expect(preview.selection.font, 2);
    expect(preview.selection.background, 2);
    await tester.tap(find.text('모두 해제'));
    await tester.pump();
    preview = tester.widget<CosmeticChatPreview>(
      find.byType(CosmeticChatPreview),
    );
    expect(preview.selection.isBasic, isTrue);
    expect(find.text('기본 모습으로 적용'), findsOneWidget);
  });

  testWidgets('result preview closes without increasing tickets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CosmeticGachaPage(nickname: '지존도건')),
    );
    await tester.ensureVisible(find.text('획득 목록 · 확률 안내  ›'));
    await tester.tap(find.text('획득 목록 · 확률 안내  ›'));
    await _settleAndOpenCard(tester);
    await tester.tap(find.text('뽑기 결과 미리보기'));
    await _settleAndOpenCard(tester);
    expect(find.byType(CosmeticResultPage), findsOneWidget);
    expect(find.text('빈티지 골드'), findsOneWidget);
    await tester.ensureVisible(find.text('지금 적용'));
    await tester.tap(find.text('지금 적용'));
    await _settleAndOpenCard(tester);
    expect(find.text('0장'), findsOneWidget);
    expect(find.textContaining('지급·저장·적용되지'), findsOneWidget);
  });

  testWidgets('sample grids and result support large text on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final page in <Widget>[
      const CosmeticItemsPage(nickname: '아주긴닉네임을사용해요', samplePreview: true),
      const CosmeticResultPage(nickname: '아주긴닉네임을사용해요'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: page,
        ),
      );
      await _settleAndOpenCard(tester);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('zero tickets disables draw and discloses test-only rewards', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: CosmeticGachaPage(nickname: '초록달러')),
    );
    await _settleAndOpenCard(tester);
    expect(find.text('0장'), findsOneWidget);
    expect(find.text('초록달러'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '뽑기권이 필요해요'),
    );
    expect(button.onPressed, isNull);
    await tester.ensureVisible(find.text('획득 목록 · 확률 안내  ›'));
    await tester.tap(find.text('획득 목록 · 확률 안내  ›'));
    await _settleAndOpenCard(tester);
    expect(find.textContaining('아직 확정되지 않았어요'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await _settleAndOpenCard(tester);
    expect(find.text('0장'), findsOneWidget);
  });

  testWidgets(
    'profile opens server inventory and returns after applying basic appearance',
    (tester) async {
      final repository = MockDollarRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: MyPage(repository: repository, onBack: () {}),
        ),
      );
      await _settleAndOpenCard(tester);
      await tester.tap(find.text('내 아이템 · 꾸미기'));
      await _settleAndOpenCard(tester);
      expect(find.text('아직 모은 글자색이 없어요.'), findsOneWidget);
      await tester.tap(find.text('글꼴'));
      await tester.pump();
      expect(find.text('아직 모은 글꼴이 없어요.'), findsOneWidget);
      await tester.tap(find.text('배경'));
      await tester.pump();
      expect(find.text('아직 모은 배경이 없어요.'), findsOneWidget);
      await tester.ensureVisible(find.text('기본 모습으로 적용'));
      await tester.tap(find.text('기본 모습으로 적용'));
      await _settleAndOpenCard(tester);
      expect(find.text('마이페이지'), findsOneWidget);
      expect((await repository.getMe()).nickname, '초록달러');
    },
  );

  testWidgets('gold presentation changes only nickname and equipment label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyPage(
          repository: MockDollarRepository(),
          onBack: () {},
          appearance: NicknameAppearance.vintageGold,
        ),
      ),
    );
    await _settleAndOpenCard(tester);
    expect(
      tester.widget<Text>(find.text('초록달러')).style!.color,
      const Color(0xFF906719),
    );
    expect(find.text('빈티지 골드 · 기본 글꼴 · 배경 없음'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('오늘은 어떤 이름?')).style!.color,
      Colors.white,
    );
  });

  testWidgets('cosmetic screens accommodate narrow viewport and larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget app(Widget child) => MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(1.5)),
        child: child!,
      ),
      home: child,
    );
    await tester.pumpWidget(
      app(const CosmeticGachaPage(nickname: '아주긴닉네임을사용해요')),
    );
    await _settleAndOpenCard(tester);
    await tester.ensureVisible(find.text('뽑기권이 필요해요'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      app(const CosmeticItemsPage(nickname: '아주긴닉네임을사용해요', holding: '2000')),
    );
    await _settleAndOpenCard(tester);
    await tester.ensureVisible(find.text('기본 모습으로 적용'));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settleAndOpenCard(WidgetTester tester) async {
  await tester.pumpAndSettle();
  if (find.text('카드를 터치해서 열어보세요').evaluate().isNotEmpty) {
    await tester.tap(find.byKey(const Key('gacha-card-touch')));
    await tester.pumpAndSettle();
  }
}
