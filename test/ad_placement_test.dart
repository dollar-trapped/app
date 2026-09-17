import 'package:dollar_trapped/features/ads/widgets/adaptive_banner.dart';
import 'package:dollar_trapped/features/ads/widgets/rewarded_test_button.dart';
import 'package:dollar_trapped/features/chat/screens/usd_room_page.dart';
import 'package:dollar_trapped/features/exchange/screens/usd_krw_detail_page.dart';
import 'package:dollar_trapped/features/gacha/screens/cosmetic_gacha_page.dart';
import 'package:dollar_trapped/features/profile/screens/my_page.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('USD room contains no advertising UI', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: UsdRoomPage(
          repository: MockDollarRepository(),
          onRateBarTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdaptiveBanner), findsNothing);
    expect(find.byType(RewardedTestButton), findsNothing);
    expect(find.textContaining('뽑기'), findsNothing);
  });

  testWidgets('detail banner is anchored below scrollable chart content', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: UsdKrwDetailPage(repository: MockDollarRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdaptiveBanner), findsOneWidget);
    final bannerY = tester.getTopLeft(find.byType(AdaptiveBanner)).dy;
    expect(
      bannerY,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('USD/KRW')).dy),
    );
    expect(
      bannerY,
      greaterThanOrEqualTo(
        tester.getBottomLeft(find.byType(SingleChildScrollView)).dy,
      ),
    );
    expect(find.byType(RewardedTestButton), findsNothing);
  });

  testWidgets('profile draw card opens and returns from gacha page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyPage(repository: MockDollarRepository(), onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('설정')).dx,
      greaterThan(tester.getCenter(find.text('마이페이지')).dx),
    );
    expect(find.byType(RewardedTestButton), findsNothing);
    await tester.ensureVisible(find.text('닉네임 뽑기  →'));
    await tester.tap(find.text('닉네임 뽑기  →'));
    await tester.pumpAndSettle();
    expect(find.byType(CosmeticGachaPage), findsOneWidget);
    expect(find.byType(RewardedTestButton), findsOneWidget);
    expect(find.textContaining('뽑기권과 아이템은 지급되지'), findsOneWidget);
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(find.byType(CosmeticGachaPage), findsNothing);
    expect(find.text('마이페이지'), findsOneWidget);
  });
}
