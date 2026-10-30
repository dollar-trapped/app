import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One animation and one accessible loading label for a group of placeholders.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.label,
    required this.child,
    this.active = true,
  });

  final String label;
  final Widget child;
  final bool active;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _opacity = _controller.drive(
    Tween<double>(
      begin: .58,
      end: 1,
    ).chain(CurveTween(curve: Curves.easeInOut)),
  );
  bool _animate = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant Skeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _syncAnimation();
  }

  void _syncAnimation() {
    _animate =
        widget.active &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (_animate) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    return Semantics(
      container: true,
      label: widget.label,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: _animate
              ? FadeTransition(opacity: _opacity, child: widget.child)
              : widget.child,
        ),
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height, radius;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Color.lerp(colors.surface, colors.line, .65),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Text-shaped placeholders also follow the user's text size setting.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width, this.height = 18});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => SkeletonBox(
    width: width,
    height: MediaQuery.textScalerOf(context).scale(height),
    radius: 6,
  );
}
