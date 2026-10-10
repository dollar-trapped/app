import 'package:flutter/material.dart';

enum CosmeticScene {
  sakura('sakura_drift'),
  starry('starry_night'),
  bubble('bubble_party'),
  aurora('aurora'),
  starlight('starlight'),
  desert('desert_tumbleweed');

  const CosmeticScene(this.token);
  final String token;
}

enum CosmeticTextScene { blood, hologram }

/// App-owned parameters. The server only selects an existing appearance token.
class CosmeticEffect {
  const CosmeticEffect({
    this.colors,
    this.solid,
    this.animated = false,
    this.dark = false,
    this.scene,
    this.shimmer = false,
    this.pulse = false,
    this.lattice = false,
    this.brokenGlass = false,
    this.textScene,
  });
  final List<Color>? colors;
  final Color? solid;
  final bool animated, dark;
  final bool shimmer, pulse, lattice, brokenGlass;
  final CosmeticScene? scene;
  final CosmeticTextScene? textScene;
}

abstract final class CosmeticEffectRegistry {
  static const _basic = CosmeticEffect();
  static const textEffects = <String, CosmeticEffect>{
    'golden_shimmer': CosmeticEffect(
      animated: true,
      shimmer: true,
      colors: [Color(0xFF8F5F10), Color(0xFFC08A1D), Color(0xFF9C6611)],
    ),
    'crimson_pulse': CosmeticEffect(
      animated: true,
      pulse: true,
      colors: [Color(0xFF65172C), Color(0xFFA72A48), Color(0xFF741A32)],
    ),
    'blood_crimson': CosmeticEffect(
      animated: true,
      textScene: CosmeticTextScene.blood,
    ),
    'unstable_hologram': CosmeticEffect(
      animated: true,
      textScene: CosmeticTextScene.hologram,
    ),
    'sunset_gradient': CosmeticEffect(
      colors: [Color(0xFFA52F58), Color(0xFFB36116)],
    ),
    'ocean_gradient': CosmeticEffect(
      colors: [Color(0xFF126079), Color(0xFF4945A7)],
    ),
    'rainbow_flow': CosmeticEffect(
      animated: true,
      colors: [
        Color(0xFFAD2844),
        Color(0xFF915300),
        Color(0xFF16734A),
        Color(0xFF2752BB),
        Color(0xFF893BAC),
      ],
    ),
    'aurora_flow': CosmeticEffect(
      animated: true,
      colors: [Color(0xFF047163), Color(0xFF3D4AAF), Color(0xFF92428A)],
    ),
  };
  static const backgroundEffects = <String, CosmeticEffect>{
    'soft_gray': CosmeticEffect(solid: Color(0xFFEDEFEF)),
    'orange_solid': CosmeticEffect(solid: Color(0xFFFFE4CF)),
    'banana_solid': CosmeticEffect(solid: Color(0xFFFFF2B8)),
    'grape_solid': CosmeticEffect(solid: Color(0xFFE5F3CC)),
    'broken_glass': CosmeticEffect(solid: Color(0xFFE8F1F5), brokenGlass: true),
    'desert_tumbleweed': CosmeticEffect(
      animated: true,
      scene: CosmeticScene.desert,
      solid: Color(0xFFFFEDD0),
    ),
    'gold_foil': CosmeticEffect(solid: Color(0xFFF7EDA6)),
    'gold_foil_shimmer': CosmeticEffect(
      animated: true,
      shimmer: true,
      colors: [Color(0xFFE4C86D), Color(0xFFF7EDA6), Color(0xFFD8B955)],
    ),
    'sky_gradient': CosmeticEffect(
      colors: [Color(0xFFE4F4FF), Color(0xFFC8DFFF)],
    ),
    'mint_lattice': CosmeticEffect(solid: Color(0xFFE5F3EB), lattice: true),
    'pastel_cloud': CosmeticEffect(
      colors: [Color(0xFFFFE6EF), Color(0xFFE7E5FF), Color(0xFFDFF5F0)],
    ),
    'peach_blossom': CosmeticEffect(
      colors: [Color(0xFFFFE2D3), Color(0xFFFFDAE8)],
    ),
    'cosmic': CosmeticEffect(
      dark: true,
      colors: [Color(0xFF292443), Color(0xFF4D3666)],
    ),
    'aurora': CosmeticEffect(
      animated: true,
      dark: true,
      scene: CosmeticScene.aurora,
      colors: [Color(0xFF102D35), Color(0xFF25233E)],
    ),
    'starlight': CosmeticEffect(
      animated: true,
      dark: true,
      scene: CosmeticScene.starlight,
      colors: [Color(0xFF182340), Color(0xFF293554)],
    ),
    'sakura_drift': CosmeticEffect(
      animated: true,
      scene: CosmeticScene.sakura,
      colors: [Color(0xFFFFF0F5), Color(0xFFF7C9DB)],
    ),
    'starry_night': CosmeticEffect(
      animated: true,
      dark: true,
      scene: CosmeticScene.starry,
      colors: [Color(0xFF202845), Color(0xFF443662)],
    ),
    'bubble_party': CosmeticEffect(
      animated: true,
      scene: CosmeticScene.bubble,
      colors: [Color(0xFFE9F9FD), Color(0xFFF7E5F4)],
    ),
  };
  static const fonts = <String, String>{
    'rounded_gothic': 'Jua',
    'serif_classic': 'Noto Serif KR',
    'handwriting': 'Nanum Pen Script',
    'heavy_gothic': 'Black Han Sans',
    'future_square': 'Gugi',
    'gentle_dodum': 'Gowun Dodum',
    'playful_handwriting': 'Gaegu',
    'brush_script': 'Nanum Brush Script',
  };
  static const _legacyBackgrounds = {'soft_gray', 'gold_foil', 'sky_gradient'};

  // Fixed legacy format, retained for existing server items; no arbitrary JSON.
  static Color? parseColor(Object? value) {
    if (value is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value)) {
      return null;
    }
    return Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
  }

  static CosmeticEffect text(Object? color, {Object? styleToken}) =>
      styleToken == null
      ? CosmeticEffect(solid: parseColor(color))
      : textEffects[styleToken] ?? _basic;
  static CosmeticEffect background(Object? style, {Object? styleToken}) {
    if (styleToken != null) return backgroundEffects[styleToken] ?? _basic;
    return _legacyBackgrounds.contains(style)
        ? backgroundEffects[style]!
        : _basic;
  }

  static bool supports(String slot, Object? token) => switch (slot) {
    'NAME_COLOR' => textEffects.containsKey(token),
    'NAME_BACKGROUND' => backgroundEffects.containsKey(token),
    _ => false,
  };
  static String font(Object? token) => fonts[token] ?? 'Noto Sans KR';
  static FontWeight fontWeight(Object? token) =>
      const {
        'heavy_gothic',
        'future_square',
        'gentle_dodum',
        'brush_script',
      }.contains(token)
      ? FontWeight.w400
      : FontWeight.w700;
}
