import '../../../core/ads/ad_config.dart';
import '../services/pending_draw_store.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../shared/data/dollar_repository.dart';
import '../../profile/widgets/profile_layout.dart';
import '../../ads/widgets/rewarded_test_button.dart';
import '../data/cosmetic_models.dart';
import '../services/request_id.dart';
import '../widgets/cosmetic_layout.dart';
import '../widgets/server_cosmetic_preview.dart';
import 'owned_cosmetics_page.dart';

class LiveGachaPage extends StatefulWidget {
  const LiveGachaPage({
    super.key,
    required this.repository,
    required this.nickname,
    this.pendingDrawStore = const SecurePendingDrawStore(),
  });
  final PendingDrawStore pendingDrawStore;
  final DollarRepository repository;
  final String nickname;
  @override
  State<LiveGachaPage> createState() => _LiveGachaPageState();
}

class _LiveGachaPageState extends State<LiveGachaPage> {
  CosmeticInventory? _inventory;
  CosmeticCatalog? _catalog;
  String? _error, _drawRequestId, _userId;
  bool _loading = true, _drawing = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository.getMyCosmetics(),
        widget.repository.getCosmeticCatalog(),
      ]);
      if (!mounted) return;
      final user = await widget.repository.getMe();
      String? pending;
      try {
        pending = await widget.pendingDrawStore.read(user.id);
      } catch (_) {
        /* Drawing itself requires a successful durable write. */
      }
      if (!mounted) return;
      _userId = user.id;
      _drawRequestId ??= pending;
      setState(() {
        _inventory = results[0] as CosmeticInventory;
        _catalog = results[1] as CosmeticCatalog;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = e is ApiException ? e.userMessage : '뽑기 정보를 불러오지 못했어요.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _draw() async {
    if (_drawing) return;
    setState(() {
      _drawing = true;
      _error = null;
    });
    try {
      _userId ??= (await widget.repository.getMe()).id;
      _drawRequestId ??=
          await widget.pendingDrawStore.read(_userId!) ?? newRequestId();
      await widget.pendingDrawStore.write(_userId!, _drawRequestId!);
      final result = await widget.repository.drawCosmetic(_drawRequestId!);
      await widget.pendingDrawStore.clear(_userId!);
      _drawRequestId = null;
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LiveDrawResultPage(
            repository: widget.repository,
            nickname: widget.nickname,
            result: result,
          ),
        ),
      );
      if (mounted) await _load();
    } catch (e) {
      // Keep the request key after any ambiguous failure; a retry cannot spend twice.
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.userMessage
              : '뽑기 결과를 확인하지 못했어요. 같은 요청으로 다시 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _drawing = false);
    }
  }

  void _showCatalog() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('획득 목록 · 확률 안내', style: ProfileStyle.title),
            const SizedBox(height: 16),
            for (final entry in _catalog!.probabilities.entries)
              Text('${entry.key}: ${(entry.value / 100).toStringAsFixed(2)}%'),
            Text(
              '같은 희귀도 안에서는 균등 확률이에요. 중복 시 설정 토큰 ${_catalog!.duplicateTokens}개를 받아요.',
            ),
            const SizedBox(height: 16),
            for (final item in _catalog!.items.where((e) => e.drawable))
              ListTile(
                title: Text(item.name),
                subtitle: Text('${item.type} · ${item.rarity}'),
              ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_drawing,
    child: ProfileLayout(
      title: '닉네임 뽑기',
      child: CosmeticContent(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('이름은 그대로.\n분위기는 새롭게.', style: ProfileStyle.title),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('내 뽑기권'),
                Text(
                  _inventory == null ? '—' : '${_inventory!.tickets}장',
                  key: const Key('gacha-ticket-balance'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RewardedTestButton(
              repository: widget.repository,
              enabled: !_drawing && !_loading,
              onVerified: _load,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ProfileStyle.forest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '달러물림 / 닉네임 컬렉션',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.nickname,
                    style: const TextStyle(
                      fontFamily: 'Noto Serif KR',
                      fontSize: 36,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '평단은 못 바꿔도, 분위기는 바꿉니다.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('글자색 · 글꼴 · 배경을 모아보세요.'),
            TextButton(
              onPressed: _catalog == null ? null : _showCatalog,
              child: const Text('획득 목록 · 확률 안내  ›'),
            ),
            TextButton(
              onPressed: _drawing
                  ? null
                  : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => OwnedCosmeticsPage(
                            repository: widget.repository,
                            nickname: widget.nickname,
                          ),
                        ),
                      );
                      if (mounted) await _load();
                    },
              child: const Text('내 아이템 · 꾸미기'),
            ),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: _loading || _drawing ? null : _load,
                child: const Text('정보 다시 불러오기'),
              ),
            ],
          ],
        ),
        actions: CosmeticAction(
          label: _drawing
              ? '뽑기 처리 중…'
              : _drawRequestId != null
              ? '뽑기 결과 다시 확인'
              : (_inventory?.tickets ?? 0) > 0
              ? '1회 뽑기'
              : '뽑기권이 필요해요',
          hint: AdConfig.isTest
              ? '테스트 광고 사용 중 · 보상은 서버 검증 후 반영돼요.'
              : '광고 보상은 서버 검증 후 반영돼요.',
          onPressed:
              !_loading &&
                  !_drawing &&
                  (_drawRequestId != null || (_inventory?.tickets ?? 0) > 0)
              ? _draw
              : null,
        ),
      ),
    ),
  );
}

class LiveDrawResultPage extends StatefulWidget {
  const LiveDrawResultPage({
    super.key,
    required this.repository,
    required this.nickname,
    required this.result,
  });
  final DollarRepository repository;
  final String nickname;
  final CosmeticDraw result;
  @override
  State<LiveDrawResultPage> createState() => _LiveDrawResultPageState();
}

class _LiveDrawResultPageState extends State<LiveDrawResultPage> {
  bool _busy = false;
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
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.userMessage
              : '장착하지 못했어요. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result, item = result.item;
    final color = item.type == 'NAME_COLOR' ? item : null,
        font = item.type == 'NAME_FONT' ? item : null,
        bg = item.type == 'NAME_BACKGROUND' ? item : null;
    return PopScope(
      canPop: !_busy,
      child: ProfileLayout(
        title: '뽑기 결과',
        child: CosmeticContent(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                result.duplicate ? '이미 보유한 아이템' : '새로운 아이템',
                style: const TextStyle(color: ProfileStyle.action),
              ),
              const SizedBox(height: 24),
              Text(
                result.duplicate ? '익숙한 취향을\n다시 만났어요.' : '새로운 취향을\n뽑았어요.',
                style: ProfileStyle.title,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${item.type} · ${item.rarity}',
                      style: ProfileStyle.caption,
                    ),
                    const SizedBox(height: 16),
                    ServerCosmeticNickname(
                      nickname: widget.nickname,
                      color: color,
                      font: font,
                      background: bg,
                      size: 32,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ServerCosmeticPreview(
                nickname: widget.nickname,
                color: color,
                font: font,
                background: bg,
              ),
              const SizedBox(height: 24),
              Text(
                result.duplicate
                    ? '중복 보상으로 설정 토큰 ${result.tokensGranted}개를 받았어요.'
                    : '아이템은 내 아이템에 보관됐어요.\n언제든 꺼내 쓸 수 있어요.',
                style: ProfileStyle.caption,
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
          actions: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CosmeticAction(
                label: _busy ? '적용 중…' : '지금 적용',
                hint: '',
                onPressed:
                    _busy ||
                        ![
                          'NAME_COLOR',
                          'NAME_FONT',
                          'NAME_BACKGROUND',
                        ].contains(item.type)
                    ? null
                    : _apply,
              ),
              const SizedBox(height: 12),
              ProfileSecondaryButton(
                label: '보관만 하기',
                onPressed: () {
                  if (!_busy) Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
