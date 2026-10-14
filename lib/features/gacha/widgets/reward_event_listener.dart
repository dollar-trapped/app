import 'package:flutter/material.dart';

import '../../../core/auth/reward_event_notifications.dart';
import 'ticket_reward_dialog.dart';

/// Mounted inside the consent gate, so rewards never cover required consent.
class RewardEventListener extends StatefulWidget {
  const RewardEventListener({
    super.key,
    required this.notifications,
    required this.child,
  });
  final RewardEventNotifications notifications;
  final Widget child;

  @override
  State<RewardEventListener> createState() => _RewardEventListenerState();
}

class _RewardEventListenerState extends State<RewardEventListener> {
  bool _scheduled = false;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    widget.notifications.addListener(_schedule);
    _schedule();
  }

  @override
  void didUpdateWidget(RewardEventListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifications != widget.notifications) {
      oldWidget.notifications.removeListener(_schedule);
      widget.notifications.addListener(_schedule);
      _schedule();
    }
  }

  void _schedule() {
    if (_scheduled || _showing) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _scheduled = false;
      if (!mounted) return;
      // Leave the receipt queued while another route/dialog is in front.
      if (ModalRoute.of(context)?.isCurrent != true) return;
      final receipt = widget.notifications.take();
      if (receipt == null) return;
      _showing = true;
      try {
        await showDialog<void>(
          context: context,
          builder: (_) => TicketRewardDialog(eventReward: receipt),
        );
      } finally {
        _showing = false;
        if (mounted) _schedule();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    widget.notifications.removeListener(_schedule);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _schedule();
    return widget.child;
  }
}
