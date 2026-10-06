import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import '../data/gacha_models.dart';
import 'gacha_card_back.dart';

/// Presentation only. Unknown outcomes stay face down, including partial batches.
class BatchGachaReveal extends StatefulWidget {
  const BatchGachaReveal({
    super.key,
    required this.nickname,
    this.results = const [],
    this.waiting = false,
    this.completed = 0,
    this.child,
  });
  final String nickname;
  final List<CosmeticDraw> results;
  final bool waiting;
  final int completed;
  final Widget? child;

  @override
  State<BatchGachaReveal> createState() => _BatchGachaRevealState();
}

class _BatchGachaRevealState extends State<BatchGachaReveal>
    with TickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  late final _turns = List.generate(
    10,
    (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    ),
  );
  final _taps = List.filled(10, 0);
  final _opened = List.filled(10, false);
  bool _finished = false;

  int _requiredTaps(int index) => switch (widget.results[index].item.rarity) {
    'SPECIAL' => 3,
    'RARE' => 2,
    _ => 1,
  };

  Future<void> _tapCard(int index) async {
    if (widget.waiting ||
        index >= widget.results.length ||
        _opened[index] ||
        _turns[index].isAnimating) {
      return;
    }
    if (!MediaQuery.disableAnimationsOf(context)) {
      try {
        await _turns[index].forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted || _finished) return;
    setState(() {
      _taps[index]++;
      _opened[index] = _taps[index] >= _requiredTaps(index);
      _turns[index].value = 0;
    });
  }

  void _openAll() {
    for (final turn in _turns) {
      turn.stop(canceled: true);
    }
    setState(() => _finished = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      for (final turn in _turns) {
        if (turn.isAnimating) turn.value = 1;
      }
    } else if (widget.waiting && !_controller.isAnimating) {
      _controller.repeat(period: const Duration(milliseconds: 2200));
    }
  }

  @override
  void didUpdateWidget(covariant BatchGachaReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.waiting != widget.waiting) {
      _controller.stop();
      _controller.value = 0;
      _syncMotion();
    }
  }

  @override
  void dispose() {
    for (final turn in _turns) {
      turn.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_controller, ..._turns]),
    builder: (context, _) {
      if (!widget.waiting && _finished) {
        return widget.child ?? const SizedBox.shrink();
      }
      final reduced = MediaQuery.disableAnimationsOf(context);
      final scene = Scaffold(
        backgroundColor: const Color(0xFF102D22),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 5 : 2;
              final rows = 10 ~/ columns;
              final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
              final cardHeight = 106 + math.max(0.0, textScale - 1) * 180;
              final gridHeight = math.max(
                rows * cardHeight + (rows - 1) * 12,
                constraints.maxHeight - 180,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      '닉네임 컬렉션 · 10회 뽑기',
                      style: TextStyle(color: Color(0xFFC5D9BD), fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.waiting
                          ? '뽑기 결과를 확인하고 있어요.'
                          : '카드를 눌러 열어보세요 · ${_opened.where((v) => v).length} / 10',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: gridHeight,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 10,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: (gridHeight - (rows - 1) * 12) / rows,
                        ),
                        itemBuilder: (context, index) {
                          final progress = _turns[index].value;
                          const entered = 1.0;
                          final flip = Curves.easeInOutCubic.transform(
                            progress,
                          );
                          final spin = widget.waiting
                              ? (reduced
                                    ? 0.0
                                    : math.sin(
                                            _controller.value * math.pi * 2 +
                                                index * .2,
                                          ) *
                                          .08)
                              : flip * math.pi * 2;
                          final result = index < widget.results.length
                              ? widget.results[index]
                              : null;
                          final opened =
                              !widget.waiting &&
                              (_opened[index] ||
                                  (result != null &&
                                      _taps[index] + 1 >=
                                          _requiredTaps(index) &&
                                      progress >= .75));
                          final color = opened && result != null
                              ? switch (result.item.rarity) {
                                  'SPECIAL' => const Color(0xFFE1B64A),
                                  'RARE' => const Color(0xFF9258CC),
                                  _ => const Color(0xFF447956),
                                }
                              : Color.lerp(
                                  const Color(0xFF447956),
                                  const Color(0xFFE1B64A),
                                  _taps[index] * .25,
                                )!;
                          return Semantics(
                            button:
                                !widget.waiting &&
                                !_opened[index] &&
                                result != null,
                            label:
                                '${index + 1}번 카드${_opened[index] ? ", 공개됨" : ", 눌러 열기"}',
                            child: GestureDetector(
                              key: Key('batch-card-touch-$index'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _tapCard(index),
                              child: Opacity(
                                opacity: entered,
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    widget.waiting && !reduced
                                        ? math.sin(
                                                _controller.value *
                                                        math.pi *
                                                        2 +
                                                    index * .2,
                                              ) *
                                              3
                                        : -math.sin(progress * math.pi) * 8,
                                  ),
                                  child: Transform(
                                    key: Key('batch-card-turn-$index'),
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, .0015)
                                      ..rotateY(spin),
                                    child: Container(
                                      key: Key('batch-card-$index'),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            color,
                                            const Color(0xFF102D22),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: opened
                                              ? color
                                              : const Color(0xFFE3D99A),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withValues(
                                              alpha: opened
                                                  ? .35
                                                  : .1 + _taps[index] * .12,
                                            ),
                                            blurRadius: opened ? 12 : 6,
                                          ),
                                        ],
                                      ),
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(
                                            math.cos(spin) < 0 ? math.pi : 0,
                                          ),
                                        child: opened
                                            ? result == null
                                                  ? const Center(
                                                      child: Text(
                                                        '미확인',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    )
                                                  : Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          result.item.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: DecoratedBox(
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFF5F7F5,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    6,
                                                                  ),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        4,
                                                                    vertical: 2,
                                                                  ),
                                                              child: ServerCosmeticNickname(
                                                                nickname: widget
                                                                    .nickname,
                                                                color:
                                                                    result
                                                                            .item
                                                                            .type ==
                                                                        'NAME_COLOR'
                                                                    ? result
                                                                          .item
                                                                    : null,
                                                                font:
                                                                    result
                                                                            .item
                                                                            .type ==
                                                                        'NAME_FONT'
                                                                    ? result
                                                                          .item
                                                                    : null,
                                                                background:
                                                                    result
                                                                            .item
                                                                            .type ==
                                                                        'NAME_BACKGROUND'
                                                                    ? result
                                                                          .item
                                                                    : null,
                                                                size: 18,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Text(
                                                          '${result.item.rarity} · ${result.duplicate ? '중복' : 'NEW'}',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white70,
                                                                fontSize: 11,
                                                              ),
                                                        ),
                                                      ],
                                                    )
                                            : GachaCardBack(
                                                number: index + 1,
                                                prompt: _taps[index] > 0
                                                    ? '한 번 더'
                                                    : null,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!widget.waiting)
                      TextButton(
                        onPressed: _openAll,
                        child: Text(
                          _opened.every((v) => v) ? '결과 보기' : '바로 열기',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      return scene;
    },
  );
}
