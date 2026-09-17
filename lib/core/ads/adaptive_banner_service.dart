import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'mobile_ads_service.dart';

/// One service per banner placement/size. Late callbacks after removal are safe.
class AdaptiveBannerService extends ChangeNotifier {
  BannerAd? _ad;
  bool _disposed = false;
  bool _loading = false;
  bool _loaded = false;
  BannerAd? get ad => _loaded ? _ad : null;

  Future<void> load(int width) async {
    if (_disposed || _loading || _ad != null || width <= 0) return;
    _loading = true;
    try {
      final config = await MobileAdsService.instance.initialize();
      if (_disposed || config == null) return;
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (_disposed || size == null) return;
      final banner = BannerAd(
        adUnitId: config.bannerId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (_disposed) return;
            _loaded = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('[AdMob] banner load failed: $error');
            if (_disposed) return;
            _ad = null;
            _loaded = false;
            unawaited(disposeAd(ad));
            notifyListeners();
          },
        ),
      );
      _ad = banner;
      await banner.load();
    } catch (error) {
      debugPrint('[AdMob] banner load failed: $error');
      final ad = _ad;
      _ad = null;
      _loaded = false;
      if (ad != null) await disposeAd(ad);
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final ad = _ad;
    _ad = null;
    if (ad != null) unawaited(disposeAd(ad));
    super.dispose();
  }
}
