import 'dart:async';

import 'package:flutter/material.dart';

import '../../gacha/widgets/ticket_reward_dialog.dart';
import '../data/launch_attendance.dart';
import 'attendance_event_dialog.dart';

/// Mounted after required consent. Waits for other routes before checking.
class LaunchAttendanceListener extends StatefulWidget {
  const LaunchAttendanceListener({
    super.key,
    required this.attendance,
    required this.child,
  });
  final LaunchAttendance attendance;
  final Widget child;
  @override
  State<LaunchAttendanceListener> createState() =>
      _LaunchAttendanceListenerState();
}

class _LaunchAttendanceListenerState extends State<LaunchAttendanceListener>
    with WidgetsBindingObserver {
  bool _scheduled = false, _showing = false, _needsCheck = true;
  int? _displayEpoch;
  Timer? _retry;
  DialogRoute<void>? _route;
  NavigatorState? _navigator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.attendance.addListener(_schedule);
    _schedule();
  }

  @override
  void didUpdateWidget(LaunchAttendanceListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attendance != widget.attendance) {
      oldWidget.attendance.removeListener(_schedule);
      _dismiss();
      widget.attendance.addListener(_schedule);
      _needsCheck = true;
      _schedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _needsCheck = true;
      _schedule();
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
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      if (!mounted) return;
      if (_showing) {
        if (_displayEpoch != widget.attendance.epoch) _dismiss();
        return;
      }
      if (ModalRoute.of(context)?.isCurrent != true) {
        _retry?.cancel();
        _retry = Timer(const Duration(milliseconds: 300), _schedule);
        return;
      }
      if (_needsCheck && widget.attendance.pending == null) {
        _needsCheck = false;
        await widget.attendance.check();
        if (!mounted) return;
        _schedule();
        return;
      }
      _needsCheck = false;
      final attendance = widget.attendance;
      final status = attendance.take();
      if (status == null) return;
      _showing = true;
      _displayEpoch = attendance.epoch;
      final navigator = Navigator.of(context, rootNavigator: true);
      final route = DialogRoute<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AttendanceDialog(status: status),
      );
      _route = route;
      _navigator = navigator;
      try {
        await navigator.push(route);
      } finally {
        if (_route == route) _route = null;
        _showing = false;
        if (mounted) _schedule();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.attendance.removeListener(_schedule);
    _retry?.cancel();
    _dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AttendanceDialog extends StatefulWidget {
  const _AttendanceDialog({required this.status});
  final AttendanceStatus status;
  @override
  State<_AttendanceDialog> createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<_AttendanceDialog> {
  bool _reward = false, _confirmed = false;
  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    return PopScope(
      canPop: false,
      child: _reward
          ? TicketRewardDialog(
              awardedTickets: status.grantedAmount,
              rewardHeading: '${status.attendedDays}회차 출석 보상 도착!',
              rewardMessage: '현재 보유 뽑기권 ${status.balance}장',
              confirmationAction: FilledButton(
                onPressed: () => setState(() {
                  _reward = false;
                  _confirmed = true;
                }),
                child: const Text('확인'),
              ),
            )
          : AttendanceEventDialog(
              data: AttendanceViewData(
                completedCount: status.attendedDays,
                todayCompleted: status.claimedToday,
                rewards: status.rewards,
                newReward: !_confirmed && status.grantedAmount > 0
                    ? status.grantedAmount
                    : null,
              ),
              onClose: () => Navigator.of(context).pop(),
              onReward: () => setState(() => _reward = true),
            ),
    );
  }
}
