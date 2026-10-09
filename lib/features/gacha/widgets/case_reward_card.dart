import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../cosmetics/models/cosmetic_models.dart';
import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import '../../shared/data/dollar_repository.dart';
import '../data/gacha_models.dart';
import 'dollar_case_reveal.dart';

/// Revealed inside the case scene; equipping never navigates to another route.
class CaseRewardCard extends StatefulWidget {
  const CaseRewardCard({
    super.key,
    required this.repository,
    required this.nickname,
    required this.result,
    this.onAgain,
  });
  final DollarRepository repository;
  final String nickname;
  final CosmeticDraw result;
  final VoidCallback? onAgain;
  @override
  State<CaseRewardCard> createState() => _CaseRewardCardState();
}

class _CaseRewardCardState extends State<CaseRewardCard> {
  bool _busy = false, _applied = false;
  String? _error;
  Future<void> _apply() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final inventory = await widget.repository.getMyCosmetics();
      if (!mounted) return;
      final e = inventory.equipment, item = widget.result.item;
      await widget.repository.equipCosmetics(
        CosmeticEquipment(
          colorId: item.type == 'NAME_COLOR' ? item.id : e.colorId,
          fontId: item.type == 'NAME_FONT' ? item.id : e.fontId,
          backgroundId: item.type == 'NAME_BACKGROUND'
              ? item.id
              : e.backgroundId,
          version: e.version,
        ),
      );
      if (mounted) setState(() => _applied = true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.actionableUserMessage
              : '장착하지 못했어요. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draw = widget.result, item = draw.item;
    final accent = dollarRarityColor(item.rarity);
    return PopScope(
      canPop: !_busy,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF172820),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: .6)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: .1), blurRadius: 24),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.rarity,
              style: TextStyle(color: accent, letterSpacing: 2),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ServerCosmeticNickname(
                  nickname: widget.nickname,
                  color: item.type == 'NAME_COLOR' ? item : null,
                  font: item.type == 'NAME_FONT' ? item : null,
                  background: item.type == 'NAME_BACKGROUND' ? item : null,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              draw.duplicate
                  ? '중복 보상으로 달러칩 ${draw.chipsGranted}개를 받았어요.'
                  : '새로운 아이템',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFAFC6BA)),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Color(0xFFFFAAAA))),
            TextButton(
              onPressed:
                  _busy ||
                      _applied ||
                      ![
                        'NAME_COLOR',
                        'NAME_FONT',
                        'NAME_BACKGROUND',
                      ].contains(item.type)
                  ? null
                  : _apply,
              child: Text(
                _busy
                    ? '적용 중…'
                    : _applied
                    ? '적용 완료'
                    : '지금 적용',
                style: TextStyle(color: accent),
              ),
            ),
            if (_applied)
              const Text(
                '새로 보내는 채팅부터 반영돼요. 이전 메시지는 바뀌지 않아요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFAFC6BA), fontSize: 12),
              ),
            if (widget.onAgain != null)
              Text(
                draw.ticketsAfter > 0
                    ? '남은 뽑기권 ${draw.ticketsAfter}장 · 1장 사용'
                    : '뽑기권이 없어요. 뽑기권을 얻은 뒤 다시 뽑아주세요.',
                style: const TextStyle(color: Color(0xFFAFC6BA), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            if (widget.onAgain != null)
              FilledButton(
                onPressed: _busy || draw.ticketsAfter <= 0
                    ? null
                    : widget.onAgain,
                child: const Text('다시 뽑기'),
              ),
          ],
        ),
      ),
    );
  }
}
