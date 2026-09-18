import 'package:dollar_trapped/core/ads/mobile_ads_service.dart';
import 'package:dollar_trapped/features/ads/widgets/rewarded_test_button.dart';
import 'package:dollar_trapped/features/gacha/data/cosmetic_models.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  testWidgets(
    'demo ad discloses no reward and never creates or polls a real session',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      instanceManager = AdInstanceManager(
        'plugins.flutter.io/google_mobile_ads',
      );
      RewardedAd? loaded;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(instanceManager.channel, (call) async {
            if (call.method == 'MobileAds#initialize') {
              return InitializationStatus({});
            }
            if (call.method == 'loadRewardedAd') {
              loaded =
                  instanceManager.adFor(call.arguments['adId'])! as RewardedAd;
              loaded!.rewardedAdLoadCallback.onAdLoaded(loaded!);
            }
            return null;
          });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(instanceManager.channel, null);
      });
      await tester.runAsync(() => MobileAdsService.instance.initialize());
      final repo = _Repo();
      var refreshes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RewardedTestButton(
              repository: repo,
              onVerified: () => refreshes++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('시청해도 실제 뽑기권은 지급되지'), findsOneWidget);
      await tester.tap(find.text('▷  테스트 광고 보기 · 보상 없음'));
      await tester.pumpAndSettle();
      final ad = loaded!;
      ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'test'));
      ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
      await tester.pumpAndSettle();
      expect(find.text('테스트 광고 시청을 완료했어요. 뽑기권은 지급되지 않습니다.'), findsOneWidget);
      expect(repo.creates, 0);
      expect(repo.reads, 0);
      expect(refreshes, 0);
      expect(find.text('보상 다시 확인'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

class _Repo extends MockDollarRepository {
  int creates = 0, reads = 0;
  @override
  Future<AdRewardSession> createAdRewardSession(String requestId) async {
    creates++;
    throw StateError('Test ads must not create a production reward session');
  }

  @override
  Future<AdRewardSession> getAdRewardSession(String sessionId) async {
    reads++;
    throw StateError('Test ads must not poll a production reward session');
  }
}
