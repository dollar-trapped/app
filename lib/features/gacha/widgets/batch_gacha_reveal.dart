import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import '../data/gacha_models.dart';

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
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      if (!widget.waiting) _controller.value = 1;
    } else if (widget.waiting) {
      if (!_controller.isAnimating) {
        _controller.repeat(period: const Duration(milliseconds: 2200));
      }
    } else if (!_started) {
      _started = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      if (!widget.waiting && _controller.value == 1) {
        return widget.child ?? const SizedBox.shrink();
      }
      final reduced = MediaQuery.disableAnimationsOf(context);
      return Scaffold(
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
                          ? '뽑기 결과를 확인하고 있어요. ${widget.completed} / 10'
                          : '열 가지 취향이 펼쳐집니다',
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
                          final progress = widget.waiting
                              ? _controller.value
                              : (((_controller.value / .8).clamp(0.0, 1.0) -
                                            index * .045) /
                                        .595)
                                    .clamp(0.0, 1.0);
                          final entered = widget.waiting
                              ? 1.0
                              : Curves.easeOut.transform(
                                  (progress / .2).clamp(0.0, 1.0),
                                );
                          final spin = widget.waiting
                              ? (reduced ? 0.0 : progress * math.pi * 2)
                              : Curves.easeInOut.transform(
                                      (progress / .9).clamp(0.0, 1.0),
                                    ) *
                                    math.pi *
                                    4;
                          final result = index < widget.results.length
                              ? widget.results[index]
                              : null;
                          final opened = !widget.waiting && progress >= .9;
                          final color = opened && result != null
                              ? switch (result.item.rarity) {
                                  'SPECIAL' => const Color(0xFFE1B64A),
                                  'RARE' => const Color(0xFF9258CC),
                                  _ => const Color(0xFF447956),
                                }
                              : const Color(0xFF447956);
                          return Opacity(
                            opacity: entered,
                            child: Transform.translate(
                              offset: Offset(0, (1 - entered) * 32),
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
                                      colors: [color, const Color(0xFF102D22)],
                                    ),
                                    border: Border.all(
                                      color: opened
                                          ? color
                                          : const Color(0xFFE3D99A),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withValues(
                                          alpha: opened ? .35 : .1,
                                        ),
                                        blurRadius: opened ? 18 : 6,
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
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      result.item.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child: DecoratedBox(
                                                        decoration: BoxDecoration(
                                                          color: const Color(
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
                                                                horizontal: 4,
                                                                vertical: 2,
                                                              ),
                                                          child: ServerCosmeticNickname(
                                                            nickname:
                                                                widget.nickname,
                                                            color:
                                                                result
                                                                        .item
                                                                        .type ==
                                                                    'NAME_COLOR'
                                                                ? result.item
                                                                : null,
                                                            font:
                                                                result
                                                                        .item
                                                                        .type ==
                                                                    'NAME_FONT'
                                                                ? result.item
                                                                : null,
                                                            background:
                                                                result
                                                                        .item
                                                                        .type ==
                                                                    'NAME_BACKGROUND'
                                                                ? result.item
                                                                : null,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      '${result.item.rarity} · ${result.duplicate ? '중복' : 'NEW'}',
                                                      style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                        : Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Color(0xFFE3D99A),
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
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
                        onPressed: () => _controller.value = 1,
                        child: const Text(
                          '연출 건너뛰기',
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
    },
  );
}
