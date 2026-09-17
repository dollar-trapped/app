import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'mobile_ads_service.dart';

enum RewardedStatus { idle, loading, ready, showing, failed }

/// Owns the single-use ad, prevents concurrent loads/shows, and never grants
/// rewards. The temporary reward callback deliberately only logs an event.
class RewardedAdService extends ChangeNotifier {
  RewardedAd? _ad;
  RewardedAd? _showingAd;
  bool _disposed = false;
  RewardedStatus _status = RewardedStatus.idle;
  RewardedStatus get status => _status;

  void _setStatus(RewardedStatus status) {
    if (_disposed) return;
    _status = status;
    notifyListeners();
  }

  Future<void> preload() async {
    if (_disposed ||
        _status == RewardedStatus.loading ||
        _status == RewardedStatus.ready ||
        _status == RewardedStatus.showing) {
      return;
    }
    _setStatus(RewardedStatus.loading);
    try {
      final config = await MobileAdsService.instance.initialize();
      if (_disposed) return;
      if (config == null) {
        _setStatus(RewardedStatus.failed);
        return;
      }
      await RewardedAd.load(
        adUnitId: config.rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (_disposed) {
              unawaited(disposeAd(ad));
              return;
            }
            _ad = ad;
            _setStatus(RewardedStatus.ready);
          },
          onAdFailedToLoad: (error) {
            debugPrint('[AdMob] rewarded load failed: $error');
            _setStatus(RewardedStatus.failed);
          },
        ),
      );
    } catch (error) {
      debugPrint('[AdMob] rewarded load failed: $error');
      _setStatus(RewardedStatus.failed);
    }
  }

  Future<void> show() async {
    if (_disposed || _status == RewardedStatus.showing) return;
    final ad = _ad;
    if (ad == null) {
      await preload();
      return; // A retry never opens an ad without another explicit tap.
    }
    _ad = null;
    _showingAd = ad;
    _setStatus(RewardedStatus.showing);
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: _finish,
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMob] rewarded show failed: $error');
        _finish(ad);
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          debugPrint('[AdMob] reward earned');
        },
      );
    } catch (error) {
      debugPrint('[AdMob] rewarded show failed: $error');
      _finish(ad);
    }
  }

  void _finish(RewardedAd ad) {
    if (!identical(_showingAd, ad)) return;
    _showingAd = null;
    unawaited(_disposeAndPreload(ad));
  }

  Future<void> _disposeAndPreload(RewardedAd ad) async {
    await disposeAd(ad);
    if (_disposed) return;
    _setStatus(RewardedStatus.idle);
    await preload();
  }

  @override
  void dispose() {
    _disposed = true;
    final ad = _ad;
    final showing = _showingAd;
    _ad = null;
    _showingAd = null;
    if (ad != null) unawaited(disposeAd(ad));
    if (showing != null) unawaited(disposeAd(showing));
    super.dispose();
  }
}
