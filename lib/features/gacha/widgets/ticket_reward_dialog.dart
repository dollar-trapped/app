import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Presentation only. Call after the server confirms the reward.
Future<void> showTicketReward(BuildContext context, {int? chipCost}) =>
    showDialog<void>(
      context: context,
      builder: (_) => TicketRewardDialog(chipCost: chipCost),
    );

class TicketRewardDialog extends StatelessWidget {
  const TicketRewardDialog({super.key, this.chipCost});
  final int? chipCost;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF008A29);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              chipCost == null ? '광고 보상 도착!' : '달러칩 교환 완료!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: reduced ? 1 : 0, end: 1),
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 1400),
                builder: (context, t, _) {
                  final merge = Curves.easeInCubic.transform(
                    (t / .55).clamp(0, 1),
                  );
                  final reveal = chipCost == null
                      ? t
                      : ((t - .4) / .6).clamp(0.0, 1.0);
                  final pop = Curves.easeOutBack.transform(reveal);
                  return SizedBox(
                    height: 180,
                    width: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEAF7EE),
                          ),
                        ),
                        if (chipCost != null && t < .6)
                          for (var i = 0; i < 10; i++)
                            Transform.translate(
                              offset:
                                  Offset(
                                    math.cos(i * math.pi / 5),
                                    math.sin(i * math.pi / 5),
                                  ) *
                                  (76 * (1 - merge)),
                              child: Opacity(
                                opacity: (1 - merge).clamp(0, 1),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9B949),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFB98716),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Text(
                                    r'$',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF674A00),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        if (reveal > 0)
                          Transform.scale(
                            scale: pop,
                            child: Transform.rotate(
                              angle: -.12 * (1 - reveal),
                              child: Container(
                                width: 136,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: green,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22008A29),
                                      blurRadius: 16,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.confirmation_number_outlined,
                                      color: Colors.white,
                                      size: 36,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      '+1',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Text(
              '뽑기권 1장 획득!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              chipCost == null
                  ? '새로운 닉네임 장식을 만나보세요.'
                  : '달러칩 $chipCost개가 뽑기권 1장으로 바뀌었어요.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF667069), fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
