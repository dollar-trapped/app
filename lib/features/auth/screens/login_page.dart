import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dollar_trapped/core/auth/token_store.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';
import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';
import 'package:dollar_trapped/features/shared/data/dollar_repository.dart';
import 'package:dollar_trapped/features/auth/widgets/auth_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.repository});

  final DollarRepository repository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _muted = Color(0xFF667069);
  static const _action = Color(0xFF008A29);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _rememberLogin = false;
  String? _errorMessage;

  bool get _canSubmit =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    if (!_canSubmit || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final tokenStore = context.read<TokenStore?>();
      if (tokenStore is RememberingTokenStore) {
        tokenStore.setRememberSession(_rememberLogin);
      }
      await widget.repository.logIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => UsdKrwPage(repository: widget.repository),
        ),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.userMessage);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '로그인 요청을 처리하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '다시 오셨네요.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('계정 정보로 로그인해주세요.', style: TextStyle(color: _muted)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: '이메일'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                onChanged: (_) => setState(() {}),
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호'),
              ),
              CheckboxListTile(
                value: _rememberLogin,
                onChanged: (value) {
                  setState(() => _rememberLogin = value ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('로그인 유지하기'),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFB3261E)),
                ),
              ],
              const Spacer(),
              AuthButton(
                label: _isSubmitting ? '로그인 중...' : '로그인',
                color: _action,
                foreground: Colors.white,
                onPressed: _canSubmit && !_isSubmitting ? _logIn : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
