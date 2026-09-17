import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/ads/ad_config.dart';
import '../../../core/ads/adaptive_banner_service.dart';
import '../../../core/ads/rewarded_ad_service.dart';

class UsdRoomAds extends StatelessWidget {
  const UsdRoomAds({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.enabled) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _RewardedTestButton(),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth.floor();
              final orientation = MediaQuery.orientationOf(context);
              return _AdaptiveBanner(
                key: ValueKey((width, orientation)),
                width: width,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RewardedTestButton extends StatefulWidget {
  const _RewardedTestButton();

  @override
  State<_RewardedTestButton> createState() => _RewardedTestButtonState();
}

class _RewardedTestButtonState extends State<_RewardedTestButton> {
  final _service = RewardedAdService();

  @override
  void initState() {
    super.initState();
    unawaited(_service.preload());
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _service,
    builder: (context, _) {
      final status = _service.status;
      return TextButton(
        onPressed:
            status == RewardedStatus.loading || status == RewardedStatus.showing
            ? null
            : () => unawaited(_service.show()),
        child: Text(switch (status) {
          RewardedStatus.loading => '테스트 광고 준비 중…',
          RewardedStatus.showing => '테스트 광고 표시 중…',
          RewardedStatus.failed => '광고 로드 실패 · 다시 준비하기',
          _ => '임시 광고 보고 뽑기 (테스트 · 보상 없음)',
        }),
      );
    },
  );
}

class _AdaptiveBanner extends StatefulWidget {
  const _AdaptiveBanner({super.key, required this.width});
  final int width;

  @override
  State<_AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<_AdaptiveBanner> {
  final _service = AdaptiveBannerService();

  @override
  void initState() {
    super.initState();
    unawaited(_service.load(widget.width));
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _service,
    builder: (context, _) {
      final ad = _service.ad;
      if (ad == null) return const SizedBox.shrink();
      return SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      );
    },
  );
}
