import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/ads/rewarded_ad_service.dart';

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
