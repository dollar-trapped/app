import 'package:flutter/material.dart';

/// Launch-event reward schedule. UI only; the server owns attendance and grants.
const launchAttendanceRewards = [1, 1, 2, 2, 3, 3, 8];

/// Presentation snapshot. A future server adapter supplies these values.
class AttendanceViewData {
  const AttendanceViewData({
    required this.completedCount,
    this.checking = false,
    this.todayCompleted = false,
    this.newReward,
  }) : assert(completedCount >= 0 && completedCount <= 7);

  final int completedCount;
  final bool checking;
  final bool todayCompleted;
  final int? newReward;
  bool get complete => completedCount == 7;
}

class AttendanceEventDialog extends StatelessWidget {
  const AttendanceEventDialog({
    super.key,
    required this.data,
    required this.onClose,
    required this.onReward,
    this.preview = false,
  });
  final AttendanceViewData data;
  final VoidCallback onClose;
  final VoidCallback onReward;
  final bool preview;

  static const green = Color(0xFF008A29);
  static const ink = Color(0xFF172B20);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFFF8FBF8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '출시 기념 출석 이벤트',
                      style: const TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '매일 한 번, 누적 7회 출석하면 총 20장',
                      style: TextStyle(color: Color(0xFF5D7265), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final largeText =
                            MediaQuery.textScalerOf(context).scale(14) > 19;
                        final columns = constraints.maxWidth >= 540
                            ? 7
                            : largeText || constraints.maxWidth < 290
                            ? 3
                            : 4;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 8) /
                            columns;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: [
                            for (var i = 0; i < 7; i++)
                              SizedBox(width: width, child: _day(context, i)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(
                          '${data.checking}-${data.newReward}-${data.complete}',
                        ),
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5ED),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          data.checking
                              ? '오늘의 출석을 확인하고 있어요…'
                              : data.complete
                              ? '20장 모두 받았어요!'
                              : data.newReward != null
                              ? '${data.completedCount}회차 출석 완료! 뽑기권 ${data.newReward}장을 받았어요.'
                              : '오늘 출석 완료',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: green,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: data.checking
                          ? null
                          : data.newReward != null
                          ? onReward
                          : onClose,
                      child: Text(
                        data.checking
                            ? '출석 확인 중'
                            : data.newReward != null
                            ? '보상 확인'
                            : '닫기',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '하루 쉬어도 괜찮아요.\n다음 접속 때 이어서 출석할 수 있어요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7A70),
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '신규 참가는 출시 이벤트 시작 후 30일 동안\n참가 후에는 완료 기한 없이 7회까지 · 하루 1회, 한국 시간 기준',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7D8B82),
                        fontSize: 10,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF006C2C), Color(0xFF00A23D)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                preview
                    ? '디자인 미리보기 · 실제 지급 없음'
                    : 'DOLLARMULLIM  /  LAUNCH EVENT',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .75),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
              tooltip: '닫기',
              onPressed: onClose,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '출석할 때마다\n뽑기권이 쌓여요',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _pill('누적 ${data.completedCount} / 7회'),
            _pill(data.complete ? '이벤트 완료' : '총 20장 선물'),
          ],
        ),
      ],
    ),
  );

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .2)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _day(BuildContext context, int index) {
    final done = index < data.completedCount;
    final today =
        done && data.todayCompleted && index == data.completedCount - 1;
    final gold = index == 6;
    final color = gold ? const Color(0xFFAC7215) : green;
    return Semantics(
      label:
          '누적 ${index + 1}회차, 뽑기권 ${launchAttendanceRewards[index]}장, ${done ? '수령 완료' : '미수령'}',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 350),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(
            color: gold
                ? const Color(0xFFFFF4D8)
                : done
                ? const Color(0xFFE8F4EB)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: today
                  ? color
                  : gold
                  ? const Color(0xFFECCB83)
                  : done
                  ? const Color(0xFFBDDEC7)
                  : const Color(0xFFE1E8E2),
              width: today ? 2 : 1,
            ),
            boxShadow: today
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .12),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                '${index + 1}회차',
                style: TextStyle(
                  color: done || gold ? color : const Color(0xFF6C7D72),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: -.15,
                    child: Icon(
                      Icons.confirmation_number_rounded,
                      color: done ? color.withValues(alpha: .3) : color,
                      size: 36,
                    ),
                  ),
                  if (done)
                    TweenAnimationBuilder<double>(
                      key: Key('attendance-stamp-${index + 1}'),
                      tween: Tween(
                        begin: today && !MediaQuery.disableAnimationsOf(context)
                            ? 0
                            : 1,
                        end: 1,
                      ),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOutBack,
                      builder: (_, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${launchAttendanceRewards[index]}장',
                style: TextStyle(
                  color: color,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                done
                    ? '받았어요'
                    : gold
                    ? '마지막 선물'
                    : '뽑기권',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: done || gold ? color : const Color(0xFF94A097),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
