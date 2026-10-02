import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'mobile_ads_service.dart';

/// One service per banner placement/size. Late callbacks after removal are safe.
class AdaptiveBannerService extends ChangeNotifier {
  AdaptiveBannerService({this.retryDelay = const Duration(seconds: 30)});

  final Duration retryDelay;
  Timer? _retryTimer;
  int _retryCount = 0;
  int _width = 0;
  BannerAd? _ad;
  bool _disposed = false;
  bool _loading = false;
  bool _loaded = false;
  BannerAd? get ad => _loaded ? _ad : null;

  Future<void> load(int width) async {
    if (_disposed || _loading || _ad != null || width <= 0) return;
    _retryTimer?.cancel();
    _width = width;
    _loading = true;
    debugPrint('[AdMob] banner load started: width=$width');
    try {
      final config = await MobileAdsService.instance.initialize();
      if (_disposed) return;
      if (config == null) {
        _scheduleRetry();
        return;
      }
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (_disposed) return;
      if (size == null) {
        debugPrint('[AdMob] banner size unavailable: width=$width');
        _scheduleRetry();
        return;
      }
      final banner = BannerAd(
        adUnitId: config.bannerId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (_disposed) return;
            _retryCount = 0;
            debugPrint('[AdMob] banner loaded');
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
            _scheduleRetry();
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
      _scheduleRetry();
    } finally {
      _loading = false;
    }
  }

  void _scheduleRetry() {
    if (_disposed || _retryCount >= 3) return;
    _retryTimer?.cancel();
    final delay = retryDelay * (1 << _retryCount);
    _retryCount++;
    debugPrint('[AdMob] banner retry $_retryCount in ${delay.inSeconds}s');
    _retryTimer = Timer(delay, () => unawaited(load(_width)));
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    final ad = _ad;
    _ad = null;
    if (ad != null) unawaited(disposeAd(ad));
    super.dispose();
  }
}
