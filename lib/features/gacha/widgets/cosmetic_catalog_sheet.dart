import '../data/gacha_models.dart';
import 'package:flutter/material.dart';
import '../../cosmetics/models/cosmetic_models.dart';
import '../../cosmetics/widgets/server_cosmetic_preview.dart';

String cosmeticRarityLabel(String value) => switch (value) {
  'COMMON' => '일반',
  'RARE' => '희귀',
  'SPECIAL' => '특별',
  _ => value,
};
String cosmeticTypeLabel(String value) => switch (value) {
  'NAME_COLOR' => '글자색',
  'NAME_FONT' => '글꼴',
  'NAME_BACKGROUND' => '배경',
  _ => value,
};
Color cosmeticRarityColor(String value) => switch (value) {
  'RARE' => const Color(0xFF5264C9),
  'SPECIAL' => const Color(0xFFA56B15),
  _ => const Color(0xFF667069),
};

class CosmeticCatalogSheet extends StatefulWidget {
  const CosmeticCatalogSheet({
    super.key,
    required this.catalog,
    required this.nickname,
  });
  final CosmeticCatalog catalog;
  final String nickname;
  @override
  State<CosmeticCatalogSheet> createState() => _CosmeticCatalogSheetState();
}

class _CosmeticCatalogSheetState extends State<CosmeticCatalogSheet> {
  bool _play = true;
  String? _type;
  String? _rarity;
  @override
  Widget build(BuildContext context) {
    final drawable = widget.catalog.items
        .where((item) => item.drawable)
        .toList();
    final rarities = <String>{
      for (final key in ['COMMON', 'RARE', 'SPECIAL'])
        if (widget.catalog.probabilities.containsKey(key) ||
            drawable.any((item) => item.rarity == key))
          key,
      ...widget.catalog.probabilities.keys,
      ...drawable.map((item) => item.rarity),
    };
    final visible = drawable
        .where(
          (item) =>
              (_type == null || item.type == _type) &&
              (_rarity == null || item.rarity == _rarity),
        )
        .toList();
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: !_play || MediaQuery.disableAnimationsOf(context),
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .85,
        minChildSize: .45,
        maxChildSize: .95,
        builder: (context, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '아이템 · 획득 확률',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  const Text(
                    '등급별 획득 확률',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  for (final rarity in rarities) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cosmeticRarityColor(
                          rarity,
                        ).withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${cosmeticRarityLabel(rarity)} · ${drawable.where((item) => item.rarity == rarity).length}종',
                              style: TextStyle(
                                color: cosmeticRarityColor(rarity),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            widget.catalog.probabilities[rarity] == null
                                ? '정보 없음'
                                : '${(widget.catalog.probabilities[rarity]! / 100).toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: cosmeticRarityColor(rarity),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    '등급 안에서는 각 아이템의 확률이 같아요.\n아이템별 확률은 등급 확률을 해당 등급의 전체 아이템 수로 나눈 값이에요.',
                    style: TextStyle(
                      color: Color(0xFF667069),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('움직임 재생'),
                    value: _play && !MediaQuery.disableAnimationsOf(context),
                    onChanged: MediaQuery.disableAnimationsOf(context)
                        ? null
                        : (value) => setState(() => _play = value),
                  ),
                  const Text(
                    '아이템 미리보기',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('모든 종류'),
                        selected: _type == null,
                        onSelected: (_) => setState(() => _type = null),
                      ),
                      for (final type in [
                        'NAME_COLOR',
                        'NAME_FONT',
                        'NAME_BACKGROUND',
                      ])
                        ChoiceChip(
                          label: Text(cosmeticTypeLabel(type)),
                          selected: _type == type,
                          onSelected: (_) => setState(() => _type = type),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('모든 등급'),
                        selected: _rarity == null,
                        onSelected: (_) => setState(() => _rarity = null),
                      ),
                      for (final rarity in rarities)
                        ChoiceChip(
                          label: Text(cosmeticRarityLabel(rarity)),
                          selected: _rarity == rarity,
                          onSelected: (_) => setState(() => _rarity = rarity),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('해당 조건의 획득 가능한 아이템이 없어요.'),
                    ),
                  for (final item in visible) ...[
                    _itemCard(
                      item,
                      drawable
                          .where((other) => other.rarity == item.rarity)
                          .length,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Divider(height: 32),
                  const Text(
                    '중복 아이템을 뽑으면',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '일반: 달러칩 1개 · 희귀: 3개 · 특별: 5개',
                    style: TextStyle(fontSize: 13, height: 1.6),
                  ),
                  Text(
                    '달러칩 ${widget.catalog.chipExchangeCost}개 → 뽑기권 1장\n닉네임 뽑기 화면에서 교환할 수 있어요.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: Color(0xFF667069),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(CosmeticItem item, int count) {
    final bps = widget.catalog.probabilities[item.rarity];
    final probability = bps == null || count == 0
        ? '확률 정보 없음'
        : '개별 확률 ${(bps / 100 / count).toStringAsFixed(4)}%';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE1E6E2)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                '${cosmeticRarityLabel(item.rarity)} · ${cosmeticTypeLabel(item.type)}',
                style: TextStyle(
                  color: cosmeticRarityColor(item.rarity),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ServerCosmeticNickname(
              nickname: widget.nickname,
              color: item.type == 'NAME_COLOR' ? item : null,
              font: item.type == 'NAME_FONT' ? item : null,
              background: item.type == 'NAME_BACKGROUND' ? item : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            probability,
            style: const TextStyle(color: Color(0xFF667069), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
