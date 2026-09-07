import 'package:flutter/material.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _nicknameController = TextEditingController(text: '초록달러');
  final _holdingController = TextEditingController(text: '2,000');
  final _averagePriceController = TextEditingController(text: '1,279.55');

  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _action = Color(0xFF008A29);
  static const _currentRate = 1346.09;

  @override
  void dispose() {
    _nicknameController.dispose();
    _holdingController.dispose();
    _averagePriceController.dispose();
    super.dispose();
  }

  double? _parseNumber(String value) {
    return double.tryParse(value.replaceAll(',', '').trim());
  }

  String get _positionPreview {
    final nickname = _nicknameController.text.trim().isEmpty
        ? '닉네임'
        : _nicknameController.text.trim();
    final holding = _holdingController.text.trim().isEmpty
        ? '0'
        : _holdingController.text.trim();
    final averagePrice = _parseNumber(_averagePriceController.text);
    final profitRate = averagePrice == null || averagePrice <= 0
        ? null
        : ((_currentRate - averagePrice) / averagePrice) * 100;
    final rateText = profitRate == null
        ? ''
        : ' · ${profitRate >= 0 ? '+' : ''}${profitRate.toStringAsFixed(1)}%';

    return '$nickname  \$$holding$rateText';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 44,
                    child: TextButton(
                      onPressed: widget.onBack,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: _ink,
                      ),
                      child: const Text(
                        '‹',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    '마이페이지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'dollar@example.com',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 20 / 13,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '✓ 이메일 인증 완료',
                            style: TextStyle(
                              color: _action,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _InfoField(
                      label: '닉네임',
                      controller: _nicknameController,
                      helper: '채팅에 표시되는 이름이에요.',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '내 달러 포지션 · 선택',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoField(
                            label: '보유량 (USD)',
                            controller: _holdingController,
                            helper: '보유한 달러 금액',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _InfoField(
                            label: '평균 매수가 (원)',
                            controller: _averagePriceController,
                            helper: '1달러당 매수 가격',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '수익률은 평균 매수가와 현재 환율로 계산해요.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '채팅에는 이렇게 보여요',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _positionPreview,
                            style: TextStyle(
                              color: _action,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 20 / 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: _action,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                        child: const Text('변경사항 저장'),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: _muted,
                      ),
                      child: const Text(
                        '로그아웃',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 20 / 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.controller,
    required this.helper,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String helper;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF151916),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 20 / 13,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            textAlignVertical: TextAlignVertical.center,
            cursorHeight: 24,
            style: const TextStyle(
              color: Color(0xFF151916),
              fontSize: 15,
              height: 24 / 15,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              constraints: const BoxConstraints.tightFor(height: 52),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFE1E6E2)),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _MyPageState._action),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helper,
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
