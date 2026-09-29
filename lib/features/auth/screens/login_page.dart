import '../../../core/moderation/moderation_dialog.dart';
import '../../../core/moderation/moderation_status.dart';
import 'password_reset_page.dart';
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
      final session = await widget.repository.logIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final acknowledged = <String>{};
      for (final notice in session.user.moderation.notices) {
        if (!notice.active) continue;
        if (!mounted) return;
        await showModerationDialog(context, notice, userId: session.user.id);
        acknowledged.add(notice.id);
        if (notice.suspended) {
          await tokenStore?.clear();
          return;
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => UsdKrwPage(
            checkConsent: true,
            repository: widget.repository,
            acknowledgedNotices: acknowledged,
          ),
        ),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.userMessage);
        final notice = ModerationNotice.fromError(error);
        if (notice != null) await showModerationDialog(context, notice);
      }
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '다시 오셨네요.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '계정 정보로 로그인해주세요.',
                      style: TextStyle(color: _muted),
                    ),
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
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              final changed = await Navigator.of(context)
                                  .push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => PasswordResetPage(
                                        repository: widget.repository,
                                        email: _emailController.text.trim(),
                                      ),
                                    ),
                                  );
                              if (!context.mounted || changed != true) return;
                              _passwordController.clear();
                              setState(() => _errorMessage = null);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '비밀번호를 변경했어요. 새 비밀번호로 로그인해 주세요.',
                                  ),
                                ),
                              );
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: _muted,
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('비밀번호 재설정'),
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
          ],
        ),
      ),
    );
  }
}
