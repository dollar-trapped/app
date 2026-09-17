import 'package:flutter/material.dart';
import '../../profile/widgets/profile_layout.dart';

/// Presentation-only combinations. Never persisted or used by the chat service.
class CosmeticSelection {
  const CosmeticSelection({this.color = 0, this.font = 0, this.background = 0});
  final int color;
  final int font;
  final int background;
  static const colors = [
    ProfileStyle.ink,
    ProfileStyle.action,
    Color(0xFF1967D2),
    Color(0xFF803E85),
    Color(0xFF906719),
  ];
  bool get isBasic => color == 0 && font == 0 && background == 0;
  CosmeticSelection select(int category, int value) => CosmeticSelection(
    color: category == 0 ? value : color,
    font: category == 1 ? value : font,
    background: category == 2 ? value : background,
  );
}

class CosmeticNickname extends StatelessWidget {
  const CosmeticNickname({
    super.key,
    required this.nickname,
    required this.selection,
  });
  final String nickname;
  final CosmeticSelection selection;
  @override
  Widget build(BuildContext context) => Container(
    padding: selection.background == 0
        ? EdgeInsets.zero
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: switch (selection.background) {
        1 => const Color(0xFFF7EDA6),
        3 => ProfileStyle.soft,
        _ => Colors.transparent,
      },
      border: selection.background == 2
          ? Border.all(color: ProfileStyle.action)
          : null,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      nickname,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: CosmeticSelection.colors[selection.color],
        fontSize: 16,
        height: 1.5,
        fontFamily: switch (selection.font) {
          2 => 'Noto Serif KR',
          3 => 'Jua',
          _ => 'Noto Sans KR',
        },
        fontWeight: selection.font == 3 ? FontWeight.w400 : FontWeight.w700,
      ),
    ),
  );
}

class CosmeticChatPreview extends StatelessWidget {
  const CosmeticChatPreview({
    super.key,
    required this.nickname,
    this.holdingLabel,
    this.selection = const CosmeticSelection(),
  });
  final String nickname;
  final String? holdingLabel;
  final CosmeticSelection selection;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7F5),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('채팅 미리보기', style: ProfileStyle.caption),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CosmeticNickname(nickname: nickname, selection: selection),
            if (holdingLabel != null)
              Text(holdingLabel!, style: ProfileStyle.caption),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          '오늘도 같이 버텨봅시다.',
          style: TextStyle(fontSize: 15, height: 24 / 15),
        ),
      ],
    ),
  );
}
