import 'package:flutter/material.dart';

import '../data/gacha_models.dart';
import 'batch_gacha_reveal.dart';
import 'gacha_reveal.dart';
import '../../cosmetics/widgets/server_cosmetic_preview.dart';

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
    required this.builder,
    this.batch = false,
  });
  final String nickname;
  final bool batch;
  final Future<T> Function() request;
  final List<CosmeticDraw> Function(T) results;
  final Widget Function(BuildContext, T, VoidCallback) builder;

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
    final child = _pending
        ? const SizedBox.shrink()
        : widget.builder(context, result as T, _again);
    return PopScope(
      canPop: !_pending,
      child: KeyedSubtree(
        key: ValueKey(_generation),
        child: widget.batch
            ? BatchGachaReveal(
                nickname: widget.nickname,
                waiting: _pending,
                results: draws,
                child: child,
              )
            : GachaReveal(
                key: const Key('gacha-draw-scene'),
                waitingForResult: _pending,
                preview: draws.isEmpty
                    ? null
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ServerCosmeticNickname(
                              nickname: widget.nickname,
                              color: draws.first.item.type == 'NAME_COLOR'
                                  ? draws.first.item
                                  : null,
                              font: draws.first.item.type == 'NAME_FONT'
                                  ? draws.first.item
                                  : null,
                              background:
                                  draws.first.item.type == 'NAME_BACKGROUND'
                                  ? draws.first.item
                                  : null,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                rarity: draws.isEmpty ? 'COMMON' : draws.first.item.rarity,
                child: child,
              ),
      ),
    );
  }
}
