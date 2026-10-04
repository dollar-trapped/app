import 'dart:math' as math;
import 'cosmetic_scene_painter.dart';
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

  static const _moving = {
    'rainbow_flow',
    'aurora_flow',
    'aurora',
    'starlight',
    ...CosmeticScenePainter.styles,
  };

  static List<Color>? _colors(Object? token) => switch (token) {
    'sakura_drift' => const [Color(0xFFFFF0F5), Color(0xFFF7C9DB)],
    'starry_night' => const [Color(0xFF202845), Color(0xFF443662)],
    'bubble_party' => const [Color(0xFFE9F9FD), Color(0xFFF7E5F4)],
    'sunset_gradient' => const [Color(0xFFA52F58), Color(0xFFB36116)],
    'ocean_gradient' => const [Color(0xFF126079), Color(0xFF4945A7)],
    'rainbow_flow' => const [
      Color(0xFFAD2844),
      Color(0xFF915300),
      Color(0xFF16734A),
      Color(0xFF2752BB),
      Color(0xFF893BAC),
    ],
    'aurora_flow' => const [
      Color(0xFF047163),
      Color(0xFF3D4AAF),
      Color(0xFF92428A),
    ],
    'sky_gradient' => const [Color(0xFFE4F4FF), Color(0xFFC8DFFF)],
    'aurora' => const [Color(0xFF173349), Color(0xFF235C57), Color(0xFF544274)],
    'starlight' => const [
      Color(0xFF282D59),
      Color(0xFF514481),
      Color(0xFF275574),
    ],
    'cosmic' => const [Color(0xFF292443), Color(0xFF4D3666)],
    'pastel_cloud' => const [
      Color(0xFFFFE6EF),
      Color(0xFFE7E5FF),
      Color(0xFFDFF5F0),
    ],
    'peach_blossom' => const [Color(0xFFFFE2D3), Color(0xFFFFDAE8)],
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final moving =
        _moving.contains(color?.appearance['nameColor']) ||
        _moving.contains(background?.appearance['nameBackground']);
    return moving ? _CosmeticMotion(builder: _render) : _render(0);
  }

  Widget _render(double phase) {
    final bg = background?.appearance['nameBackground'];
    final foreground = color?.appearance['nameColor'];
    final bgColors = _colors(bg);
    final textColors = _colors(foreground);
    final darkBackground = {
      'aurora',
      'starlight',
      'cosmic',
      'starry_night',
    }.contains(bg);
    LinearGradient gradient(List<Color> colors) => LinearGradient(
      begin: Alignment(-1 + (1 - math.cos(phase * math.pi * 2)), -1),
      end: Alignment(1 - (1 - math.cos(phase * math.pi * 2)), 1),
      colors: colors,
    );
    final text = Text(
      nickname,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: size,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: textColors != null
            ? Colors.white
            : parseColor(foreground) ??
                  (darkBackground ? Colors.white : ProfileStyle.ink),
        fontFamily: switch (font?.appearance['nameFont']) {
          'rounded_gothic' => 'Jua',
          'serif_classic' => 'Noto Serif KR',
          'handwriting' => 'Nanum Pen Script',
          _ => 'Noto Sans KR',
        },
      ),
    );
    Widget content = textColors == null
        ? text
        : ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                gradient(textColors).createShader(bounds),
            child: text,
          );
    if (CosmeticScenePainter.styles.contains(bg)) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CosmeticScenePainter(
                    style: bg as String,
                    phase: phase,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: content,
            ),
          ],
        ),
      );
    }
    return Container(
      padding: CosmeticScenePainter.styles.contains(bg)
          ? EdgeInsets.zero
          : background == null
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bgColors != null
            ? null
            : switch (bg) {
                'soft_gray' => const Color(0xFFEDEFEF),
                'gold_foil' => const Color(0xFFF7EDA6),
                _ => Colors.transparent,
              },
        gradient: bgColors == null ? null : gradient(bgColors),
        border: darkBackground
            ? Border.all(color: const Color(0xFFBDB4E8))
            : null,
      ),
      child: content,
    );
  }
}

class _CosmeticMotion extends StatefulWidget {
  const _CosmeticMotion({required this.builder});
  final Widget Function(double) builder;
  @override
  State<_CosmeticMotion> createState() => _CosmeticMotionState();
}

class _CosmeticMotionState extends State<_CosmeticMotion>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(_controller.value),
    ),
  );
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
