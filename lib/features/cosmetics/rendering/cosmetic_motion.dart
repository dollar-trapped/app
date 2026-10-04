import 'package:flutter/material.dart';

class CosmeticMotion extends StatefulWidget {
  const CosmeticMotion({super.key, required this.builder});
  final Widget Function(double) builder;
  @override
  State<CosmeticMotion> createState() => CosmeticMotionState();
}

class CosmeticMotionState extends State<CosmeticMotion>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(_controller.value),
    ),
  );
}
