import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '달러물림',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00B235)),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const AuthPage(),
    );
  }
}

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
                  const _AuthButton(
                    label: '로그인',
                    color: _action,
                    foreground: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const _AuthButton(
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

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.color,
    required this.foreground,
    this.borderColor,
  });

  final String label;
  final Color color;
  final Color foreground;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: color,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor == null
                ? BorderSide.none
                : BorderSide(color: borderColor!),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
