import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Presentation only: the draw has already been confirmed by the server.
class GachaReveal extends StatefulWidget {
  const GachaReveal({super.key, required this.child, this.isPreview = false});
  final Widget child;
  final bool isPreview;

  @override
  State<GachaReveal> createState() => _GachaRevealState();
}

class _GachaRevealState extends State<GachaReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward();
    }
    _started = true;
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
      if (t == 1) return widget.child;
      final reveal = Curves.easeOut.transform(((t - .76) / .24).clamp(0, 1));
      final burst = Curves.easeOutCubic.transform(
        ((t - .48) / .45).clamp(0, 1),
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
                                          const Color(0xFFE3D99A).withValues(
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
                                  Transform.rotate(
                                    angle:
                                        math.sin(t * math.pi * 18) *
                                        .055 *
                                        (1 - burst),
                                    child: Transform.scale(
                                      scale:
                                          .9 +
                                          .1 * math.sin(t * math.pi) +
                                          burst * .12,
                                      child: Container(
                                        width: size * .58,
                                        height: size * .76,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF447956),
                                              Color(0xFF173E2B),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE3D99A),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFE3D99A,
                                              ).withValues(alpha: burst * .35),
                                              blurRadius: 40 * burst,
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
                        const Text(
                          '나만의 분위기를 여는 중',
                          style: TextStyle(color: Color(0xFFC5D9BD)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextButton(
                            onPressed: () => _controller.value = 1,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: const Text('연출 건너뛰기'),
                          ),
                        ),
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
