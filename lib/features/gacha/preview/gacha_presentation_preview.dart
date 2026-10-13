import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../cosmetics/models/cosmetic_models.dart';
import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import '../../shared/data/mock_dollar_repository.dart';
import '../data/gacha_models.dart';
import '../presentation/gacha_presentation.dart';
import '../presentation/gacha_result.dart';
import '../presentation/grade_config.dart';
import '../widgets/case_reward_card.dart';
import '../widgets/batch_reward_summary.dart';

/// No network, currency, random selection or inventory mutation.
class GachaPresentationPreview extends StatefulWidget {
  const GachaPresentationPreview({super.key});
  @override
  State<GachaPresentationPreview> createState() => _PreviewState();
}

class _PreviewState extends State<GachaPresentationPreview> {
  GachaGrade _grade = GachaGrade.special;
  GachaQuality _quality = GachaQuality.high;
  int _count = 1;
  late final _items = _load();
  Future<List<CosmeticItem>> _load() async {
    final json =
        jsonDecode(
              await rootBundle.loadString(
                'config/cosmetic_catalog_expansion.json',
              ),
            )
            as Map;
    return (json['items'] as List)
        .map((item) => CosmeticItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  void _play(List<CosmeticItem> items) {
    final grades = _count == 1
        ? [_grade]
        : [
            for (var i = 0; i < 10; i++)
              i == 6
                  ? _grade
                  : (_grade != GachaGrade.common && i == 3
                        ? GachaGrade.rare
                        : GachaGrade.common),
          ];
    final draws = [
      for (var i = 0; i < grades.length; i++)
        CosmeticDraw(
          item: items.firstWhere(
            (item) => GachaGrade.fromServer(item.rarity) == grades[i],
          ),
          duplicate: i.isOdd,
          chipsGranted: i.isOdd ? [1, 3, 5][grades[i].index] : 0,
          ticketsAfter: 0,
        ),
    ];
    final repository = MockDollarRepository();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GachaPresentation(
          result: GachaResult.fromDraws(draws),
          quality: _quality,
          previewBuilder: (context, i) {
            final item = draws[i].item;
            return FittedBox(
              child: ServerCosmeticNickname(
                nickname: '달러물림',
                color: item.type == 'NAME_COLOR' ? item : null,
                font: item.type == 'NAME_FONT' ? item : null,
                defaultTextColor: item.type == 'NAME_FONT'
                    ? Colors.white
                    : null,
                background: item.type == 'NAME_BACKGROUND' ? item : null,
                size: 34,
              ),
            );
          },
          resultBuilder: (context) => _count == 10
              ? BatchRewardSummary(
                  draws: draws,
                  nickname: '달러물림',
                  repository: repository,
                  allowEquip: false,
                )
              : CaseRewardCard(
                  repository: repository,
                  nickname: '달러물림',
                  result: draws.single,
                  allowEquip: false,
                ),
          onFinish: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('달러 가챠 · 연출 데모')),
    body: FutureBuilder<List<CosmeticItem>>(
      future: _items,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('확정된 예시 보상으로 재생합니다. 뽑기권을 사용하지 않습니다.'),
          const SizedBox(height: 24),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('1연차')),
              ButtonSegment(value: 10, label: Text('10연차')),
            ],
            selected: {_count},
            onSelectionChanged: (values) =>
                setState(() => _count = values.single),
          ),
          const SizedBox(height: 24),
          RadioGroup<GachaGrade>(
            groupValue: _grade,
            onChanged: (value) => setState(() => _grade = value!),
            child: Column(
              children: [
                for (final grade in GachaGrade.values)
                  RadioListTile<GachaGrade>(
                    title: Text(
                      _count == 1
                          ? GradeConfig.defaults[grade]!.label
                          : switch (grade) {
                              GachaGrade.common => '전부 커먼',
                              GachaGrade.rare => '레어 최고',
                              GachaGrade.special => '스페셜 포함',
                            },
                    ),
                    value: grade,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SegmentedButton<GachaQuality>(
            segments: const [
              ButtonSegment(value: GachaQuality.high, label: Text('High')),
              ButtonSegment(value: GachaQuality.low, label: Text('Low')),
            ],
            selected: {_quality},
            onSelectionChanged: (values) =>
                setState(() => _quality = values.single),
          ),
          const SizedBox(height: 32),
          FilledButton(
            key: const Key('gacha-demo-play'),
            onPressed: snapshot.hasData ? () => _play(snapshot.data!) : null,
            child: const Text('연출 재생'),
          ),
          if (snapshot.hasError) const Text('미리보기 목록을 불러오지 못했습니다.'),
          const SizedBox(height: 12),
          const Text('화면 터치: 전체 결과로 건너뛰기\n오디오: NoOp · 햅틱: 기기 기본 피드백'),
        ],
      ),
    ),
  );
}
