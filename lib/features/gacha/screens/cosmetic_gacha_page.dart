import 'package:flutter/material.dart';

import '../../../core/ads/ad_config.dart';
import '../../ads/widgets/rewarded_test_button.dart';

class CosmeticGachaPage extends StatelessWidget {
  const CosmeticGachaPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('꾸미기 뽑기')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Icon(
                Icons.card_giftcard,
                size: 64,
                color: Color(0xFF008A29),
              ),
              const SizedBox(height: 24),
              const Text('꾸미기 뽑기를 준비하고 있어요.'),
              const SizedBox(height: 8),
              const Text(
                '현재는 테스트 광고만 시청할 수 있으며, 실제 아이템은 지급되지 않아요.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (AdConfig.enabled)
                const RewardedTestButton()
              else
                const Text('테스트 광고는 Android 개발 빌드에서 이용할 수 있어요.'),
            ],
          ),
        ),
      ),
    ),
  );
}
