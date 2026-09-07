import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/auth_button.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _action = Color(0xFF008A29);
  static const _brand = Color(0xFF00B235);
  static const _line = Color(0xFFE1E6E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Column(
          children: [
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.only(top: 96),
              child: Column(
                children: [
                  SizedBox(
                    width: 235,
                    height: 89,
                    child: SvgPicture.asset(
                      'assets/images/dollar_wordmark.svg',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(width: 32, height: 4, color: _brand),
                  const SizedBox(height: 24),
                  const Text(
                    '물려도, 혼자는 아니니까.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const AuthButton(
                    label: '로그인',
                    color: _action,
                    foreground: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const AuthButton(
                    label: '회원가입',
                    color: Colors.white,
                    foreground: _ink,
                    borderColor: _line,
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: _muted,
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: const Text(
                      '비회원으로 둘러보기',
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
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }
}
