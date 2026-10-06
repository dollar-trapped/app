import 'package:flutter/material.dart';

import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import '../../profile/widgets/profile_layout.dart';
import '../../shared/widgets/cosmetic_layout.dart';
import '../data/gacha_models.dart';
import '../widgets/batch_gacha_reveal.dart';

class BatchDrawResultPage extends StatelessWidget {
  const BatchDrawResultPage({
    super.key,
    required this.nickname,
    required this.results,
    required this.onOpenResult,
    this.failure,
    this.animate = true,
  });

  final bool animate;
  final String nickname;
  final List<CosmeticDraw> results;
  final String? failure;
  final Future<void> Function(BuildContext, CosmeticDraw) onOpenResult;

  @override
  Widget build(BuildContext context) {
    final newItems = results.where((result) => !result.duplicate).length;
    final chips = results.fold(0, (sum, result) => sum + result.chipsGranted);
    final content = ProfileLayout(
      title: '10회 뽑기 결과',
      child: CosmeticContent(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${results.length}개의 취향을\n만났어요.', style: ProfileStyle.title),
            const SizedBox(height: 16),
            Text('새 아이템 $newItems개 · 중복 ${results.length - newItems}개'),
            if (chips > 0) Text('중복 보상 달러칩 $chips개'),
            const SizedBox(height: 8),
            const Text(
              '아이템을 눌러 자세히 보거나 적용할 수 있어요.',
              style: ProfileStyle.caption,
            ),
            if (failure != null) ...[
              const SizedBox(height: 16),
              Text(
                '확인된 ${results.length}회 결과만 표시했어요.\n$failure',
                style: const TextStyle(color: Color(0xFFB3261E)),
              ),
            ],
            const SizedBox(height: 24),
            for (var i = 0; i < results.length; i++) ...[
              _ResultCard(
                index: i + 1,
                result: results[i],
                nickname: nickname,
                onPressed: () => onOpenResult(context, results[i]),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
        actions: CosmeticAction(
          label: '확인',
          hint: '획득한 아이템은 내 아이템에 보관됐어요.',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
    return animate
        ? BatchGachaReveal(nickname: nickname, results: results, child: content)
        : content;
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.index,
    required this.result,
    required this.nickname,
    required this.onPressed,
  });
  final int index;
  final CosmeticDraw result;
  final String nickname;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final item = result.item;
    return Material(
      color: const Color(0xFFF5F7F5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$index. ${item.name} · ${item.rarity}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ServerCosmeticNickname(
                nickname: nickname,
                color: item.type == 'NAME_COLOR' ? item : null,
                font: item.type == 'NAME_FONT' ? item : null,
                background: item.type == 'NAME_BACKGROUND' ? item : null,
                size: 22,
              ),
              const SizedBox(height: 12),
              Text(
                result.duplicate ? '중복 · 달러칩 +${result.chipsGranted}' : '새 아이템',
                style: ProfileStyle.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
