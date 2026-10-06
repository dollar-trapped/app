import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import '../../profile/widgets/profile_layout.dart';
import '../../shared/data/dollar_repository.dart';
import '../../shared/widgets/cosmetic_layout.dart';
import '../data/wish_ticket_models.dart';
import '../services/pending_draw_store.dart';
import '../services/wish_ticket_operations.dart';

class WishTicketPage extends StatefulWidget {
  const WishTicketPage({
    super.key,
    required this.repository,
    required this.nickname,
    this.pendingStore = const SecurePendingDrawStore(
      prefix: 'pending_wish_ticket_',
    ),
  });
  final DollarRepository repository;
  final String nickname;
  final PendingDrawStore pendingStore;
  @override
  State<WishTicketPage> createState() => _WishTicketPageState();
}

class _WishTicketPageState extends State<WishTicketPage> {
  WishTicketState? _status;
  WishTicketOperations? _operations;
  WishTicketOption? _selected;
  bool _loading = true, _busy = false, _unavailable = false;
  String? _error, _success;
  bool get _pending => _operations?.pending != null;
  bool get _enabled =>
      !_loading &&
      !_busy &&
      !_pending &&
      _operations?.ready == true &&
      _status?.supported == true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? error}) async {
    setState(() {
      _loading = true;
      _error = error;
      _selected = null;
      _operations = null;
    });
    try {
      final user = await widget.repository.getMe();
      final operations = WishTicketOperations(
        widget.repository,
        widget.pendingStore,
        user.id,
      );
      await operations.restore();
      if (!mounted) return;
      _operations = operations;
      final status = await widget.repository.getWishTickets();
      if (!mounted) return;
      setState(() {
        _status = status;
        _unavailable = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = null;
        _unavailable = e is ApiException && [404, 501].contains(e.statusCode);
        if (!_unavailable) _error = error ?? '선택권 정보를 불러오지 못했어요. 다시 확인해 주세요.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _perform({WishTicketOption? choice}) async {
    if (_busy || _loading || _operations?.ready != true) return;
    if (!_pending &&
        (!_enabled ||
            (choice == null
                ? _status!.chips < 100
                : _status!.tickets < 1 || !choice.selectable))) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      if (!_pending) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              choice == null
                  ? '염원의 선택권으로 교환할까요?'
                  : '${choice.item.name}을 선택할까요?',
            ),
            content: Text(
              choice == null
                  ? '달러칩 100개를 사용해 선택권 1장을 받아요. 선택권은 원하는 SPECIAL을 고를 때 사용할 수 있어요.'
                  : '염원의 선택권 1장을 사용해 이 장식을 획득해요. 확정한 선택은 되돌릴 수 없어요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(choice == null ? '100개로 교환' : '선택 확정'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
      }
      final receipt = await _operations!.execute(cosmeticId: choice?.item.id);
      if (!mounted) return;
      final item = receipt.item;
      setState(() {
        _success = item == null
            ? '염원의 선택권 1장을 받았어요.'
            : '${item.name}을 획득했어요. 내 아이템에서 적용할 수 있어요.';
      });
      if (item != null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('염원이 이루어졌어요'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.name),
                const SizedBox(height: 20),
                ServerCosmeticNickname(
                  nickname: widget.nickname,
                  color: item.type == 'NAME_COLOR' ? item : null,
                  font: item.type == 'NAME_FONT' ? item : null,
                  background: item.type == 'NAME_BACKGROUND' ? item : null,
                  size: 24,
                ),
                const SizedBox(height: 16),
                const Text('내 아이템에 보관됐어요.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
      if (mounted) await _load();
    } catch (e) {
      if (!mounted) return;
      // Numeric error.details are diagnostics, not user-facing validation text.
      final message = e is ApiException
          ? switch (e.code) {
              'INSUFFICIENT_DOLLAR_CHIP' => '달러칩이 부족해요. 교환하려면 100개가 필요해요.',
              'INSUFFICIENT_WISH_TICKET' => '염원의 선택권이 부족해요.',
              'COSMETIC_ALREADY_OWNED' => '이미 보유한 장식이에요. 다른 SPECIAL을 선택해 주세요.',
              'COSMETIC_NOT_SELECTABLE' => '현재 선택할 수 없는 장식이에요. 목록을 다시 확인해 주세요.',
              'WISH_TICKETS_DISABLED' => '지금은 선택권을 교환하거나 사용할 수 없어요.',
              'IDEMPOTENCY_CONFLICT' => '이전 요청 정보가 일치하지 않아요. 문의를 통해 확인해 주세요.',
              'RATE_LIMITED' => '요청이 많아요. 잠시 후 같은 요청으로 다시 확인해 주세요.',
              'SERVICE_UNAVAILABLE' => '일시적으로 결과를 확인할 수 없어요. 잠시 후 다시 확인해 주세요.',
              _ => e.actionableUserMessage,
            }
          : '';
      await _load(
        error: message.isNotEmpty
            ? message
            : '결과를 확인하지 못했어요. 같은 요청으로 다시 확인해 주세요.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options =
        _status?.options
            .where(
              (o) =>
                  o.item.rarity == 'SPECIAL' &&
                  o.item.drawable &&
                  const {
                    'NAME_COLOR',
                    'NAME_FONT',
                    'NAME_BACKGROUND',
                  }.contains(o.item.type),
            )
            .toList() ??
        [];
    return PopScope(
      canPop: !_busy,
      child: ProfileLayout(
        title: '염원의 선택권',
        child: CosmeticContent(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '기다렸던 SPECIAL,\n이번에는 직접 선택하세요.',
                style: ProfileStyle.title,
              ),
              const SizedBox(height: 12),
              const Text(
                '달러칩 100개로 선택권 1장을 교환해요.\n원하는 장식을 확정할 때 선택권이 사용돼요.',
                style: ProfileStyle.caption,
              ),
              const SizedBox(height: 24),
              Text('내 달러칩  ${_status == null ? '—' : '${_status!.chips}개'}'),
              const SizedBox(height: 8),
              Text(
                '염원의 선택권  ${_status == null ? '—' : '${_status!.tickets}장'}',
                key: const Key('wish-ticket-balance'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                key: const Key('wish-exchange'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _enabled && _status!.chips >= 100
                      ? ProfileStyle.action
                      : Colors.transparent,
                  foregroundColor: _enabled && _status!.chips >= 100
                      ? Colors.white
                      : ProfileStyle.muted,
                ),
                onPressed: _enabled && _status!.chips >= 100
                    ? () => _perform()
                    : null,
                child: const Text(
                  '달러칩 100개 → 염원의 선택권 1장',
                  textAlign: TextAlign.center,
                ),
              ),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (_unavailable || (_status != null && !_status!.supported))
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('염원의 선택권을 준비하고 있어요. 지금은 교환하거나 사용할 수 없어요.'),
                ),
              if (_success != null)
                Text(
                  _success!,
                  style: const TextStyle(color: ProfileStyle.action),
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_pending) ...[
                const SizedBox(height: 12),
                const Text('이전 교환 또는 선택 결과를 먼저 확인해 주세요.'),
                FilledButton(
                  onPressed: !_busy && !_loading ? () => _perform() : null,
                  child: const Text('이전 결과 다시 확인'),
                ),
              ],
              TextButton(
                onPressed: _busy || _loading ? null : _load,
                child: const Text('정보 새로고침'),
              ),
              const SizedBox(height: 16),
              const Text(
                'SPECIAL 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '보유한 장식은 선택할 수 없어요. 선택권은 나중에 사용해도 괜찮아요.',
                style: ProfileStyle.caption,
              ),
              if (_status?.supported == true &&
                  options.every((o) => !o.selectable))
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    '현재 선택할 수 있는 SPECIAL이 없어요. 새 장식이 추가되면 선택권을 사용해 보세요.',
                  ),
                ),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    selected: _selected?.item.id == option.item.id,
                    child: OutlinedButton(
                      key: ValueKey('wish-option-${option.item.id}'),
                      onPressed:
                          _enabled && option.selectable && _status!.tickets > 0
                          ? () => setState(() => _selected = option)
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: _selected?.item.id == option.item.id
                            ? const Color(0xFFEAF7EE)
                            : Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${option.item.name}${option.owned
                                ? ' · 보유 중'
                                : _selected?.item.id == option.item.id
                                ? ' · 선택됨'
                                : ''}',
                          ),
                          const SizedBox(height: 12),
                          ServerCosmeticNickname(
                            nickname: widget.nickname,
                            color: option.item.type == 'NAME_COLOR'
                                ? option.item
                                : null,
                            font: option.item.type == 'NAME_FONT'
                                ? option.item
                                : null,
                            background: option.item.type == 'NAME_BACKGROUND'
                                ? option.item
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          actions: CosmeticAction(
            label: _busy ? '처리 중…' : '선택권 1장으로 획득',
            hint: '마지막 확인 전에는 선택권이 소모되지 않아요.',
            onPressed: _enabled && _selected != null && _status!.tickets > 0
                ? () => _perform(choice: _selected)
                : null,
          ),
        ),
      ),
    );
  }
}
