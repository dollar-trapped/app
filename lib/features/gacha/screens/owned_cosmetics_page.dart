import 'cosmetic_gacha_page.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../shared/data/dollar_repository.dart';
import '../../profile/widgets/profile_layout.dart';
import '../../exchange/widgets/period_tab.dart';
import '../data/cosmetic_models.dart';
import '../widgets/cosmetic_layout.dart';
import '../widgets/server_cosmetic_preview.dart';

class OwnedCosmeticsPage extends StatefulWidget {
  const OwnedCosmeticsPage({
    super.key,
    required this.repository,
    required this.nickname,
  });
  final DollarRepository repository;
  final String nickname;
  @override
  State<OwnedCosmeticsPage> createState() => _OwnedCosmeticsPageState();
}

class _OwnedCosmeticsPageState extends State<OwnedCosmeticsPage> {
  static const types = ['NAME_COLOR', 'NAME_FONT', 'NAME_BACKGROUND'];
  static const labels = ['글자색', '글꼴', '배경'];
  CosmeticInventory? _inventory;
  final List<String?> _ids = [null, null, null];
  int _tab = 0;
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final inventory = await widget.repository.getMyCosmetics();
      if (!mounted) return;
      setState(() {
        _inventory = inventory;
        _ids[0] = inventory.equipment.colorId;
        _ids[1] = inventory.equipment.fontId;
        _ids[2] = inventory.equipment.backgroundId;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.actionableUserMessage
              : '아이템을 불러오지 못했어요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  CosmeticItem? _item(String? id) {
    for (final item in _inventory?.items ?? <CosmeticItem>[]) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _save() async {
    if (_busy || _inventory == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.equipCosmetics(
        CosmeticEquipment(
          colorId: _ids[0],
          fontId: _ids[1],
          backgroundId: _ids[2],
          version: _inventory!.equipment.version,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장식을 적용했어요. 새로 보내는 채팅부터 반영돼요.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      // Reload the version before another write rather than overwriting a newer selection.
      if (e is ApiException && e.statusCode == 409) {
        await _load();
        if (mounted) {
          setState(() => _error = '다른 곳에서 장착이 변경되어 최신 상태를 불러왔어요. 다시 선택해 주세요.');
        }
      } else {
        setState(
          () => _error = e is ApiException
              ? e.actionableUserMessage
              : '장착을 저장하지 못했어요. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items =
        _inventory?.items.where((e) => e.type == types[_tab]).toList() ??
        <CosmeticItem>[];
    return ProfileLayout(
      title: '내 아이템',
      action: TextButton(
        onPressed: _busy || _inventory == null
            ? null
            : () => setState(() => _ids.fillRange(0, 3, null)),
        child: const Text('모두 해제'),
      ),
      child: CosmeticContent(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ServerCosmeticPreview(
              nickname: widget.nickname,
              color: _item(_ids[0]),
              font: _item(_ids[1]),
              background: _item(_ids[2]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: PeriodTab(
                      label: labels[i],
                      selected: _tab == i,
                      onPressed: () => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('보유한 ${labels[_tab]} · ${items.length}개'),
            const SizedBox(height: 16),
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              if (_error!.isNotEmpty)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('다시 불러오기'),
              ),
            ],
            if (_inventory != null) ...[
              for (var row = 0; row < (items.length + 2) ~/ 2; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var col = 0; col < 2; col++) ...[
                        if (col > 0) const SizedBox(width: 12),
                        Expanded(
                          child: row * 2 + col <= items.length
                              ? _card(
                                  row * 2 + col == 0
                                      ? null
                                      : items[row * 2 + col - 1],
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              if (items.isEmpty)
                Text(
                  '아직 모은 ${labels[_tab]}이 없어요.',
                  style: ProfileStyle.caption,
                ),
            ],
            if (items.isEmpty && _inventory != null)
              TextButton(
                onPressed: _busy
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CosmeticGachaPage(
                              repository: widget.repository,
                              nickname: widget.nickname,
                            ),
                          ),
                        );
                        if (mounted) await _load();
                      },
                child: const Text('닉네임 뽑기'),
              ),
            const SizedBox(height: 16),
            const Text(
              '종류별로 하나씩 선택하거나, 사용하지 않아도 돼요.',
              style: ProfileStyle.caption,
            ),
          ],
        ),
        actions: CosmeticAction(
          label: _ids.every((id) => id == null) ? '기본 모습으로 적용' : '이대로 적용',
          hint: '적용하면 새로 보내는 채팅부터 반영돼요. 이전 메시지는 바뀌지 않아요.',
          onPressed: _busy || _inventory == null ? null : _save,
        ),
      ),
    );
  }

  Widget _card(CosmeticItem? item) {
    final selected = _ids[_tab] == item?.id;
    final preview = [_item(_ids[0]), _item(_ids[1]), _item(_ids[2])];
    preview[_tab] = item;
    return Semantics(
      selected: selected,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? ProfileStyle.action : const Color(0xFFE1E6E2),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: _busy ? null : () => setState(() => _ids[_tab] = item?.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: const BoxConstraints(minHeight: 132),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  alignment: Alignment.center,
                  child: ServerCosmeticNickname(
                    nickname: widget.nickname,
                    color: preview[0],
                    font: preview[1],
                    background: preview[2],
                  ),
                ),
                const SizedBox(height: 4),
                Text(item?.name ?? '사용 안 함'),
                const SizedBox(height: 4),
                Text(
                  selected
                      ? '✓ 선택됨'
                      : item == null
                      ? '기본 ${labels[_tab]}'
                      : '보유 중',
                  style: ProfileStyle.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
