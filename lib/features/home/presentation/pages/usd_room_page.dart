import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UsdRoomPage extends StatefulWidget {
  const UsdRoomPage({super.key, required this.onRateBarTap});

  final VoidCallback onRateBarTap;

  @override
  State<UsdRoomPage> createState() => _UsdRoomPageState();
}

class _UsdRoomPageState extends State<UsdRoomPage> {
  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _surface = Color(0xFFF5F7F5);
  static const _line = Color(0xFFE1E6E2);
  static const _action = Color(0xFF008A29);
  static const _negative = Color(0xFF2463B5);

  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 85,
                    height: 32,
                    child: SvgPicture.asset(
                      'assets/images/dollar_wordmark.svg',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Text(
                        'USD방',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 32 / 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '● 실시간 채팅',
                        style: TextStyle(
                          color: _action,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: const [
                  Text(
                    '9월 6일 일요일',
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
                  ),
                  SizedBox(height: 24),
                  _ChatMessage(
                    nickname: '김달러',
                    holding: r'$2,300',
                    profit: '+3.2%',
                    message: '오늘도 달러방 출석합니다.\n다들 환율 보고 계신가요?',
                    time: '오전 9:18',
                  ),
                  SizedBox(height: 24),
                  _ChatMessage(
                    nickname: '이달러',
                    holding: r'$5,200',
                    profit: '−32.0%',
                    profitColor: _negative,
                    message: '이 시발 새끼들아 내 돈 돌려내 개 좇 같 네',
                    time: '오전 9:19',
                  ),
                  SizedBox(height: 24),
                  _ChatMessage(
                    nickname: '초록달러 (나)',
                    holding: r'$2,000',
                    profit: '+5.2%',
                    message: '개병신 새끼들 ㅋㅋㅋ',
                    time: '오전 9:20',
                    isMine: true,
                  ),
                ],
              ),
            ),
            InkWell(onTap: widget.onRateBarTap, child: const _RateBar()),
            Container(
              height: 76,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        hintStyle: const TextStyle(
                          color: _muted,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        filled: true,
                        fillColor: _surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _messageController.text.isEmpty
                          ? null
                          : () => _messageController.clear(),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        backgroundColor: _action,
                        disabledBackgroundColor: _line,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: _muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '↑',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  const _ChatMessage({
    required this.nickname,
    required this.holding,
    required this.profit,
    required this.message,
    required this.time,
    this.profitColor = const Color(0xFF008A29),
    this.isMine = false,
  });

  final String nickname;
  final String holding;
  final String profit;
  final String message;
  final String time;
  final Color profitColor;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final alignment = isMine
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nickname,
              style: const TextStyle(
                color: Color(0xFF151916),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 20 / 13,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              holding,
              style: const TextStyle(
                color: Color(0xFF667069),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              profit,
              style: TextStyle(color: profitColor, fontSize: 12, height: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 304),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine ? const Color(0xFFEAF7EE) : const Color(0xFFF5F7F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFF151916),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: const TextStyle(
            color: Color(0xFF667069),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _RateBar extends StatelessWidget {
  const _RateBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE1E6E2))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'USD/KRW',
                    style: TextStyle(
                      color: Color(0xFF667069),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 20 / 13,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '1,346.09원',
                    style: TextStyle(
                      color: Color(0xFF151916),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                '▼ 8.31 (−0.61%) · 전일 대비',
                style: TextStyle(
                  color: Color(0xFF2463B5),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
          Text(
            '›',
            style: TextStyle(
              color: Color(0xFF667069),
              fontSize: 32,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
