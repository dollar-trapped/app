import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Presentation only: waiting never grants an item or reveals an invented result.
class GachaReveal extends StatefulWidget {
  const GachaReveal({
    super.key,
    required this.child,
    this.isPreview = false,
    this.waitingForResult = false,
    this.rarity = 'COMMON',
  });
  final Widget child;
  final bool isPreview;
  final bool waitingForResult;
  final String rarity;

  @override
  State<GachaReveal> createState() => _GachaRevealState();
}

class _GachaRevealState extends State<GachaReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
    duration: Duration(
      milliseconds: switch (widget.rarity) {
        'RARE' => 4800,
        'SPECIAL' => 6400,
        _ => 3200,
      },
    ),
  );
  bool _waitingStarted = false;
  bool _spinning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.waitingForResult && !_waitingStarted) {
      _waitingStarted = true;
      if (!MediaQuery.disableAnimationsOf(context)) {
        _controller.repeat(
          max: .48,
          period: const Duration(milliseconds: 1200),
        );
      }
    }
  }

  void _turnCard() {
    if (widget.waitingForResult || _spinning) return;
    setState(() => _spinning = true);
    _controller.forward(from: 0);
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
      final t = _controller.value;
      if (!widget.waitingForResult && t == 1) return widget.child;
      final enhanced =
          !widget.waitingForResult &&
          (widget.rarity == 'RARE' || widget.rarity == 'SPECIAL');
      final turns = switch (widget.rarity) {
        'RARE' => 5,
        'SPECIAL' => 7,
        _ => 3,
      };
      final spinEnd = (turns * 800) / (turns * 800 + 800);
      final spin = (t / spinEnd).clamp(0.0, 1.0);
      final palette = <Color>[
        const Color(0xFF447956),
        const Color(0xFF327CC5),
        const Color(0xFF9258CC),
        if (widget.rarity == 'SPECIAL') const Color(0xFFE1B64A),
      ];
      final colorProgress = enhanced ? ((t - .18) / .56).clamp(0.0, 1.0) : 0.0;
      final position = colorProgress * (palette.length - 1);
      final index = position.floor();
      final cardColor = Color.lerp(
        palette[index],
        palette[math.min(index + 1, palette.length - 1)],
        position - index,
      )!;
      final glowColor = enhanced ? cardColor : const Color(0xFFE3D99A);
      final reveal = Curves.easeOut.transform(
        ((t - spinEnd - .04) / (1 - spinEnd - .04)).clamp(0, 1),
      );
      final burst = Curves.easeOutCubic.transform(
        ((t - spinEnd) / (1 - spinEnd)).clamp(0, 1),
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          if (reveal > 0)
            ExcludeSemantics(
              child: IgnorePointer(
                child: Opacity(opacity: reveal, child: widget.child),
              ),
            ),
          Opacity(
            opacity: 1 - reveal,
            child: Scaffold(
              backgroundColor: const Color(0xFF102D22),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = math.min(
                      260.0,
                      math.min(
                        constraints.maxWidth * .72,
                        constraints.maxHeight * .48,
                      ),
                    );
                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          widget.isPreview ? '닉네임 컬렉션 · 샘플 미리보기' : '닉네임 컬렉션',
                          style: const TextStyle(
                            color: Color(0xFFC5D9BD),
                            letterSpacing: 2,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: SizedBox.square(
                              dimension: size,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          glowColor.withValues(
                                            alpha: .12 + burst * .35,
                                          ),
                                          const Color(0x00102D22),
                                        ],
                                      ),
                                    ),
                                  ),
                                  for (var i = 0; i < 16; i++)
                                    Transform.translate(
                                      offset: Offset(
                                        math.cos(i * math.pi / 8) *
                                            size *
                                            (.25 + burst * .42),
                                        math.sin(i * math.pi / 8) *
                                            size *
                                            (.25 + burst * .42),
                                      ),
                                      child: Opacity(
                                        opacity: math.sin(burst * math.pi),
                                        child: Transform.rotate(
                                          angle: i + burst * 2,
                                          child: Container(
                                            width: i.isEven ? 5 : 3,
                                            height: i.isEven ? 12 : 6,
                                            color: const Color(0xFFE8DFAB),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Semantics(
                                    button:
                                        !widget.waitingForResult && !_spinning,
                                    label: '카드를 터치해 뽑기 결과 열기',
                                    child: GestureDetector(
                                      key: const Key('gacha-card-touch'),
                                      onTap:
                                          widget.waitingForResult || _spinning
                                          ? null
                                          : _turnCard,
                                      child: Transform(
                                        key: const Key('gacha-card-turn'),
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, .0015)
                                          ..rotateY(
                                            widget.waitingForResult
                                                ? 0
                                                : spin * math.pi * 2 * turns,
                                          )
                                          ..rotateZ(
                                            math.sin(t * math.pi * 18) *
                                                .055 *
                                                (1 - burst),
                                          ),
                                        child: Transform.scale(
                                          scale:
                                              .9 +
                                              .1 * math.sin(t * math.pi) +
                                              burst * .12,
                                          child: Container(
                                            width: size * .58,
                                            height: size * .76,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  cardColor,
                                                  Color.lerp(
                                                    cardColor,
                                                    const Color(0xFF102D22),
                                                    .65,
                                                  )!,
                                                ],
                                              ),
                                              border: Border.all(
                                                color: enhanced
                                                    ? Color.lerp(
                                                        glowColor,
                                                        Colors.white,
                                                        .5,
                                                      )!
                                                    : const Color(0xFFE3D99A),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: glowColor.withValues(
                                                    alpha: .15 + burst * .35,
                                                  ),
                                                  blurRadius: 16 + 40 * burst,
                                                  spreadRadius: 8 * burst,
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.auto_awesome,
                                                color: Color(0xFFF2E9BB),
                                                size: 48,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          '어떤 취향을 만나게 될까요?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.waitingForResult
                              ? '나만의 분위기를 준비하는 중'
                              : _spinning
                              ? '어떤 아이템이 숨어 있을까요?'
                              : '카드를 터치해서 열어보세요',
                          style: TextStyle(color: Color(0xFFC5D9BD)),
                        ),
                        if (widget.waitingForResult)
                          const Padding(
                            padding: EdgeInsets.all(28),
                            child: Text(
                              '뽑기 결과를 확인하고 있어요.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        else if (_spinning)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextButton(
                              onPressed: () => _controller.value = 1,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white70,
                              ),
                              child: const Text('연출 건너뛰기'),
                            ),
                          )
                        else
                          const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
