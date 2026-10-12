import 'package:flutter/material.dart';
import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import '../../shared/data/dollar_repository.dart';
import '../data/gacha_models.dart';
import 'case_reward_card.dart';
import 'dollar_case_reveal.dart';

class BatchRewardSummary extends StatelessWidget {
  const BatchRewardSummary({
    super.key,
    required this.draws,
    required this.nickname,
    required this.repository,
    this.allowEquip = true,
  });
  final List<CosmeticDraw> draws;
  final String nickname;
  final DollarRepository repository;
  final bool allowEquip;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 700
          ? 5
          : constraints.maxWidth >= 480
          ? 3
          : 2;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '당신의 새로운 컬렉션',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '아이템을 눌러 자세히 보기 · 획득 순서',
            style: TextStyle(color: Color(0xFF9BAFA3)),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: draws.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent:
                  220 *
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final draw = draws[index], item = draw.item;
              final color = dollarRarityColor(item.rarity);
              return Material(
                color: const Color(0xFF1B2B23),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: Key('batch-reward-$index'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: const Color(0xFF142219),
                    builder: (_) => SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: CaseRewardCard(
                          repository: repository,
                          nickname: nickname,
                          result: draw,
                          allowEquip: allowEquip,
                        ),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              '${index + 1}'.padLeft(2, '0'),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              draw.duplicate ? '중복' : 'NEW',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 4,
                          ),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4F0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FittedBox(
                            child: ServerCosmeticNickname(
                              nickname: nickname,
                              color: item.type == 'NAME_COLOR' ? item : null,
                              font: item.type == 'NAME_FONT' ? item : null,
                              background: item.type == 'NAME_BACKGROUND'
                                  ? item
                                  : null,
                              size: 22,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          draw.duplicate
                              ? '${dollarRarityLabel(item.rarity)} · +${draw.chipsGranted}칩'
                              : dollarRarityLabel(item.rarity),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            letterSpacing: .5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
