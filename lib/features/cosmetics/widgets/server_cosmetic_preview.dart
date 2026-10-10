import '../rendering/effect_registry.dart';
import '../rendering/cosmetic_motion.dart';
import '../rendering/effects/gradient_effect.dart';
import '../rendering/effects/cosmetic_scene_painter.dart';
import '../rendering/effects/shimmer_effect.dart';
import '../rendering/effects/lattice_effect.dart';
import '../rendering/effects/broken_glass_effect.dart';
import '../rendering/effects/cosmetic_text_painter.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/cosmetic_models.dart';

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
  static Color? parseColor(Object? value) =>
      CosmeticEffectRegistry.parseColor(value);

  @override
  Widget build(BuildContext context) {
    // Unknown effect tokens use the complete basic nickname. This also avoids
    // displaying a known text effect against an unsupported background.
    for (final item in [color, font, background]) {
      final token = item?.appearance['styleToken'];
      if (token != null &&
          !CosmeticEffectRegistry.supports(item!.type, token)) {
        return _render(
          0,
          const CosmeticEffect(),
          const CosmeticEffect(),
          basic: true,
          context: context,
        );
      }
    }
    final textEffect = CosmeticEffectRegistry.text(
      color?.appearance['nameColor'],
      styleToken: color?.appearance['styleToken'],
    );
    final backgroundEffect = CosmeticEffectRegistry.background(
      background?.appearance['nameBackground'],
      styleToken: background?.appearance['styleToken'],
    );
    final moving = textEffect.animated || backgroundEffect.animated;
    Widget render(double phase) =>
        _render(phase, textEffect, backgroundEffect, context: context);
    return moving
        ? CosmeticMotion(
            duration: Duration(seconds: textEffect.textScene == null ? 4 : 6),
            builder: render,
          )
        : render(0);
  }

  Widget _render(
    double phase,
    CosmeticEffect textEffect,
    CosmeticEffect backgroundEffect, {
    bool basic = false,
    required BuildContext context,
  }) {
    final bgColors = backgroundEffect.colors;
    final textColors = textEffect.colors;
    final darkBackground = backgroundEffect.dark;
    LinearGradient gradient(
      List<Color> colors,
      CosmeticEffect effect, {
      bool forText = false,
    }) {
      if (effect.pulse) {
        final glow = (1 - math.cos(phase * math.pi * 2)) / 2 * .55;
        return GradientEffect.gradient(
          colors
              .map((color) => Color.lerp(color, const Color(0xFFC63C63), glow)!)
              .toList(),
          phase: 0,
        );
      }
      if (effect.shimmer && forText) {
        return GradientEffect.shimmer(colors, phase: phase);
      }
      return GradientEffect.gradient(
        colors,
        // These scenes move their own light bands over a steady dark base.
        phase:
            effect.animated &&
                !effect.shimmer &&
                effect.scene != CosmeticScene.aurora &&
                effect.scene != CosmeticScene.starlight
            ? phase
            : 0,
      );
    }

    final textStyle = TextStyle(
      fontSize: size,
      height: 1.5,
      fontWeight: basic
          ? FontWeight.w700
          : CosmeticEffectRegistry.fontWeight(font?.appearance['nameFont']),
      color: textColors != null
          ? Colors.white
          : textEffect.solid ??
                (darkBackground ? Colors.white : const Color(0xFF151916)),
      fontFamily: basic
          ? 'Noto Sans KR'
          : CosmeticEffectRegistry.font(font?.appearance['nameFont']),
    );
    final text = Text(
      nickname,
      textAlign: TextAlign.center,
      style: textEffect.textScene == null
          ? textStyle
          : textStyle.copyWith(color: Colors.transparent),
    );
    Widget content = textEffect.textScene != null
        ? CustomPaint(
            foregroundPainter: CosmeticTextPainter(
              nickname: nickname,
              textStyle: textStyle,
              scene: textEffect.textScene!,
              phase: phase,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            ),
            child: text,
          )
        : textColors == null
        ? text
        : ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => gradient(
              textColors,
              textEffect,
              forText: true,
            ).createShader(bounds),
            child: text,
          );
    if (backgroundEffect.lattice) {
      content = CustomPaint(
        painter: const LatticeEffect(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: content,
        ),
      );
    }
    if (backgroundEffect.brokenGlass) {
      content = CustomPaint(
        painter: const BrokenGlassEffect(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: content,
        ),
      );
    }
    if (backgroundEffect.scene != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: CosmeticScenePainter(
                    style: backgroundEffect.scene!.token,
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
    if (backgroundEffect.shimmer) {
      content = Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: ShimmerEffect(phase: phase)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: content,
          ),
        ],
      );
    }
    return Container(
      padding:
          backgroundEffect.scene != null ||
              backgroundEffect.shimmer ||
              backgroundEffect.lattice ||
              backgroundEffect.brokenGlass
          ? EdgeInsets.zero
          : background == null || basic
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: bgColors != null
            ? null
            : backgroundEffect.solid ?? Colors.transparent,
        gradient: bgColors == null
            ? null
            : gradient(bgColors, backgroundEffect),
        border: darkBackground
            ? Border.all(color: const Color(0xFFBDB4E8))
            : null,
      ),
      child: content,
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
        const Text(
          '채팅 미리보기',
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF667069),
            fontWeight: FontWeight.w400,
          ),
        ),
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
