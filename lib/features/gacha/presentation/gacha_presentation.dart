import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gacha_controller.dart';
import 'gacha_feedback.dart';
import 'gacha_result.dart';
import 'grade_config.dart';
import 'painters/gacha_scene_painter.dart';
import 'film/gacha_film_driver.dart';
import 'film/gacha_film_layer.dart';

class GachaPresentation extends StatefulWidget {
  const GachaPresentation({
    super.key,
    required this.result,
    this.quality = GachaQuality.high,
    this.configs = GradeConfig.defaults,
    this.resultBuilder,
    this.previewBuilder,
    this.onFinish,
    this.audio,
    this.haptics,
    this.useBlenderFilm = true,
  });
  final GachaResult result;
  final GachaQuality quality;
  final Map<GachaGrade, GradeConfig> configs;
  final WidgetBuilder? resultBuilder;
  final IndexedWidgetBuilder? previewBuilder;
  final VoidCallback? onFinish;

  /// Injected feedback belongs to this route and is disposed with it.
  final GachaAudio? audio;
  final GachaHaptics? haptics;
  final bool useBlenderFilm;
  @override
  State<GachaPresentation> createState() => GachaPresentationState();
}

class GachaPresentationState extends State<GachaPresentation>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final GachaController controller;
  late final GachaSceneResources resources;
  GachaFilmDriver? film;
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = GachaController(
      vsync: this,
      result: widget.result,
      configs: widget.configs,
      audio: widget.audio,
      haptics: widget.haptics,
    );
    resources = GachaSceneResources(widget.result, widget.quality);
    if (widget.useBlenderFilm) {
      film = GachaFilmDriver(controller, onFallback: _prepareFallback)
        ..addListener(_filmChanged);
    } else {
      _prepareFallback();
    }
  }

  void _prepareFallback() {
    resources.prepareSmoke();
    resources.caseFrames.prepare();
  }

  void _filmChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (!_ready) {
      if (reduced || film == null) {
        controller.start(reduced: reduced);
      } else {
        film!.start();
      }
      _ready = true;
    } else if (reduced) {
      controller.skip();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (film != null) {
        film!.resume();
      } else {
        controller.resume();
      }
    } else {
      if (film != null) {
        film!.pause();
      } else {
        controller.pause();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    film?.removeListener(_filmChanged);
    film?.dispose();
    controller.dispose();
    resources.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: GachaStyle.night,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: GachaStyle.night,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (film?.ready ?? false)
            GachaFilmLayer(film: film!, resources: resources)
          else if (film != null && !film!.failed)
            Image.asset(
              'assets/gacha/film/poster.jpg',
              fit: BoxFit.contain,
              errorBuilder: (_, error, stack) =>
                  const ColoredBox(color: GachaStyle.night),
            )
          else ...[
            RepaintBoundary(
              child: CustomPaint(
                painter: GachaSkyPainter(resources, controller),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                key: const Key('gacha-procedural-scene'),
                painter: GachaScenePainter(
                  controller: controller,
                  resources: resources,
                ),
              ),
            ),
          ],
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              if (controller.complete) return _results(context);
              final index = controller.timeline.cardIndex(controller.ms);
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (index >= 0)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 60, 24, 94),
                        child: Align(
                          alignment: const Alignment(0, -.25),
                          child: _card(context, index),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Semantics(
                      label: '연출 건너뛰기',
                      button: true,
                      child: GestureDetector(
                        key: const Key('gacha-skip-surface'),
                        behavior: HitTestBehavior.opaque,
                        onTap: controller.skip,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: controller.skip,
                        child: const Text(
                          '건너뛰기',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  if (index >= 0)
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      child: SafeArea(
                        top: false,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (
                              var i = 0;
                              i < widget.result.rewards.length;
                              i++
                            )
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i <= index
                                        ? widget
                                              .configs[widget
                                                  .result
                                                  .rewards[i]
                                                  .grade]!
                                              .color
                                        : Colors.white12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
  Widget _card(BuildContext context, int index) {
    final reward = widget.result.rewards[index],
        config = widget.configs[reward.grade]!;
    final progress = controller.timeline.cardProgress(controller.ms, index);
    final flip = Curves.easeInOutCubic.transform((progress / .48).clamp(0, 1));
    final front = flip >= .5;
    final angle = front ? (1 - flip) * math.pi : -flip * math.pi;
    // Keep the last card visible while the light fades before the summary.
    final opacity = index == widget.result.rewards.length - 1
        ? 1.0
        : 1 -
              Curves.easeInCubic.transform(
                ((progress - .92) / .08).clamp(0, 1),
              );
    final glow = reward.grade == GachaGrade.special ? 36.0 : 18.0;
    Widget staged(Widget child, double start) => Opacity(
      opacity: Curves.easeOutCubic.transform(
        ((progress - start) / .15).clamp(0, 1),
      ),
      child: child,
    );
    return ExcludeSemantics(
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0018)
            ..rotateY(angle),
          child: Container(
            key: ValueKey('gacha-card-$index'),
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            decoration: BoxDecoration(
              color: GachaStyle.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: config.color.withValues(alpha: .75)),
              boxShadow: [
                BoxShadow(
                  color: config.color.withValues(alpha: .28),
                  blurRadius: glow,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!front) ...[
                    Text(
                      r'$',
                      style: TextStyle(
                        fontSize: 100,
                        color: config.color,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const Text(
                      'D O L L A R',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ] else ...[
                    staged(
                      Text(
                        config.label,
                        style: TextStyle(
                          color: config.color,
                          fontSize: 12,
                          letterSpacing: 4,
                        ),
                      ),
                      .23,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 100,
                      child: Center(
                        child:
                            widget.previewBuilder?.call(context, index) ??
                            Text(
                              r'$',
                              style: TextStyle(
                                fontSize: 76,
                                color: config.color,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    staged(
                      Text(
                        reward.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      .42,
                    ),
                    const SizedBox(height: 14),
                    staged(
                      Text(
                        reward.duplicate
                            ? '중복 · 달러칩 +${reward.chips}'
                            : '새로운 아이템',
                        style: TextStyle(color: config.color, fontSize: 13),
                      ),
                      .61,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${index + 1} / ${widget.result.rewards.length}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(BuildContext context) => SafeArea(
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child:
                widget.resultBuilder?.call(context) ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: const Text(
                        '획득 결과',
                        style: TextStyle(color: Colors.white, fontSize: 26),
                      ),
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < widget.result.rewards.length; i++)
                      ListTile(
                        key: ValueKey('gacha-result-$i'),
                        leading: Text(
                          '${i + 1}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        title: Text(
                          widget.result.rewards[i].title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          widget.configs[widget.result.rewards[i].grade]!.label,
                          style: TextStyle(
                            color: widget
                                .configs[widget.result.rewards[i].grade]!
                                .color,
                          ),
                        ),
                        trailing: Text(
                          widget.result.rewards[i].duplicate
                              ? '+${widget.result.rewards[i].chips}칩'
                              : 'NEW',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                  ],
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  widget.onFinish ?? () => Navigator.of(context).maybePop(),
              child: const Text('확인'),
            ),
          ),
        ),
      ],
    ),
  );
}
