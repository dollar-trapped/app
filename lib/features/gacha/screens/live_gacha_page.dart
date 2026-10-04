import 'cosmetic_gacha_page.dart';
import '../data/gacha_models.dart';
import '../widgets/cosmetic_catalog_sheet.dart';
import '../widgets/ticket_reward_dialog.dart';
import '../../../core/ads/ad_config.dart';
import '../services/pending_draw_store.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../shared/data/dollar_repository.dart';
import '../../profile/widgets/profile_layout.dart';
import '../../ads/widgets/rewarded_test_button.dart';
import '../../cosmetics/models/cosmetic_models.dart';
import '../services/request_id.dart';
import '../../shared/widgets/cosmetic_layout.dart';
import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import '../../inventory/screens/owned_cosmetics_page.dart';
import '../widgets/gacha_reveal.dart';

class LiveGachaPage extends StatefulWidget {
  const LiveGachaPage({
    super.key,
    required this.repository,
    required this.nickname,
    this.pendingDrawStore = const SecurePendingDrawStore(),
    this.pendingExchangeStore = const SecurePendingDrawStore(
      prefix: 'pending_chip_exchange_',
    ),
  });
  final PendingDrawStore pendingDrawStore, pendingExchangeStore;
  final DollarRepository repository;
  final String nickname;
  @override
  State<LiveGachaPage> createState() => _LiveGachaPageState();
}

class _LiveGachaPageState extends State<LiveGachaPage> {
  bool get _hasExchangeChips =>
      _inventory != null &&
      _catalog != null &&
      _catalog!.chipExchangeCost > 0 &&
      _inventory!.dollarChips >= _catalog!.chipExchangeCost;

  bool _exchanging = false;
  String? _exchangeId;
  CosmeticInventory? _inventory;
  CosmeticCatalog? _catalog;
  bool _loadingCatalog = false;
  String? _error, _drawRequestId, _userId;
  bool _loading = true, _drawing = false, _awaitingDraw = false;
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
      String? pendingExchange;
      try {
        pendingExchange = await widget.pendingExchangeStore.read(user.id);
      } catch (_) {
        /* A successful write is required before exchange. */
      }
      if (!mounted) return;
      _exchangeId ??= pendingExchange;
      _userId = user.id;
      _drawRequestId ??= pending;
      setState(() {
        _inventory = results[0] as CosmeticInventory;
        _catalog = results[1] as CosmeticCatalog;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.actionableUserMessage
              : '뽑기 정보를 불러오지 못했어요.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exchangeChips() async {
    if (_exchanging || _drawing || _loading || _userId == null) return;
    setState(() {
      _exchanging = true;
      _error = null;
    });
    try {
      _exchangeId ??=
          await widget.pendingExchangeStore.read(_userId!) ?? newRequestId();
      await widget.pendingExchangeStore.write(_userId!, _exchangeId!);
      final result = await widget.repository.exchangeChips(_exchangeId!);
      await widget.pendingExchangeStore.clear(_userId!);
      _exchangeId = null;
      if (!mounted) return;
      final inventory = _inventory!;
      setState(
        () => _inventory = CosmeticInventory(
          items: inventory.items,
          equipment: inventory.equipment,
          tickets: result.ticketsAfter,
          dollarChips: result.chipsAfter,
        ),
      );
      await showTicketReward(context, chipCost: _catalog!.chipExchangeCost);
      if (!mounted) return;
      await _load();
    } catch (error) {
      // Keep the operation ID on ambiguous failures, including app restarts.
      if (error is ApiException && error.code == 'INSUFFICIENT_DOLLAR_CHIP') {
        try {
          await widget.pendingExchangeStore.clear(_userId!);
          _exchangeId = null;
        } catch (_) {
          /* Retry the same operation if clearing failed. */
        }
      }
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.actionableUserMessage
              : '교환 결과를 확인하지 못했어요. 같은 요청으로 다시 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _exchanging = false);
    }
  }

  Future<void> _draw() async {
    if (_drawing || _exchanging) return;
    setState(() {
      _drawing = true;
      _error = null;
    });
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    var drawAgain = false;
    try {
      do {
        drawAgain = false;
        setState(() => _awaitingDraw = true);
        final anticipation = Stopwatch()..start();
        _userId ??= (await widget.repository.getMe()).id;
        _drawRequestId ??=
            await widget.pendingDrawStore.read(_userId!) ?? newRequestId();
        await widget.pendingDrawStore.write(_userId!, _drawRequestId!);
        final result = await widget.repository.drawCosmetic(_drawRequestId!);
        await widget.pendingDrawStore.clear(_userId!);
        _drawRequestId = null;
        final remaining = 900 - anticipation.elapsedMilliseconds;
        if (!reduceMotion && remaining > 0) {
          await Future<void>.delayed(Duration(milliseconds: remaining));
        }
        if (!mounted) return;
        setState(() => _awaitingDraw = false);
        drawAgain =
            await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => LiveDrawResultPage(
                  repository: widget.repository,
                  nickname: widget.nickname,
                  result: result,
                ),
              ),
            ) ??
            false;
        if (mounted) await _load();
      } while (mounted &&
          drawAgain &&
          _error == null &&
          (_inventory?.tickets ?? 0) > 0);
    } catch (e) {
      // Keep the request key after any ambiguous failure; a retry cannot spend twice.
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.actionableUserMessage
              : '뽑기 결과를 확인하지 못했어요. 같은 요청으로 다시 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _drawing = false;
          _awaitingDraw = false;
        });
      }
    }
  }

  Future<void> _showCatalog() async {
    if (_loadingCatalog) return;
    setState(() => _loadingCatalog = true);
    try {
      final catalog = await widget.repository.getCosmeticCatalog();
      if (!mounted) return;
      setState(() => _catalog = catalog);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        builder: (context) => SafeArea(
          top: false,
          child: CosmeticCatalogSheet(
            catalog: catalog,
            nickname: widget.nickname,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.actionableUserMessage
                  : '아이템 목록을 불러오지 못했어요. 다시 시도해 주세요.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_drawing && !_exchanging,
    child: _awaitingDraw
        ? const GachaReveal(
            key: Key('gacha-draw-pending'),
            waitingForResult: true,
            child: SizedBox.shrink(),
          )
        : ProfileLayout(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('내 달러칩'),
                      Text(
                        _inventory == null
                            ? '—'
                            : '${_inventory!.dollarChips}개',
                        key: const Key('gacha-chip-balance'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    key: const Key('exchange-dollar-chips'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: _hasExchangeChips
                          ? ProfileStyle.action
                          : Colors.transparent,
                      disabledBackgroundColor: _hasExchangeChips
                          ? ProfileStyle.action
                          : Colors.transparent,
                      foregroundColor: _hasExchangeChips
                          ? Colors.white
                          : ProfileStyle.muted,
                      disabledForegroundColor: _hasExchangeChips
                          ? Colors.white70
                          : ProfileStyle.muted,
                      side: BorderSide(
                        color: _hasExchangeChips
                            ? ProfileStyle.action
                            : const Color(0xFFE1E6E2),
                      ),
                    ),
                    onPressed:
                        !_loading &&
                            !_drawing &&
                            !_exchanging &&
                            _inventory != null &&
                            (_exchangeId != null || _hasExchangeChips)
                        ? _exchangeChips
                        : null,
                    child: Text(
                      _exchanging
                          ? '교환 중…'
                          : _exchangeId != null
                          ? '교환 결과 다시 확인'
                          : '달러칩 ${_catalog?.chipExchangeCost ?? 10}개 → 뽑기권 1개로 바꾸기',
                    ),
                  ),
                  const SizedBox(height: 12),
                  RewardedTestButton(
                    repository: widget.repository,
                    enabled: !_drawing && !_loading && !_exchanging,
                    onVerified: _load,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '글자색 · 글꼴 · 배경을 모아서\n평단은 못 바꿔도 분위기를 바꿉시다.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: ProfileStyle.muted,
                    ),
                  ),
                  TextButton(
                    onPressed: _catalog == null ? null : _showCatalog,
                    child: const Text('획득 목록 · 확률 안내  ›'),
                  ),
                  TextButton(
                    onPressed: _drawing || _exchanging
                        ? null
                        : () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<bool>(
                                builder: (_) => OwnedCosmeticsPage(
                                  repository: widget.repository,
                                  nickname: widget.nickname,
                                  onOpenGacha: (context) =>
                                      Navigator.of(context).push<void>(
                                        MaterialPageRoute(
                                          builder: (_) => CosmeticGachaPage(
                                            repository: widget.repository,
                                            nickname: widget.nickname,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            );
                            if (mounted) await _load();
                          },
                    child: const Text('내 아이템 · 꾸미기'),
                  ),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                  if (_error != null) ...[
                    if (_error!.isNotEmpty)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    TextButton(
                      onPressed: _loading || _drawing || _exchanging
                          ? null
                          : _load,
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
                    ? '테스트 광고는 뽑기권을 지급하지 않아요.'
                    : '광고 보상은 서버 검증 후 반영돼요.',
                onPressed:
                    !_loading &&
                        !_exchanging &&
                        !_drawing &&
                        (_drawRequestId != null ||
                            (_inventory?.tickets ?? 0) > 0)
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장식을 적용했어요. 새로 보내는 채팅부터 반영돼요.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.actionableUserMessage
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
    return GachaReveal(
      rarity: item.rarity,
      child: PopScope(
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
                      ? '중복 보상으로 달러칩 ${result.chipsGranted}개를 받았어요.'
                      : '아이템은 내 아이템에 보관됐어요.\n언제든 꺼내 쓸 수 있어요.',
                  style: ProfileStyle.caption,
                ),
                if (_error?.isNotEmpty == true)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
            actions: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CosmeticAction(
                  label: _busy ? '적용 중…' : '지금 적용',
                  hint: '새로 보내는 채팅부터 반영돼요. 이전 메시지는 바뀌지 않아요.',
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
                CosmeticAction(
                  label: '다시 뽑기',
                  hint: result.ticketsAfter > 0
                      ? '남은 뽑기권 ${result.ticketsAfter}장 · 1장 사용'
                      : '뽑기권이 없어요. 뽑기권을 얻은 뒤 다시 뽑아주세요.',
                  onPressed: _busy || result.ticketsAfter <= 0
                      ? null
                      : () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
