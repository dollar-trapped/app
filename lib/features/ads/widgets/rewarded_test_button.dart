import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ads/rewarded_ad_service.dart';
import '../../../core/ads/ad_config.dart';

class RewardedTestButton extends StatefulWidget {
  const RewardedTestButton({super.key});

  @override
  State<RewardedTestButton> createState() => _RewardedTestButtonState();
}

class _RewardedTestButtonState extends State<RewardedTestButton> {
  final _service = RewardedAdService();

  @override
  void initState() {
    super.initState();
    if (AdConfig.enabled) unawaited(_service.preload());
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
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: const Color(0xFF151916),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE1E6E2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Noto Sans KR',
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed:
              !AdConfig.enabled ||
                  status == RewardedStatus.loading ||
                  status == RewardedStatus.showing
              ? null
              : () => unawaited(_service.show()),
          child: Text(switch (status) {
            RewardedStatus.loading => '테스트 광고 준비 중…',
            RewardedStatus.showing => '테스트 광고 표시 중…',
            RewardedStatus.failed => '광고 로드 실패 · 다시 준비하기',
            _ => '▷  광고 보고 뽑기권 받기',
          }),
        ),
      );
    },
  );
}
