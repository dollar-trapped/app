import 'package:dollar_trapped/features/shared/widgets/skeleton.dart';
import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'wish_ticket_page.dart';
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
import '../widgets/draw_session.dart';

class LiveGachaPage extends StatefulWidget {
  const LiveGachaPage({
    super.key,
    required this.repository,
    required this.nickname,
    this.pendingDrawStore = const SecurePendingDrawStore(),
    this.pendingBatchDrawStore = const SecurePendingDrawStore(
      prefix: 'pending_cosmetic_batch_draw_',
    ),
    this.pendingExchangeStore = const SecurePendingDrawStore(
      prefix: 'pending_chip_exchange_',
    ),
  });
  final PendingDrawStore pendingDrawStore,
      pendingBatchDrawStore,
      pendingExchangeStore;
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
  String? _batchRequestId;
  bool _batchStateReady = false;
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
      _batchStateReady = false;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository.getMyCosmetics(),
        widget.repository.getCosmeticCatalog(),
      ]);
      if (!mounted) return;
      final user = await widget.repository.getMe();
      final pendingBatch = await widget.pendingBatchDrawStore.read(user.id);
      if (!mounted) return;
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
      _batchRequestId ??= pendingBatch;
      setState(() {
        _inventory = results[0] as CosmeticInventory;
        _catalog = results[1] as CosmeticCatalog;
        _batchStateReady = true;
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
          guaranteeState: inventory.guaranteeState,
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

  Future<CosmeticDraw> _requestDraw() async {
    _userId ??= (await widget.repository.getMe()).id;
    _drawRequestId ??=
        await widget.pendingDrawStore.read(_userId!) ?? newRequestId();
    await widget.pendingDrawStore.write(_userId!, _drawRequestId!);
    final result = await widget.repository.drawCosmetic(_drawRequestId!);
    await widget.pendingDrawStore.clear(_userId!);
    _drawRequestId = null;
    return result;
  }

  Future<void> _drawTen() async {
    if (_drawing ||
        !_batchStateReady ||
        _exchanging ||
        _loading ||
        _drawRequestId != null ||
        (_batchRequestId == null && (_inventory?.tickets ?? 0) < 10)) {
      return;
    }
    setState(() {
      _drawing = true;
      _error = null;
    });
    try {
      final outcome = await Navigator.of(context).push<Object>(
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => DrawSession<CosmeticBatchDraw>(
            nickname: widget.nickname,
            batch: true,
            request: () async {
              _userId ??= (await widget.repository.getMe()).id;
              _batchRequestId ??=
                  await widget.pendingBatchDrawStore.read(_userId!) ??
                  newRequestId();
              await widget.pendingBatchDrawStore.write(
                _userId!,
                _batchRequestId!,
              );
              final result = await widget.repository.drawCosmeticBatch(
                _batchRequestId!,
              );
              if (result.requestId != _batchRequestId ||
                  result.count != 10 ||
                  result.results.length != 10) {
                throw const FormatException('Unexpected batch draw response');
              }
              await widget.pendingBatchDrawStore.clear(_userId!);
              _batchRequestId = null;
              return result;
            },
            results: (result) => result.results,
            repository: widget.repository,
          ),
        ),
      );
      if (outcome is DrawSessionFailure) throw outcome.error;
      if (mounted) await _load();
    } catch (error) {
      // Keep the whole batch key, even if the response or local cleanup was lost.
      // Never fall back to single draws: the server may have consumed all ten.
      if (mounted) {
        await _load();
      }
      if (mounted) {
        setState(
          () => _error =
              error is ApiException && error.actionableUserMessage.isNotEmpty
              ? error.actionableUserMessage
              : '10회 뽑기 결과를 확인하지 못했어요. 같은 요청으로 다시 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _drawing = false;
        });
      }
    }
  }

  Future<void> _draw() async {
    if (_drawing ||
        _exchanging ||
        !_batchStateReady ||
        _batchRequestId != null) {
      return;
    }
    setState(() {
      _drawing = true;
      _error = null;
    });
    try {
      final outcome = await Navigator.of(context).push<Object>(
        PageRouteBuilder(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => DrawSession<CosmeticDraw>(
            nickname: widget.nickname,
            request: _requestDraw,
            results: (result) => [result],
            repository: widget.repository,
          ),
        ),
      );
      if (outcome is DrawSessionFailure) throw outcome.error;
      if (mounted) await _load();
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
        backgroundColor: AppColors.of(context).background,
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

  Future<void> _openWishTickets() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WishTicketPage(
          repository: widget.repository,
          nickname: widget.nickname,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openItems() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OwnedCosmeticsPage(
          repository: widget.repository,
          nickname: widget.nickname,
          onOpenGacha: (context) => Navigator.of(context).push<void>(
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
  }

  CosmeticItem? _equippedItem(String? id) {
    for (final item in _inventory?.items ?? <CosmeticItem>[]) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool get _busy => _loading || _drawing || _exchanging;

  Widget _drawActions() {
    final ten = CosmeticAction(
      secondary: true,
      label: _batchRequestId == null ? '10회 뽑기' : '10회 결과 다시 확인',
      hint: _batchRequestId == null
          ? _catalog?.cumulativeGuaranteedRareOrAbove != true &&
                    _catalog?.batchGuaranteedRareOrAbove == true
                ? '10장 사용 · RARE 이상 1개 보장'
                : '10장 사용'
          : '이전 10회 요청 결과 확인',
      onPressed:
          !_busy &&
              _batchStateReady &&
              _drawRequestId == null &&
              (_batchRequestId != null || (_inventory?.tickets ?? 0) >= 10)
          ? _drawTen
          : null,
    );
    final one = CosmeticAction(
      label: _drawRequestId != null ? '뽑기 결과 다시 확인' : '1회 뽑기',
      hint: _drawRequestId != null ? '이전 요청 결과 확인' : '1장 사용',
      onPressed:
          !_busy &&
              _batchStateReady &&
              _batchRequestId == null &&
              (_drawRequestId != null || (_inventory?.tickets ?? 0) > 0)
          ? _draw
          : null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(16) > 21) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [one, const SizedBox(height: 16), ten],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ten),
            const SizedBox(width: 12),
            Expanded(child: one),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_drawing && !_exchanging,
    child: ProfileLayout(
      title: '닉네임 뽑기',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.of(context).soft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text('지금 내 닉네임', style: AppColors.of(context).caption),
                  const SizedBox(height: 16),
                  Skeleton(
                    active: _loading && _inventory == null,
                    label: '닉네임 장식 불러오는 중',
                    child: _loading && _inventory == null
                        ? const SkeletonLine(width: 160, height: 36)
                        : ServerCosmeticNickname(
                            nickname: widget.nickname,
                            size: 24,
                            color: _equippedItem(_inventory?.equipment.colorId),
                            font: _equippedItem(_inventory?.equipment.fontId),
                            background: _equippedItem(
                              _inventory?.equipment.backgroundId,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Skeleton(
              active: _loading && _inventory == null,
              label: '보유 수량 불러오는 중',
              child: Row(
                children: [
                  Expanded(
                    child: _Balance(
                      loading: _loading && _inventory == null,
                      label: '내 뽑기권',
                      value: _inventory == null
                          ? '—'
                          : '${_inventory!.tickets}장',
                      valueKey: const Key('gacha-ticket-balance'),
                      prominent: true,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: AppColors.of(context).line,
                  ),
                  Expanded(
                    child: _Balance(
                      loading: _loading && _inventory == null,
                      label: '내 달러칩',
                      value: _inventory == null
                          ? '—'
                          : '${_inventory!.dollarChips}개',
                      valueKey: const Key('gacha-chip-balance'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_loading && _inventory != null) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 12),
            ],
            if (_error != null) ...[
              if (_error!.isNotEmpty)
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.of(context).error),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _busy ? null : _load,
                  child: const Text('정보 다시 불러오기'),
                ),
              ),
            ],
            if (_catalog?.cumulativeGuaranteedRareOrAbove == true) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _loading
                          ? '보장 횟수를 확인하고 있어요.'
                          : _error != null || _inventory?.guaranteeState == null
                          ? '보장 횟수를 확인하지 못했어요. 정보를 다시 불러와 주세요.'
                          : _inventory!.guaranteeState!.drawsUntilGuaranteed ==
                                1
                          ? '누적 보장 9/10 · 다음 뽑기 레어 이상 확정'
                          : '누적 보장 ${_inventory!.guaranteeState!.consecutiveCommonCount}/10',
                      key: const Key('gacha-guarantee-status'),
                      style: AppColors.of(
                        context,
                      ).caption.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    message: '단뽑·10회 뽑기 누적 횟수 공유\n레어 또는 스페셜이 나오면 횟수가 초기화돼요.',
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.of(context).muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            _drawActions(),
            const SizedBox(height: 28),
            Divider(height: 1, color: AppColors.of(context).line),
            const SizedBox(height: 24),
            Text('뽑기권 모으기', style: _gachaSectionStyle(context)),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('exchange-dollar-chips'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                foregroundColor: AppColors.of(context).ink,
                side: BorderSide(color: AppColors.of(context).line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed:
                  !_busy &&
                      _inventory != null &&
                      (_exchangeId != null || _hasExchangeChips)
                  ? _exchangeChips
                  : null,
              child: Text(
                _exchanging
                    ? '교환 중…'
                    : _exchangeId != null
                    ? '교환 결과 다시 확인'
                    : '달러칩 ${_catalog?.chipExchangeCost ?? 10}개로 뽑기권 1장 교환',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            RewardedTestButton(
              repository: widget.repository,
              enabled: !_busy,
              onVerified: _load,
            ),
            const SizedBox(height: 8),
            Text(
              AdConfig.isTest
                  ? '테스트 광고는 뽑기권을 지급하지 않아요.'
                  : '광고 보상은 서버 검증 후 반영돼요.',
              style: AppColors.of(context).caption,
            ),
            const SizedBox(height: 28),
            Text('더 둘러보기', style: _gachaSectionStyle(context)),
            const SizedBox(height: 8),
            AccountMenuRow(
              label: '스페셜 아이템 선택',
              onTap: _busy ? null : _openWishTickets,
            ),
            AccountMenuRow(
              label: '획득 목록 · 확률 안내',
              onTap: _catalog == null || _drawing || _exchanging
                  ? null
                  : _showCatalog,
            ),
            AccountMenuRow(
              label: '내 아이템 · 꾸미기',
              onTap: _drawing || _exchanging ? null : _openItems,
            ),
          ],
        ),
      ),
    ),
  );
}

TextStyle _gachaSectionStyle(BuildContext context) => TextStyle(
  fontSize: 14,
  height: 1.5,
  fontWeight: FontWeight.w700,
  color: AppColors.of(context).ink,
);

class _Balance extends StatelessWidget {
  const _Balance({
    required this.label,
    required this.value,
    required this.valueKey,
    this.prominent = false,
    this.loading = false,
  });
  final String label, value;
  final Key valueKey;
  final bool prominent, loading;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: AppColors.of(context).caption),
      const SizedBox(height: 4),
      if (loading)
        const SkeletonLine(width: 72, height: 33)
      else
        Text(
          value,
          key: valueKey,
          style: TextStyle(
            fontSize: 22,
            height: 1.5,
            fontWeight: FontWeight.w700,
            color: prominent
                ? AppColors.of(context).action
                : AppColors.of(context).ink,
          ),
        ),
    ],
  );
}

class LiveDrawResultPage extends StatefulWidget {
  const LiveDrawResultPage({
    super.key,
    required this.repository,
    required this.nickname,
    required this.result,
    this.allowDrawAgain = true,
    this.animate = true,
    this.onDrawAgain,
  });
  final DollarRepository repository;
  final String nickname;
  final CosmeticDraw result;
  final bool allowDrawAgain, animate;
  final VoidCallback? onDrawAgain;
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
    final content = PopScope(
      canPop: !_busy,
      child: ProfileLayout(
        title: '뽑기 결과',
        child: CosmeticContent(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                result.duplicate ? '이미 보유한 아이템' : '새로운 아이템',
                style: TextStyle(color: AppColors.of(context).action),
              ),
              const SizedBox(height: 24),
              Text(
                result.duplicate ? '익숙한 취향을\n다시 만났어요.' : '새로운 취향을\n뽑았어요.',
                style: AppColors.of(context).title,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${item.type} · ${item.rarity}',
                      style: AppColors.of(context).caption,
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
                style: AppColors.of(context).caption,
              ),
              if (_error?.isNotEmpty == true)
                Text(
                  _error!,
                  style: TextStyle(color: AppColors.of(context).error),
                ),
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
              if (widget.allowDrawAgain) ...[
                const SizedBox(height: 12),
                CosmeticAction(
                  label: '다시 뽑기',
                  hint: result.ticketsAfter > 0
                      ? '남은 뽑기권 ${result.ticketsAfter}장 · 1장 사용'
                      : '뽑기권이 없어요. 뽑기권을 얻은 뒤 다시 뽑아주세요.',
                  onPressed: _busy || result.ticketsAfter <= 0
                      ? null
                      : widget.onDrawAgain ??
                            () => Navigator.of(context).pop(true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return widget.animate
        ? GachaReveal(rarity: item.rarity, child: content)
        : content;
  }
}
