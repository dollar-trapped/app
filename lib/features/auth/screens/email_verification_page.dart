import 'package:flutter/material.dart';

import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';

class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key, required this.email});

  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _soft = Color(0xFFEAF7EE);
  static const _action = Color(0xFF008A29);

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                      onPressed: () => Navigator.of(context).pop(),
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
                    '이메일 인증',
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _soft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '@',
                        style: TextStyle(
                          color: _action,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 46 / 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '메일함을 확인해주세요.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 32 / 24,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '아래 주소로 인증 링크를 보냈어요.\n메일의 링크를 눌러 인증을 완료해주세요.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '메일이 없다면 스팸함도 확인해주세요.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('인증 메일을 다시 보냈어요.')),
                        );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        foregroundColor: _action,
                      ),
                      child: const Text(
                        '인증 메일 다시 보내기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 20 / 13,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const UsdKrwPage(),
                          ),
                        ),
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
                        child: const Text('인증 완료했어요'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '인증 확인 후 USD방으로 이동해요.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
