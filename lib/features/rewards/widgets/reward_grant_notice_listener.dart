import 'dart:async';

import 'package:flutter/material.dart';

import '../../gacha/widgets/ticket_reward_dialog.dart';
import '../data/reward_grant_notices.dart';

/// Placed inside the consent gate; serializes with other home-screen dialogs.
class RewardGrantNoticeListener extends StatefulWidget {
  const RewardGrantNoticeListener({
    super.key,
    required this.notices,
    required this.child,
  });
  final RewardGrantNotices notices;
  final Widget child;
  @override
  State<RewardGrantNoticeListener> createState() =>
      _RewardGrantNoticeListenerState();
}

class _RewardGrantNoticeListenerState extends State<RewardGrantNoticeListener>
    with WidgetsBindingObserver {
  bool _scheduled = false, _showing = false;
  DialogRoute<void>? _route;
  NavigatorState? _navigator;
  int? _displayEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.notices.addListener(_schedule);
    unawaited(widget.notices.load());
    _schedule();
  }

  @override
  void didUpdateWidget(RewardGrantNoticeListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notices != widget.notices) {
      oldWidget.notices.removeListener(_schedule);
      _dismiss();
      widget.notices.addListener(_schedule);
      unawaited(widget.notices.load());
      _schedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.notices.load(refresh: true));
    }
  }

  void _dismiss() {
    final route = _route, navigator = _navigator;
    _route = null;
    if (route != null && navigator != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted && route.isActive) navigator.removeRoute(route);
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      if (!mounted) return;
      if (_showing) {
        if (_displayEpoch != widget.notices.epoch) _dismiss();
        return;
      }
      if (ModalRoute.of(context)?.isCurrent != true) return;
      final notice = widget.notices.current;
      if (notice == null) return;
      _showing = true;
      _displayEpoch = widget.notices.epoch;
      final notices = widget.notices;
      final navigator = Navigator.of(context, rootNavigator: true);
      final route = DialogRoute<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _GrantDialog(
          notice: notice,
          acknowledge: () => notices.acknowledge(notice),
        ),
      );
      _route = route;
      _navigator = navigator;
      try {
        await navigator.push(route);
      } finally {
        if (_route == route) _route = null;
        _showing = false;
        if (mounted) {
          // Page fetch only after the current pending receipt is acknowledged.
          unawaited(widget.notices.load());
          _schedule();
        }
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.notices.removeListener(_schedule);
    _dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _schedule();
    return widget.child;
  }
}

class _GrantDialog extends StatefulWidget {
  const _GrantDialog({required this.notice, required this.acknowledge});
  final RewardGrantNotice notice;
  final Future<void> Function() acknowledge;
  @override
  State<_GrantDialog> createState() => _GrantDialogState();
}

class _GrantDialogState extends State<_GrantDialog> {
  bool _busy = false;
  String? _error;
  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.acknowledge();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _error = '확인을 저장하지 못했어요. 다시 눌러 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: TicketRewardDialog(
      awardedTickets: widget.notice.amount,
      rewardHeading: widget.notice.name,
      rewardMessage:
          '${widget.notice.grantedAtKst} 지급 · 한국 시간\n지급된 뽑기권으로 닉네임 장식을 만나보세요.',
      confirmationStatus: _error == null
          ? null
          : Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB3261E)),
            ),
      confirmationAction: FilledButton(
        onPressed: _busy ? null : _confirm,
        child: Text(
          _busy
              ? '확인 저장 중…'
              : _error == null
              ? '확인'
              : '다시 확인',
        ),
      ),
    ),
  );
}
