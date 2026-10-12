import 'package:flutter/material.dart';
import '../presentation/gacha_result.dart';
import '../presentation/gacha_presentation.dart';
import '../presentation/grade_config.dart';

Color dollarRarityColor(String rarity) =>
    GradeConfig.defaults[GachaGrade.fromServer(rarity)]!.color;
String dollarRarityLabel(String rarity) =>
    GradeConfig.defaults[GachaGrade.fromServer(rarity)]!.label;

/// Compatibility boundary for existing result pages. Only confirmed data may
/// create a presentation; the waiting screen has no animation or invented grade.
class DollarCaseReveal extends StatefulWidget {
  const DollarCaseReveal({
    super.key,
    required this.rarities,
    required this.child,
    this.waiting = false,
    this.count = 1,
    this.preview,
    this.rewardBuilder,
    this.summaryBuilder,
    this.onFinish,
    this.result,
    this.previewBuilder,
    this.quality = GachaQuality.high,
  });
  final List<String> rarities;
  final Widget child;
  final bool waiting;
  final int count;
  final Widget? preview;
  final Widget Function(int)? rewardBuilder;
  final Widget Function()? summaryBuilder;
  final VoidCallback? onFinish;
  final GachaResult? result;
  final IndexedWidgetBuilder? previewBuilder;
  final GachaQuality quality;
  @override
  State<DollarCaseReveal> createState() => _DollarCaseRevealState();
}

class _DollarCaseRevealState extends State<DollarCaseReveal> {
  GachaResult? _snapshot;
  @override
  Widget build(BuildContext context) {
    if (widget.waiting || widget.rarities.length != widget.count) {
      return Scaffold(
        backgroundColor: GachaStyle.night,
        body: Center(
          child: Semantics(
            liveRegion: true,
            child: const Text(
              '뽑기 결과를 확인하는 중…',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }
    _snapshot ??=
        widget.result ??
        GachaResult(
          rewards: [
            for (var i = 0; i < widget.rarities.length; i++)
              GachaReward(
                id: 'legacy-$i',
                grade: GachaGrade.fromServer(widget.rarities[i]),
                title: '획득한 아이템',
              ),
          ],
        );
    return GachaPresentation(
      result: _snapshot!,
      quality: widget.quality,
      onFinish: widget.onFinish,
      previewBuilder: widget.previewBuilder,
      resultBuilder: (context) {
        if (widget.count == 10 && widget.summaryBuilder != null) {
          return widget.summaryBuilder!();
        }
        if (widget.rewardBuilder != null) return widget.rewardBuilder!(0);
        // Legacy callers may supply a complete Scaffold, which needs bounds.
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: widget.child,
        );
      },
    );
  }
}
