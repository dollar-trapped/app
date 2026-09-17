import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/ads/ad_config.dart';
import '../../../core/ads/adaptive_banner_service.dart';

class AdaptiveBanner extends StatelessWidget {
  const AdaptiveBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.enabled) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: _AdaptiveBanner(
          key: ValueKey((
            constraints.maxWidth.floor(),
            MediaQuery.orientationOf(context),
          )),
          width: constraints.maxWidth.floor(),
        ),
      ),
    );
  }
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
