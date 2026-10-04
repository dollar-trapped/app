import 'cosmetic_models.dart';

// Design samples only; never part of inventory or the draw probability pool.
const _designs = <(String, String, String, String)>[
  ('흩날리는 벚꽃', 'NAME_BACKGROUND', 'sakura_drift', 'SPECIAL'),
  ('반짝이는 별밤', 'NAME_BACKGROUND', 'starry_night', 'SPECIAL'),
  ('버블 파티', 'NAME_BACKGROUND', 'bubble_party', 'SPECIAL'),
  ('춤추는 오로라', 'NAME_BACKGROUND', 'aurora', 'SPECIAL'),
  ('별빛 물결', 'NAME_BACKGROUND', 'starlight', 'SPECIAL'),
  ('흐르는 무지개', 'NAME_COLOR', 'rainbow_flow', 'SPECIAL'),
  ('오로라 잉크', 'NAME_COLOR', 'aurora_flow', 'SPECIAL'),
  ('노을빛', 'NAME_COLOR', 'sunset_gradient', 'RARE'),
  ('깊은 바다', 'NAME_COLOR', 'ocean_gradient', 'RARE'),
  ('솜사탕 구름', 'NAME_BACKGROUND', 'pastel_cloud', 'RARE'),
  ('복숭아 꽃', 'NAME_BACKGROUND', 'peach_blossom', 'RARE'),
  ('은하의 밤', 'NAME_BACKGROUND', 'cosmic', 'RARE'),
];
final cosmeticDesignSamples = _designs
    .map(
      (sample) => CosmeticItem(
        id: 'preview_${sample.$3}',
        type: sample.$2,
        name: sample.$1,
        rarity: sample.$4,
        appearance: {
          sample.$2 == 'NAME_BACKGROUND' ? 'nameBackground' : 'nameColor':
              sample.$3,
        },
      ),
    )
    .toList(growable: false);

bool sameCosmeticDesign(CosmeticItem a, CosmeticItem b) {
  final key = a.type == 'NAME_BACKGROUND' ? 'nameBackground' : 'nameColor';
  return a.type == b.type && a.appearance[key] == b.appearance[key];
}
