import '../../shared/data/dollar_repository.dart';
import 'owned_cosmetics_page.dart';
import 'package:flutter/material.dart';

import '../../exchange/widgets/period_tab.dart';
import '../../profile/widgets/profile_layout.dart';
import '../widgets/cosmetic_layout.dart';
import '../widgets/cosmetic_preview.dart';
import 'cosmetic_gacha_page.dart';

/// First-visit UI only: no inventory API, persistence, or chat mutations.
class CosmeticItemsPage extends StatefulWidget {
  const CosmeticItemsPage({
    super.key,
    required this.nickname,
    this.holding,
    this.samplePreview = false,
    this.repository,
  });
  final DollarRepository? repository;
  final bool samplePreview;
  final String nickname;
  final String? holding;
  @override
  State<CosmeticItemsPage> createState() => _CosmeticItemsPageState();
}

class _CosmeticItemsPageState extends State<CosmeticItemsPage> {
  static const _categories = ['글자색', '글꼴', '배경'];
  int _selected = 0;
  CosmeticSelection _appearance = const CosmeticSelection();
  String get _category => _categories[_selected];
  String get _emptyTitle => switch (_selected) {
    0 => '아직 모은 글자색이 없어요.',
    1 => '아직 모은 글꼴이 없어요.',
    _ => '아직 모은 배경이 없어요.',
  };

  String? get _holdingLabel {
    final amount = widget.holding;
    if (amount == null || amount.isEmpty) return null;
    final parts = amount.split('.');
    final formatted = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    final fraction = parts.length > 1 ? '.${parts[1]}' : '';
    return '\$$formatted$fraction';
  }

  @override
  Widget build(BuildContext context) =>
      widget.repository != null && !widget.samplePreview
      ? OwnedCosmeticsPage(
          repository: widget.repository!,
          nickname: widget.nickname,
        )
      : ProfileLayout(
          title: '내 아이템',
          action: SizedBox(
            width: 76,
            height: 44,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selected = 0;
                  _appearance = const CosmeticSelection();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('기본 모습으로 미리보기를 초기화했어요.')),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: ProfileStyle.muted,
                textStyle: const TextStyle(
                  fontFamily: 'Noto Sans KR',
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              child: const Text('모두 해제'),
            ),
          ),
          child: CosmeticContent(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CosmeticChatPreview(
                  nickname: widget.nickname,
                  holdingLabel: _holdingLabel,
                  selection: _appearance,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < _categories.length; i++)
                      Expanded(
                        child: Semantics(
                          selected: _selected == i,
                          child: PeriodTab(
                            label: _categories[i],
                            selected: _selected == i,
                            onPressed: () => setState(() => _selected = i),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '보유한 $_category',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 20 / 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.samplePreview ? '샘플 3개' : '0개',
                      style: ProfileStyle.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.samplePreview)
                  _itemGrid()
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _emptyTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '기본 이름으로도 충분해요.\n새로운 분위기가 필요하면 뽑아보세요.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 24 / 15,
                            color: ProfileStyle.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ProfileSecondaryButton(
                          label: '닉네임 뽑기',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  CosmeticGachaPage(nickname: widget.nickname),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  '종류별로 하나씩 선택하거나, 사용하지 않아도 돼요.',
                  style: ProfileStyle.caption,
                ),
              ],
            ),
            actions: CosmeticAction(
              label: _appearance.isBasic ? '기본 모습으로 적용' : '이대로 적용',
              hint: '현재는 미리보기만 제공하며, 채팅에는 적용되지 않아요.',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('미리보기예요. 실제 아이템 적용은 준비 중이에요.')),
              ),
            ),
          ),
        );
  Widget _itemGrid() {
    const labels = [
      ['사용 안 함', '달러 그린', '코발트 블루', '차분한 자주'],
      ['사용 안 함', '선명한 고딕', '차분한 명조', '둥근 고딕'],
      ['사용 안 함', '형광펜', '얇은 테두리', '반투명 배경'],
    ];
    final selected = [
      _appearance.color,
      _appearance.font,
      _appearance.background,
    ][_selected];
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col > 0) const SizedBox(width: 12),
                Expanded(
                  child: _itemCard(
                    row * 2 + col,
                    labels[_selected][row * 2 + col],
                    selected,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _itemCard(int index, String label, int selected) => Semantics(
    selected: index == selected,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: index == selected
              ? ProfileStyle.action
              : const Color(0xFFE1E6E2),
          width: index == selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            setState(() => _appearance = _appearance.select(_selected, index)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selected == 2
                      ? Colors.white
                      : const Color(0xFFF5F7F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CosmeticNickname(
                  nickname: widget.nickname,
                  selection: _appearance.select(_selected, index),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  height: 20 / 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                index == 0
                    ? '기본 $_category'
                    : index == selected
                    ? '✓ 선택됨'
                    : '샘플 아이템',
                style: ProfileStyle.caption.copyWith(
                  color: index == selected
                      ? ProfileStyle.action
                      : ProfileStyle.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
