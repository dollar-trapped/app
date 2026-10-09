import 'package:flutter/material.dart';

import '../data/gacha_models.dart';
import 'dollar_case_reveal.dart';
import 'case_reward_card.dart';
import '../../shared/data/dollar_repository.dart';

class DrawSessionFailure {
  const DrawSessionFailure(this.error);
  final Object error;
}

/// One route and one reveal state from request through result, including redraws.
/// The caller owns durable request IDs; this widget never retries automatically.
class DrawSession<T> extends StatefulWidget {
  const DrawSession({
    super.key,
    required this.nickname,
    required this.request,
    required this.results,
    required this.repository,
    this.batch = false,
  });
  final String nickname;
  final bool batch;
  final Future<T> Function() request;
  final List<CosmeticDraw> Function(T) results;
  final DollarRepository repository;

  @override
  State<DrawSession<T>> createState() => _DrawSessionState<T>();
}

class _DrawSessionState<T> extends State<DrawSession<T>> {
  T? _result;
  bool _pending = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _request();
  }

  Future<void> _request() async {
    try {
      final result = await widget.request();
      if (!mounted) return;
      setState(() {
        _result = result;
        _pending = false;
      });
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop(DrawSessionFailure(error));
    }
  }

  void _again() {
    if (_pending) return;
    setState(() {
      _pending = true;
      _result = null;
      _generation++;
    });
    _request();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final draws = _pending ? <CosmeticDraw>[] : widget.results(result as T);
    return PopScope(
      canPop: !_pending,
      child: DollarCaseReveal(
        key: ValueKey(_generation),
        count: widget.batch ? 10 : 1,
        waiting: _pending,
        rarities: draws.map((draw) => draw.item.rarity).toList(),
        rewardBuilder: (index) => CaseRewardCard(
          key: ValueKey('${_generation}_$index'),
          repository: widget.repository,
          nickname: widget.nickname,
          result: draws[index],
          onAgain: !widget.batch ? _again : null,
        ),
        onFinish: () => Navigator.of(context).pop(),
        child: const SizedBox.shrink(),
      ),
    );
  }
}
