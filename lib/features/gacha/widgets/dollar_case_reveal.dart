import 'dart:math' as math;
import 'package:flutter/material.dart';

Color dollarRarityColor(String rarity) => switch (rarity) {
  'SPECIAL' => const Color(0xFFFFD779),
  'RARE' => const Color(0xFF9DAEFF),
  _ => const Color(0xFFA5E3C0),
};

/// Server results determine every bill's light. No outcome is invented while waiting.
class DollarCaseReveal extends StatefulWidget {
  const DollarCaseReveal({
    super.key,
    required this.rarities,
    required this.child,
    this.waiting = false,
    this.count = 1,
    this.preview,
    this.rewardBuilder,
    this.onFinish,
  });
  final List<String> rarities;
  final Widget child;
  final bool waiting;
  final int count;
  final Widget? preview;
  final Widget Function(int index)? rewardBuilder;
  final VoidCallback? onFinish;
  @override
  State<DollarCaseReveal> createState() => _DollarCaseRevealState();
}

class _DollarCaseRevealState extends State<DollarCaseReveal>
    with TickerProviderStateMixin {
  late final _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6600),
  );
  late final _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  bool _started = false;
  int _revealed = -1;
  bool _all = false;
  bool get _ready => !widget.waiting && widget.rarities.length == widget.count;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant DollarCaseReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waiting && !oldWidget.waiting) {
      _drop.reset();
      _open.reset();
      _started = false;
      _revealed = -1;
      _all = false;
    }
    _sync();
  }

  void _sync() {
    if (!_ready) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _drop.value = 1;
      if (_open.isAnimating) _open.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _drop.forward(from: 0);
    }
  }

  void _openCase() {
    if (!_ready || !_drop.isCompleted) return;
    if (_open.isAnimating) {
      if (widget.rewardBuilder != null) _open.value = 1;
      return;
    }
    if (widget.rewardBuilder != null) {
      if (_revealed >= widget.count - 1) {
        widget.onFinish?.call();
        return;
      }
      setState(() => _revealed++);
    } else if (_open.value > 0) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _open.value = 1;
    } else {
      _open.forward(from: 0);
    }
  }

  void _skip() {
    if (widget.rewardBuilder != null) {
      setState(() {
        _all = true;
        _revealed = widget.count - 1;
      });
      _drop.value = 1;
    }
    _open.value = 1;
  }

  @override
  void dispose() {
    _drop.dispose();
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_drop, _open]),
    builder: (context, _) {
      if (widget.rewardBuilder == null && _ready && _open.isCompleted) {
        return widget.child;
      }
      final fade = widget.rewardBuilder == null
          ? ((_open.value - .8) / .2).clamp(0.0, 1.0)
          : 0.0;
      final arrived = _ready && _drop.value * 6.6 >= 5.55 ? widget.count : 0;
      final emergence = Curves.easeInOutCubic.transform(
        ((_open.value - .4) / .55).clamp(0.0, 1.0),
      );
      final finished = _revealed == widget.count - 1 && _open.isCompleted;
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF081711)),
          if (fade > 0)
            IgnorePointer(
              child: ExcludeSemantics(
                child: Opacity(opacity: fade, child: widget.child),
              ),
            ),
          Opacity(
            opacity: 1 - fade,
            child: Scaffold(
              backgroundColor: const Color(0xFF081711),
              body: GestureDetector(
                key: const Key('case-background-touch'),
                behavior: HitTestBehavior.opaque,
                onTap: _openCase,
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        widget.count == 10 ? '닉네임 컬렉션 · 10회 뽑기' : '닉네임 컬렉션',
                        style: const TextStyle(
                          color: Color(0xFFAFC6BA),
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _revealed >= 0
                            ? '${_revealed + 1} / ${widget.count} 공개'
                            : _ready
                            ? '$arrived / ${widget.count}'
                            : '보상을 준비하고 있어요',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, bounds) {
                            final width = math.min(bounds.maxWidth, 520.0);
                            return Center(
                              child: SizedBox(
                                width: width,
                                height: bounds.maxHeight,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    RepaintBoundary(
                                      child: CustomPaint(
                                        key: const Key('dollar-case-scene'),
                                        painter: DollarCasePainter(
                                          rarities: _ready
                                              ? widget.rarities
                                              : const [],
                                          count: widget.count,
                                          drop: _drop.value,
                                          opening: _revealed > 0
                                              ? 1
                                              : _open.value,
                                          showRewardLights:
                                              widget.rewardBuilder == null,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: width * .08,
                                      right: width * .08,
                                      bottom:
                                          45 *
                                          math.min(
                                            width / 360,
                                            bounds.maxHeight / 520,
                                          ),
                                      child: Semantics(
                                        button: true,
                                        label: '돈 가방을 열어 보상 확인',
                                        enabled: _ready && _drop.isCompleted,
                                        child: GestureDetector(
                                          key: const Key('gacha-case-touch'),
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _openCase,
                                          child: SizedBox(
                                            width: width * .82,
                                            height:
                                                135 *
                                                math.min(
                                                  width / 360,
                                                  bounds.maxHeight / 520,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (widget.rewardBuilder != null &&
                                        _revealed >= 0)
                                      Positioned(
                                        left: 20,
                                        right: 20,
                                        top: 12,
                                        height: math.max(
                                          0,
                                          bounds.maxHeight -
                                              180 *
                                                  math.min(
                                                    width / 360,
                                                    bounds.maxHeight / 520,
                                                  ),
                                        ),
                                        child: Opacity(
                                          opacity: _all
                                              ? 1
                                              : ((_open.value - .4) / .2).clamp(
                                                  0.0,
                                                  1.0,
                                                ),
                                          child: Transform.translate(
                                            offset: Offset(
                                              0,
                                              _all
                                                  ? 0
                                                  : (bounds.maxHeight -
                                                            170 *
                                                                math.min(
                                                                  width / 360,
                                                                  bounds.maxHeight /
                                                                      520,
                                                                )) *
                                                        (1 - emergence),
                                            ),
                                            child: Transform.scale(
                                              key: const Key(
                                                'case-reward-scale',
                                              ),
                                              alignment: Alignment.topCenter,
                                              scale: _all
                                                  ? 1
                                                  : .12 + .88 * emergence,
                                              child: IgnorePointer(
                                                ignoring: !_open.isCompleted,
                                                child: SingleChildScrollView(
                                                  child: Column(
                                                    children: [
                                                      if (_all)
                                                        for (
                                                          var i = 0;
                                                          i < widget.count;
                                                          i++
                                                        )
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  bottom: 12,
                                                                ),
                                                            child: widget
                                                                .rewardBuilder!(i),
                                                          )
                                                      else
                                                        widget.rewardBuilder!(
                                                          _revealed,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (widget.preview != null &&
                                        _open.value > .48)
                                      IgnorePointer(
                                        child: Align(
                                          alignment: const Alignment(0, -.4),
                                          child: Opacity(
                                            opacity: ((_open.value - .48) / .18)
                                                .clamp(0.0, 1.0),
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                20 * (1 - _open.value),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  24,
                                                ),
                                                child: widget.preview!,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (widget.rewardBuilder != null &&
                                        _open.isAnimating)
                                      Positioned.fill(
                                        child: GestureDetector(
                                          key: const Key('skip-item-emergence'),
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _openCase,
                                          child: const SizedBox.expand(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: 56,
                        child: _ready
                            ? TextButton(
                                onPressed: finished ? widget.onFinish : _skip,
                                child: Text(
                                  finished ? '확인' : '바로 열기',
                                  style: const TextStyle(
                                    color: Color(0xFFAFC6BA),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// Original vector artwork: brushed aluminium shell, latches, handle and banknotes.
class DollarCasePainter extends CustomPainter {
  const DollarCasePainter({
    required this.rarities,
    required this.count,
    required this.drop,
    required this.opening,
    this.showRewardLights = true,
  });
  final List<String> rarities;
  final int count;
  final double drop, opening;
  final bool showRewardLights;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // Uniform scaling preserves the case on short screens and foldables.
    final scale = math.min(size.width / 360, size.height / 520);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - 360 * scale) / 2, size.height - 480 * scale);
    canvas.scale(scale);
    final skyY = -(size.height - 480 * scale) / scale + 24;
    final time = drop * 6.6;
    final formation = Curves.easeInOutCubic.transform(
      ((time - 1.1) / .95).clamp(0.0, 1.0),
    );
    final flight = ((time - 2.2) / 3.35).clamp(0.0, 1.0);
    final plunge = Curves.easeInCubic.transform(
      ((time - 4.85) / .7).clamp(0.0, 1.0),
    );
    final caseReveal = Curves.easeOutCubic.transform(
      ((time - 4.65) / .9).clamp(0.0, 1.0),
    );
    final caseOffset = (size.height / scale + 180) * (1 - caseReveal);
    final impactTime = ((time - 5.55) / 1.05).clamp(0.0, 1.0);
    final shake = time > 5.55 && time < 5.9
        ? math.sin((time - 5.55) * 70) * 3 * (1 - (time - 5.55) / .35)
        : 0.0;
    final middleY = (skyY + 360) / 2;
    // Camera follows the falling lights; upward streaks accelerate behind them.
    if (flight > 0 && flight < 1) {
      final span = 480 - skyY;
      for (var i = 0; i < 18; i++) {
        final x = 10.0 + (i * 47 % 340);
        final y = skyY + ((i * 71 - flight * flight * 2600) % span);
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y - 20 - flight * 85),
          Paint()
            ..strokeWidth = i.isEven ? 1 : .5
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFFB9D3C9).withValues(alpha: .06 + flight * .13),
              ],
            ).createShader(Rect.fromLTWH(x, y - 110, 1, 110)),
        );
      }
    }
    canvas.save();
    canvas.translate(shake, caseOffset);
    final open = Curves.easeInOutCubic.transform(
      (opening / .62).clamp(0.0, 1.0),
    );
    final accent = rarities.contains('SPECIAL')
        ? dollarRarityColor('SPECIAL')
        : rarities.contains('RARE')
        ? dollarRarityColor('RARE')
        : dollarRarityColor('COMMON');
    canvas.drawOval(
      const Rect.fromLTWH(35, 409, 290, 35),
      Paint()
        ..color = Colors.black.withValues(alpha: .4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // Spotlight stays neutral until the money has landed.
    final glow = drop == 1 ? accent : const Color(0xFFAFC6BA);
    canvas.drawCircle(
      const Offset(180, 320),
      160,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glow.withValues(alpha: .04 + open * .14),
            Colors.transparent,
          ],
        ).createShader(const Rect.fromLTWH(20, 160, 320, 320)),
    );
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(47, 326, 266, 92),
      const Radius.circular(13),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE3E8E9),
            Color(0xFF8C9A9F),
            Color(0xFFCFD7DA),
            Color(0xFF64747B),
          ],
        ).createShader(body.outerRect),
    );
    canvas.save();
    canvas.clipRRect(body);
    for (double y = 335; y < 418; y += 4) {
      canvas.drawLine(
        Offset(48, y),
        Offset(312, y),
        Paint()
          ..color = Colors.white.withValues(alpha: .11)
          ..strokeWidth = .6,
      );
    }
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFDAE3E7),
    );
    // Recessed metal face and protective corner caps give the shell depth.
    final panel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(59, 359, 242, 47),
      const Radius.circular(7),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF52636C), Color(0xFFAFBBC1), Color(0xFF76868F)],
        ).createShader(panel.outerRect),
    );
    canvas.drawRRect(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFE7ECEF)
        ..strokeWidth = 1,
    );
    for (final x in [70.0, 91.0, 112.0, 239.0, 260.0, 281.0]) {
      canvas.drawLine(
        Offset(x, 367),
        Offset(x, 397),
        Paint()
          ..color = const Color(0xFF53646E)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(x + 1.5, 367),
        Offset(x + 1.5, 397),
        Paint()
          ..color = const Color(0xFFD8E1E5)
          ..strokeWidth = 1,
      );
    }
    for (final x in [48.0, 294.0]) {
      for (final y in [333.0, 398.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 18, 18),
            const Radius.circular(5),
          ),
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFFDAE2E7), Color(0xFF586975)],
            ).createShader(Rect.fromLTWH(x, y, 18, 18)),
        );
      }
    }
    // The interior is uncovered by the hinged lid.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(55, 325, 250, 34),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF1D2929),
    );
    if (open > 0) {
      final beam = Path()
        ..moveTo(62, 341)
        ..lineTo(95, 120)
        ..lineTo(265, 120)
        ..lineTo(298, 341)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              accent.withValues(alpha: open * .55),
              accent.withValues(alpha: 0),
            ],
          ).createShader(const Rect.fromLTWH(60, 120, 240, 225)),
      );
    }
    canvas.restore();
    // Ignition, formation, tracked descent, then a synchronized impact.
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(-100, skyY - 180, 460, 315));
    for (var i = 0; i < rarities.length; i++) {
      final ignition = time - i * .085;
      if (ignition <= 0) continue;
      final endX = count == 1 ? 180.0 : 79 + i * 22.0;
      final startX = count == 1 ? 180.0 : 36 + i * 32.0;
      final color = dollarRarityColor(rarities[i]);
      final scatteredY = skyY + 15 + (i * 37 % 70);
      final alignedX = startX;
      final lightX = startX + math.sin(i * 2.4) * 9 * (1 - formation);
      final lightY = scatteredY + (middleY - scatteredY) * formation;
      final flash = math.sin((ignition / .25).clamp(0.0, 1.0) * math.pi);
      if (flash > 0) {
        canvas.drawCircle(
          Offset(lightX, lightY),
          30 * flash,
          Paint()
            ..color = color.withValues(alpha: .55 * flash)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(lightX, lightY),
            width: 58 * flash,
            height: 3,
          ),
          Paint()..color = color.withValues(alpha: flash),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(lightX, lightY),
            width: 3,
            height: 36 * flash,
          ),
          Paint()..color = Colors.white.withValues(alpha: flash),
        );
      }
      if (ignition < .12 || flight >= 1) continue;
      final t = plunge;
      final x = lightX + (endX - alignedX) * t;
      final y = lightY + (367 - lightY) * t;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(flight * (1 - flight) * (i.isEven ? -.18 : .18));
      canvas.scale(.65 + .35 * t);
      final trail = Path()
        ..moveTo(-14, 0)
        ..lineTo(-5, -130)
        ..lineTo(5, -130)
        ..lineTo(14, 0)
        ..close();
      canvas.drawPath(
        trail,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              color.withValues(alpha: .7 * flight),
              color.withValues(alpha: 0),
            ],
          ).createShader(const Rect.fromLTWH(-14, -130, 28, 130)),
      );
      canvas.drawCircle(
        Offset.zero,
        time < 5.05 ? 16 : 25,
        Paint()
          ..color = color.withValues(alpha: .45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      if (time < 5.05) {
        canvas.drawCircle(Offset.zero, 4, Paint()..color = Colors.white);
        canvas.drawOval(
          const Rect.fromLTWH(-11, -1, 22, 2),
          Paint()..color = color,
        );
        canvas.drawOval(
          const Rect.fromLTWH(-1, -14, 2, 28),
          Paint()..color = color,
        );
        canvas.restore();
        continue;
      }
      final note = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-16, -30, 32, 60),
        const Radius.circular(3),
      );
      canvas.drawRRect(note, Paint()..color = const Color(0xFFD4E8D6));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-12, -26, 24, 52),
          const Radius.circular(2),
        ),
        Paint()
          ..color = const Color(0xFF476C55)
          ..style = PaintingStyle.stroke,
      );
      canvas.drawOval(
        const Rect.fromLTWH(-9, -13, 18, 26),
        Paint()..color = const Color(0xFF799F80),
      );
      _text(canvas, r'$', const Offset(-6, -13), 19, const Color(0xFFE7F4DC));
      canvas.restore();
    }
    canvas.restore();
    canvas.save();
    canvas.translate(shake, caseOffset);
    // Closed lid masks the bottom of arriving notes; an inset slot receives them.
    final lidTop = 303 - open * 98;
    final lid = Path()
      ..moveTo(48 + open * 10, lidTop)
      ..lineTo(312 - open * 10, lidTop)
      ..lineTo(313, 335)
      ..lineTo(47, 335)
      ..close();
    canvas.drawPath(
      lid,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF0F3F3),
            const Color(0xFF9BA9AE),
            const Color(0xFF5D6D75),
          ],
        ).createShader(Rect.fromLTRB(47, lidTop, 313, 335)),
    );
    canvas.drawPath(
      lid,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFD6E0E2)
        ..strokeWidth = 2,
    );
    if (open > .05) {
      final inside = RRect.fromRectAndRadius(
        Rect.fromLTRB(61, lidTop + 9, 299, 329),
        const Radius.circular(6),
      );
      canvas.drawRRect(
        inside,
        Paint()..color = const Color(0xFF182523).withValues(alpha: open),
      );
      canvas.drawRRect(
        inside,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = accent.withValues(alpha: open * .5),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(64, 314, 232, 5),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF263A32),
      );
      // Small colored indicators retain the individual rarity information after arrival.
      for (var i = 0; i < rarities.length; i++) {
        if (time < 5.55) continue;
        final x = count == 1 ? 180.0 : 79 + i * 22.0;
        canvas.drawCircle(
          Offset(x, 316),
          2.5,
          Paint()
            ..color = dollarRarityColor(rarities[i])
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
    }
    // Front handle and paired locking clasps.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(144, 353, 72, 31),
        const Radius.circular(8),
      ),
      Paint()
        ..color = const Color(0xFF293938)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    if (opening == 0) {
      for (var i = 0; i < rarities.length; i++) {
        final impact = (time - 5.55) / .22;
        if (impact <= 0 || impact >= 1) continue;
        final x = count == 1 ? 180.0 : 79 + i * 22.0;
        final color = dollarRarityColor(rarities[i]);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, 314),
            width: 12 + impact * 48,
            height: 3 + impact * 9,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = color.withValues(alpha: 1 - impact),
        );
        for (var spark = 0; spark < 5; spark++) {
          final angle = math.pi * (1.15 + spark * .175);
          final distance = 8 + impact * 30;
          canvas.drawCircle(
            Offset(
              x + math.cos(angle) * distance,
              314 + math.sin(angle) * distance,
            ),
            1.5 * (1 - impact),
            Paint()..color = color.withValues(alpha: 1 - impact),
          );
        }
      }
    }
    for (final x in [84.0, 261.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 10, 338, 20, 30),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFECF0EE),
      );
      canvas.drawRect(
        Rect.fromLTWH(x - 6, 344, 12, 8),
        Paint()..color = const Color(0xFF66777C),
      );
    }
    for (final point in [
      const Offset(58, 344),
      const Offset(302, 344),
      const Offset(58, 404),
      const Offset(302, 404),
    ]) {
      canvas.drawCircle(point, 2, Paint()..color = const Color(0xFF3E5057));
    }
    if (showRewardLights && opening > .38) {
      final lift = Curves.easeOutCubic.transform(
        ((opening - .38) / .35).clamp(0.0, 1.0),
      );
      for (var i = 0; i < rarities.length; i++) {
        final x = count == 1 ? 180.0 : 77 + (i % 5) * 51.0;
        final y =
            322 -
            lift *
                (count == 1
                    ? 165
                    : i < 5
                    ? 185
                    : 130);
        final color = dollarRarityColor(rarities[i]);
        canvas.drawCircle(
          Offset(x, y),
          12,
          Paint()
            ..color = color.withValues(alpha: .3 * lift)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
        final sparkle = Path()
          ..moveTo(x, y - 12)
          ..lineTo(x + 3, y - 3)
          ..lineTo(x + 10, y)
          ..lineTo(x + 3, y + 3)
          ..lineTo(x, y + 12)
          ..lineTo(x - 3, y + 3)
          ..lineTo(x - 10, y)
          ..lineTo(x - 3, y - 3)
          ..close();
        canvas.drawPath(
          sparkle,
          Paint()..color = color.withValues(alpha: lift),
        );
      }
    }
    if (impactTime > 0 && impactTime < 1 && opening == 0) {
      for (var i = 0; i < 16; i++) {
        final direction = i.isEven ? -1.0 : 1.0;
        final x = 180 + direction * (35 + impactTime * (90 + i * 3));
        final y = 321 - math.sin(impactTime * math.pi * .75) * (12 + i % 4 * 9);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 18 + impactTime * 65,
            height: 8 + impactTime * 18,
          ),
          Paint()
            ..color = const Color(
              0xFFC2CEC4,
            ).withValues(alpha: (1 - impactTime) * .13)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }
    canvas.restore();
    canvas.restore();
  }

  void _text(
    Canvas canvas,
    String text,
    Offset at,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Noto Sans KR',
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at);
    painter.dispose();
  }

  @override
  bool shouldRepaint(DollarCasePainter oldDelegate) =>
      showRewardLights != oldDelegate.showRewardLights ||
      drop != oldDelegate.drop ||
      opening != oldDelegate.opening ||
      rarities != oldDelegate.rarities ||
      count != oldDelegate.count;
}
