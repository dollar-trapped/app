import 'dart:async';

import 'package:flutter/material.dart';

import 'chat_guidelines.dart';

/// Shows the introduction only when the room and its route are visible.
class ChatGuidelinesListener extends StatefulWidget {
  const ChatGuidelinesListener({
    super.key,
    required this.enabled,
    required this.child,
    this.store = const ChatGuidelinesStore(),
  });

  final bool enabled;
  final Widget child;
  final ChatGuidelinesStore store;

  @override
  State<ChatGuidelinesListener> createState() => _ChatGuidelinesListenerState();
}

class _ChatGuidelinesListenerState extends State<ChatGuidelinesListener>
    with WidgetsBindingObserver {
  bool _scheduled = false, _checking = false, _done = false;
  Timer? _retry;
  DialogRoute<bool>? _route;
  NavigatorState? _navigator;

  bool get _foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _schedule();
    } else {
      _retry?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant ChatGuidelinesListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _retry?.cancel();
      _dismiss();
    } else if (!oldWidget.enabled) {
      _schedule();
    }
  }

  void _schedule() {
    if (!mounted ||
        !_foreground ||
        !widget.enabled ||
        _scheduled ||
        _checking ||
        _done) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      unawaited(_check());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _waitForRoute() {
    _retry?.cancel();
    _retry = Timer(const Duration(milliseconds: 300), _schedule);
  }

  Future<void> _check() async {
    if (!mounted || !_foreground || !widget.enabled || _checking || _done) {
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) {
      _waitForRoute();
      return;
    }
    _checking = true;
    try {
      var seen = false;
      try {
        seen = await widget.store.hasSeen();
      } catch (_) {
        // An unavailable preference store must not hide the introduction.
      }
      if (!mounted || !_foreground || !widget.enabled) return;
      if (seen) {
        _done = true;
        return;
      }
      if (ModalRoute.of(context)?.isCurrent != true) {
        _waitForRoute();
        return;
      }
      _done = true;
      FocusManager.instance.primaryFocus?.unfocus();
      final navigator = Navigator.of(context, rootNavigator: true);
      final route = DialogRoute<bool>(
        context: context,
        builder: (_) => const ChatGuidelinesDialog(),
      );
      _navigator = navigator;
      _route = route;
      final confirmed = await navigator.push(route);
      if (confirmed == true) await widget.store.acknowledge();
    } finally {
      _route = null;
      _checking = false;
    }
  }

  void _dismiss() {
    final route = _route, navigator = _navigator;
    _route = null;
    if (route == null || navigator == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && route.isActive) navigator.removeRoute(route);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _retry?.cancel();
    _dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
