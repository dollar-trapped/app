import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cosmetic_models.dart';
import '../widgets/server_cosmetic_preview.dart';

/// Development-only design fixture; never used for ownership or real draws.
class CosmeticExpansionPreviewPage extends StatefulWidget {
  const CosmeticExpansionPreviewPage({super.key});
  @override
  State<CosmeticExpansionPreviewPage> createState() =>
      _CosmeticExpansionPreviewPageState();
}

class _CosmeticExpansionPreviewPageState
    extends State<CosmeticExpansionPreviewPage> {
  late final Future<List<CosmeticItem>> _items = _load();
  String? _type;
  bool _play = true;
  CosmeticItem? _color, _font, _background;

  Future<List<CosmeticItem>> _load() async {
    final json =
        jsonDecode(
              await rootBundle.loadString(
                'config/cosmetic_catalog_expansion.json',
              ),
            )
            as Map<String, dynamic>;
    return (json['items'] as List)
        .map(
          (value) =>
              CosmeticItem.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
  }

  void _select(CosmeticItem item) => setState(() {
    switch (item.type) {
      case 'NAME_COLOR':
        _color = item;
      case 'NAME_FONT':
        _font = item;
      case 'NAME_BACKGROUND':
        _background = item;
    }
  });

  @override
  Widget build(BuildContext context) {
    final systemReducedMotion = MediaQuery.disableAnimationsOf(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: !_play || MediaQuery.disableAnimationsOf(context),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('장식 개발 미리보기')),
        body: FutureBuilder<List<CosmeticItem>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('미리보기를 불러오지 못했습니다.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('30종 디자인 시안 · 실제 획득 목록은 서버 등록 후 반영됩니다.'),
                const SizedBox(height: 16),
                ServerCosmeticPreview(
                  nickname: '달러물림',
                  color: _color,
                  font: _font,
                  background: _background,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [
                          _color?.name,
                          _font?.name,
                          _background?.name,
                        ].whereType<String>().join(' · '),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _color = null;
                        _font = null;
                        _background = null;
                      }),
                      child: const Text('모두 해제'),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('움직임 재생'),
                  value: _play && !systemReducedMotion,
                  onChanged: systemReducedMotion
                      ? null
                      : (value) => setState(() => _play = value),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in <String?, String>{
                      null: '전체',
                      'NAME_COLOR': '글자색',
                      'NAME_FONT': '글꼴',
                      'NAME_BACKGROUND': '배경',
                    }.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _type == entry.key,
                        onSelected: (_) => setState(() => _type = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final item in items.where(
                  (item) => _type == null || item.type == _type,
                ))
                  Card(
                    child: InkWell(
                      onTap: () => _select(item),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.name} · ${switch (item.rarity) {
                                'COMMON' => '일반',
                                'RARE' => '희귀',
                                _ => '특별',
                              }}',
                            ),
                            const SizedBox(height: 12),
                            ServerCosmeticNickname(
                              nickname: '달러물림',
                              size: 16,
                              color: item.type == 'NAME_COLOR' ? item : _color,
                              font: item.type == 'NAME_FONT' ? item : _font,
                              background: item.type == 'NAME_BACKGROUND'
                                  ? item
                                  : _background,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
