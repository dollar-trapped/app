import 'package:flutter/material.dart';

import '../../../core/ads/ad_config.dart';
import '../../ads/widgets/rewarded_test_button.dart';
import '../../profile/widgets/profile_layout.dart';
import '../widgets/cosmetic_layout.dart';
import 'cosmetic_items_page.dart';
import 'cosmetic_result_page.dart';

/// Test-only empty state. Ad rewards log an event, never increment this balance.
class CosmeticGachaPage extends StatelessWidget {
  const CosmeticGachaPage({super.key, this.nickname = '닉네임'});
  final String nickname;

  @override
  Widget build(BuildContext context) => ProfileLayout(
    title: '닉네임 뽑기',
    child: CosmeticContent(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('이름은 그대로.\n분위기는 새롭게.', style: ProfileStyle.title),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '내 뽑기권',
                style: TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  fontWeight: FontWeight.w500,
                  color: ProfileStyle.muted,
                ),
              ),
              Text(
                '0장',
                key: Key('gacha-ticket-balance'),
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: ProfileStyle.action,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const RewardedTestButton(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ProfileStyle.forest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '달러물림 / 닉네임 컬렉션',
                  style: ProfileStyle.caption.copyWith(
                    color: ProfileStyle.soft,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  nickname,
                  style: const TextStyle(
                    fontFamily: 'Noto Serif KR',
                    fontSize: 36,
                    height: 46 / 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '평단은 못 바꿔도, 분위기는 바꿉니다.',
                  style: ProfileStyle.caption.copyWith(
                    color: ProfileStyle.soft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CategorySample(label: '글자색', color: Color(0xFF803E85)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _CategorySample(
                  label: '글꼴',
                  fontFamily: 'Noto Serif KR',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _CategorySample(
                  label: '배경',
                  color: ProfileStyle.forest,
                  background: Color(0xFFF7EDA6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '세 종류 중 한 가지 아이템을 뽑아요.',
            style: TextStyle(
              fontSize: 15,
              height: 24 / 15,
              color: ProfileStyle.muted,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('획득 목록 · 확률 안내'),
                  content: const Text(
                    '글자색 · 글꼴 · 배경을 준비하고 있어요.\n획득 목록과 확률은 아직 확정되지 않았어요.\n현재는 테스트 광고만 시청할 수 있으며 뽑기권과 아이템은 지급되지 않아요.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CosmeticItemsPage(
                              nickname: nickname,
                              samplePreview: true,
                            ),
                          ),
                        );
                      },
                      child: const Text('아이템 조합 미리보기'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                CosmeticResultPage(nickname: nickname),
                          ),
                        );
                      },
                      child: const Text('뽑기 결과 미리보기'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 44),
                foregroundColor: ProfileStyle.muted,
                textStyle: const TextStyle(
                  fontFamily: 'Noto Sans KR',
                  fontSize: 13,
                  height: 20 / 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('획득 목록 · 확률 안내  ›'),
            ),
          ),
        ],
      ),
      actions: CosmeticAction(
        label: '뽑기권이 필요해요',
        hint: AdConfig.enabled
            ? '테스트 광고 · 뽑기권과 아이템은 지급되지 않아요.'
            : '테스트 광고는 Android 개발 빌드에서 이용할 수 있어요.',
      ),
    ),
  );
}

class _CategorySample extends StatelessWidget {
  const _CategorySample({
    required this.label,
    this.color = ProfileStyle.ink,
    this.background = const Color(0xFFF5F7F5),
    this.fontFamily = 'Noto Sans KR',
  });
  final String label;
  final Color color;
  final Color background;
  final String fontFamily;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '가나다',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: ProfileStyle.caption),
      ],
    ),
  );
}
