import 'dart:convert';
import 'package:dollar_trapped/core/ads/ad_config.dart';
import 'package:dollar_trapped/core/ads/adaptive_banner_service.dart';
import 'package:dollar_trapped/core/ads/rewarded_ad_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// The plugin's own test seam lets us exercise real Dart callbacks without ads.
// ignore: implementation_imports
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  String? failingMethod;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls.clear();
    failingMethod = null;
    instanceManager = AdInstanceManager('plugins.flutter.io/google_mobile_ads');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, (call) async {
          calls.add(call);
          if (call.method == failingMethod) {
            throw PlatformException(code: 'test_failure');
          }
          return switch (call.method) {
            'MobileAds#initialize' => InitializationStatus({}),
            'AdSize#getLargeAnchoredAdaptiveBannerAdSize' => 60,
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(instanceManager.channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> flush() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  RewardedAd loadedRewarded() {
    final call = calls.lastWhere((c) => c.method == 'loadRewardedAd');
    return instanceManager.adFor(call.arguments['adId'])! as RewardedAd;
  }

  test('test config is Android only and uses Google demo units', () async {
    final config = await AdConfig.load();
    expect(config.bannerId, 'ca-app-pub-3940256099942544/9214589741');
    expect(config.rewardedId, 'ca-app-pub-3940256099942544/5224354917');
    expect(AdConfig.enabled, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AdConfig.enabled, isFalse);
  });

  test('production IDs use the corrected units and reject demo IDs', () async {
    final json =
        jsonDecode(await rootBundle.loadString('config/admob_production.json'))
            as Map<String, dynamic>;
    final config = AdConfig.fromJson(json, production: true);
    expect(config.bannerId, 'ca-app-pub-8613152611947698/5836287128');
    expect(config.rewardedId, 'ca-app-pub-8613152611947698/2766235844');
    expect(json['androidAppId'], 'ca-app-pub-8613152611947698~7427088470');
    expect(
      () => AdConfig.fromJson({
        ...json,
        'androidAdaptiveBannerId': 'ca-app-pub-3940256099942544/9214589741',
      }, production: true),
      throwsStateError,
    );
    expect(() => AdConfig.fromJson(json, production: false), throwsStateError);
  });

  test(
    'reward logs only on earned callback; dismiss disposes and preloads',
    () async {
      final service = RewardedAdService();
      await Future.wait([service.preload(), service.preload()]);
      expect(calls.where((c) => c.method == 'loadRewardedAd'), hasLength(1));
      final ad = loadedRewarded();
      ad.rewardedAdLoadCallback.onAdLoaded(ad);
      expect(service.status, RewardedStatus.ready);
      final logs = <String?>[];
      final originalPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) => logs.add(message);
      try {
        await Future.wait([service.show(), service.show()]);
        expect(
          calls.where((c) => c.method == 'showAdWithoutView'),
          hasLength(1),
        );
        expect(logs, isEmpty);
        ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'test'));
        expect(logs, ['[AdMob] reward earned']);
        ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
        await flush();
        expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
        expect(calls.where((c) => c.method == 'loadRewardedAd'), hasLength(2));
        expect(service.status, RewardedStatus.loading);
        service.dispose();
        final lateAd = loadedRewarded();
        lateAd.rewardedAdLoadCallback.onAdLoaded(lateAd);
        await flush();
        expect(calls.where((c) => c.method == 'disposeAd'), hasLength(2));
      } finally {
        debugPrint = originalPrint;
      }
    },
  );

  test(
    'SSV custom data is configured before display and verification starts after close',
    () async {
      final service = RewardedAdService();
      await service.preload();
      final ad = loadedRewarded();
      ad.rewardedAdLoadCallback.onAdLoaded(ad);
      bool? earned;
      await service.show(
        customData: 'signed-session-data',
        onClosed: (value) => earned = value,
      );
      final methods = calls.map((c) => c.method).toList();
      expect(
        methods.indexOf('setServerSideVerificationOptions'),
        lessThan(methods.indexOf('showAdWithoutView')),
      );
      expect(methods, contains('setServerSideVerificationOptions'));
      ad.onUserEarnedRewardCallback!(ad, RewardItem(1, 'test'));
      expect(earned, isNull);
      ad.fullScreenContentCallback!.onAdDismissedFullScreenContent!(ad);
      expect(earned, isTrue);
      await flush();
      service.dispose();
    },
  );

  test(
    'load failure can retry; show callback failure disposes and preloads',
    () async {
      final service = RewardedAdService();
      await service.preload();
      final failedAd = loadedRewarded();
      failedAd.rewardedAdLoadCallback.onAdFailedToLoad(
        LoadAdError(0, 'test', 'offline', null),
      );
      expect(service.status, RewardedStatus.failed);
      await service.show();
      expect(calls.where((c) => c.method == 'showAdWithoutView'), isEmpty);
      final ad = loadedRewarded();
      ad.rewardedAdLoadCallback.onAdLoaded(ad);
      await service.show();
      ad.fullScreenContentCallback!.onAdFailedToShowFullScreenContent!(
        ad,
        AdError(0, 'test', 'show failed'),
      );
      await flush();
      expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
      expect(calls.where((c) => c.method == 'loadRewardedAd'), hasLength(3));
      service.dispose();
      final lateAd = loadedRewarded();
      lateAd.rewardedAdLoadCallback.onAdLoaded(lateAd);
      await flush();
    },
  );

  test('platform show exception recovers without escaping to UI', () async {
    final service = RewardedAdService();
    await service.preload();
    final ad = loadedRewarded();
    ad.rewardedAdLoadCallback.onAdLoaded(ad);
    failingMethod = 'showAdWithoutView';
    await service.show();
    await flush();
    expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
    expect(service.status, RewardedStatus.loading);
    service.dispose();
    final lateAd = loadedRewarded();
    lateAd.rewardedAdLoadCallback.onAdLoaded(lateAd);
    await flush();
  });

  test(
    'banner uses available width and safely disposes after load failure',
    () async {
      final service = AdaptiveBannerService();
      await service.load(360);
      final call = calls.lastWhere((c) => c.method == 'loadBannerAd');
      final ad = instanceManager.adFor(call.arguments['adId'])! as BannerAd;
      expect(ad.size.width, 360);
      expect(service.ad, isNull);
      ad.listener.onAdLoaded!(ad);
      expect(service.ad, ad);
      ad.listener.onAdFailedToLoad!(
        ad,
        LoadAdError(0, 'test', 'offline', null),
      );
      await flush();
      expect(service.ad, isNull);
      expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
      service.dispose();
    },
  );

  test(
    'banner retries a failed load and cancels pending retry on disposal',
    () async {
      final service = AdaptiveBannerService(
        retryDelay: const Duration(milliseconds: 20),
      );
      await service.load(360);
      var call = calls.lastWhere((c) => c.method == 'loadBannerAd');
      var ad = instanceManager.adFor(call.arguments['adId'])! as BannerAd;
      ad.listener.onAdFailedToLoad!(
        ad,
        LoadAdError(3, 'test', 'no fill', null),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await flush();
      expect(calls.where((c) => c.method == 'loadBannerAd'), hasLength(2));
      call = calls.lastWhere((c) => c.method == 'loadBannerAd');
      ad = instanceManager.adFor(call.arguments['adId'])! as BannerAd;
      ad.listener.onAdFailedToLoad!(
        ad,
        LoadAdError(3, 'test', 'no fill', null),
      );
      service.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(calls.where((c) => c.method == 'loadBannerAd'), hasLength(2));
    },
  );

  test(
    'banner late completion after removal does not notify disposed UI',
    () async {
      final service = AdaptiveBannerService();
      await service.load(360);
      final call = calls.lastWhere((c) => c.method == 'loadBannerAd');
      final ad = instanceManager.adFor(call.arguments['adId'])! as BannerAd;
      service.dispose();
      ad.listener.onAdLoaded!(ad);
      await flush();
      expect(calls.where((c) => c.method == 'disposeAd'), hasLength(1));
      expect(service.ad, isNull);
    },
  );
}
