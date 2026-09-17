import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class MobileAdsService {
  MobileAdsService._();

  static final instance = MobileAdsService._();
  Future<AdConfig?>? _initialization;

  /// Shared by startup and ad services; failures allow a later retry.
  Future<AdConfig?> initialize() {
    if (!AdConfig.enabled) return Future.value(null);
    return _initialization ??= _initialize();
  }

  Future<AdConfig?> _initialize() async {
    try {
      final config = await AdConfig.load();
      await MobileAds.instance.initialize();
      return config;
    } catch (error) {
      debugPrint('[AdMob] initialization failed: $error');
      _initialization = null;
      return null;
    }
  }
}

/// Plugin operations are asynchronous, including disposal.
Future<void> disposeAd(Ad ad) async {
  try {
    await ad.dispose();
  } catch (error) {
    debugPrint('[AdMob] dispose failed: $error');
  }
}
