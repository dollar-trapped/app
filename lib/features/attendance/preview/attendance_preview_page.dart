import 'dart:async';

import 'package:flutter/material.dart';

import '../../gacha/widgets/ticket_reward_dialog.dart';
import '../widgets/attendance_event_dialog.dart';

/// Offline fixtures only. Never calls a server or changes an account balance.
class AttendancePreviewPage extends StatefulWidget {
  const AttendancePreviewPage({
    super.key,
    this.initialRound = 1,
    this.alreadyAttended = false,
  }) : assert(initialRound >= 1 && initialRound <= 7);
  final int initialRound;
  final bool alreadyAttended;
  @override
  State<AttendancePreviewPage> createState() => _AttendancePreviewPageState();
}

class _AttendancePreviewPageState extends State<AttendancePreviewPage> {
  late int _round = widget.initialRound;
  late bool _alreadyAttended = widget.alreadyAttended;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play();
    });
  }

  Future<void> _play() async {
    if (_open) return;
    setState(() => _open = true);
    final snapshot = ValueNotifier(
      AttendanceViewData(
        completedCount: _alreadyAttended ? _round : _round - 1,
        checking: !_alreadyAttended,
        todayCompleted: _alreadyAttended,
      ),
    );
    Timer? arrival;
    var rewardOpen = false;
    if (!_alreadyAttended) {
      arrival = Timer(const Duration(milliseconds: 650), () {
        snapshot.value = AttendanceViewData(
          completedCount: _round,
          todayCompleted: true,
          newReward: launchAttendanceRewards[_round - 1],
        );
      });
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ValueListenableBuilder(
        valueListenable: snapshot,
        builder: (_, data, _) => AttendanceEventDialog(
          data: data,
          preview: true,
          onClose: () => Navigator.of(dialogContext).pop(),
          onReward: () async {
            if (rewardOpen || data.newReward == null) return;
            rewardOpen = true;
            await showDialog<void>(
              context: dialogContext,
              builder: (_) => TicketRewardDialog(
                awardedTickets: data.newReward,
                rewardHeading: '${data.completedCount}회차 출석 보상 도착!',
                rewardMessage: data.complete
                    ? '누적 7회 출석으로 총 20장을 모두 받았어요.'
                    : '오늘의 출석이 쌓였어요. 다음에도 이어서 만나요.',
              ),
            );
            rewardOpen = false;
            if (!dialogContext.mounted) return;
            snapshot.value = AttendanceViewData(
              completedCount: data.completedCount,
              todayCompleted: true,
            );
          },
        ),
      ),
    );
    arrival?.cancel();
    snapshot.dispose();
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F7F3),
    appBar: AppBar(
      title: const Text('출석 이벤트 미리보기'),
      backgroundColor: const Color(0xFFF3F7F3),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 64,
            color: AttendanceEventDialog.green,
          ),
          const SizedBox(height: 20),
          const Text(
            '7번의 출석, 20장의 선물',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const Text(
            '디자인 미리보기 · 실제 뽑기권은 지급되지 않습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7A70)),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _round,
            decoration: const InputDecoration(
              labelText: '확인할 누적 출석 회차',
              border: OutlineInputBorder(),
            ),
            items: [
              for (var i = 1; i <= 7; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text('$i회차 · 뽑기권 ${launchAttendanceRewards[i - 1]}장'),
                ),
            ],
            onChanged: _open
                ? null
                : (value) => setState(() => _round = value!),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('오늘 이미 출석한 상태'),
            subtitle: const Text('진행도를 유지하고 보상을 다시 주지 않는 화면'),
            value: _alreadyAttended,
            onChanged: _open
                ? null
                : (value) => setState(() => _alreadyAttended = value),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _open ? null : _play,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('앱 진입 연출 보기'),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '1 → 1 → 2 → 2 → 3 → 3 → 8장\n\n신규 참가 기간은 30일이며, 참가 후 완료 기한은 없습니다. 며칠 쉬어도 초기화 없이 다음 회차로 이어집니다.',
            style: TextStyle(color: Color(0xFF6B7A70), height: 1.7),
          ),
        ],
      ),
    ),
  );
}
