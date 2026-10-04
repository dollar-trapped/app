import 'package:flutter/material.dart';
import '../../profile/widgets/profile_layout.dart';
import '../../shared/widgets/cosmetic_layout.dart';
import '../widgets/cosmetic_preview.dart';
import '../widgets/gacha_reveal.dart';

/// Design preview only. Opening or closing this page never grants an item.
class CosmeticResultPage extends StatelessWidget {
  const CosmeticResultPage({super.key, required this.nickname});
  final String nickname;
  void _finish(BuildContext context) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('샘플 미리보기예요. 아이템은 지급·저장·적용되지 않았어요.')),
    );
  }

  @override
  Widget build(BuildContext context) => GachaReveal(
    isPreview: true,
    child: ProfileLayout(
      title: '뽑기 결과',
      child: CosmeticContent(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '새로운 아이템 · 샘플',
              style: TextStyle(
                fontSize: 13,
                height: 20 / 13,
                color: ProfileStyle.action,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const Text('새로운 취향을\n뽑았어요.', style: ProfileStyle.title),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('글자색 · NAME COLOR', style: ProfileStyle.caption),
                  const SizedBox(height: 16),
                  Text(
                    nickname,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      height: 46 / 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF906719),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '빈티지 골드',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '은은하게, 존재감 있게.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 24 / 15,
                      color: ProfileStyle.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CosmeticChatPreview(
              nickname: nickname,
              selection: const CosmeticSelection(color: 4),
            ),
            const SizedBox(height: 24),
            const Text(
              '뽑기 결과 디자인을 확인하는 샘플이에요.\n실제 아이템은 지급되거나 보관되지 않아요.',
              style: ProfileStyle.caption,
            ),
          ],
        ),
        actions: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CosmeticAction(
              label: '지금 적용',
              hint: '',
              onPressed: () => _finish(context),
            ),
          ],
        ),
      ),
    ),
  );
}
