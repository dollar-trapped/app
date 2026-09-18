import 'package:flutter/material.dart';
import '../../profile/widgets/profile_layout.dart';
import '../data/cosmetic_models.dart';

/// Only nickname styling is affected. Unknown server styles use basic rendering.
class ServerCosmeticNickname extends StatelessWidget {
  const ServerCosmeticNickname({
    super.key,
    required this.nickname,
    this.color,
    this.font,
    this.background,
    this.size = 16,
  });
  final String nickname;
  final CosmeticItem? color, font, background;
  final double size;
  static Color? parseColor(Object? value) {
    if (value is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      return null;
    }
    return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final bg = background?.appearance['nameBackground'];
    return Container(
      padding: background == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: switch (bg) {
          'soft_gray' => const Color(0xFFEDEFEF),
          'gold_foil' => const Color(0xFFF7EDA6),
          _ => Colors.transparent,
        },
        gradient: bg == 'sky_gradient'
            ? const LinearGradient(
                colors: [Color(0xFFE4F4FF), Color(0xFFC8DFFF)],
              )
            : null,
      ),
      child: Text(
        nickname,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          height: 1.5,
          fontWeight: FontWeight.w700,
          color: parseColor(color?.appearance['nameColor']) ?? ProfileStyle.ink,
          fontFamily: switch (font?.appearance['nameFont']) {
            'rounded_gothic' => 'Jua',
            'serif_classic' => 'Noto Serif KR',
            'handwriting' => 'Nanum Pen Script',
            _ => 'Noto Sans KR',
          },
        ),
      ),
    );
  }
}

class ServerCosmeticPreview extends StatelessWidget {
  const ServerCosmeticPreview({
    super.key,
    required this.nickname,
    this.color,
    this.font,
    this.background,
  });
  final String nickname;
  final CosmeticItem? color, font, background;
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
        ServerCosmeticNickname(
          nickname: nickname,
          color: color,
          font: font,
          background: background,
        ),
        const SizedBox(height: 12),
        const Text(
          '오늘도 같이 버텨봅시다.',
          style: TextStyle(fontSize: 15, height: 1.6),
        ),
      ],
    ),
  );
}
