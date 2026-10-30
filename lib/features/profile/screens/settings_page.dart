import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_controller.dart';
import '../../legal/legal_documents.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/realtime/dollar_socket.dart';
import '../../auth/screens/auth_page.dart';
import '../../shared/data/dollar_repository.dart';
import '../widgets/profile_layout.dart';
import 'blocked_users_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.repository,
    this.email,
    this.socket,
  });
  final DollarRepository repository;
  final String? email;
  final DollarSocket? socket;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDeleting = false;
  String? _errorMessage;
  Future<void> _setDarkMode(ThemeController theme, bool enabled) async {
    try {
      await theme.setDarkMode(enabled);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('화면 설정을 저장하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _logOut() async {
    await widget.repository.logOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴하시겠어요?'),
        content: const Text('탈퇴하면 계정과 로그인 정보가 삭제되며 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('계속'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final passwordController = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호를 입력해 주세요'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: '비밀번호'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text('탈퇴하기'),
          ),
        ],
      ),
    );
    if (!mounted || password == null || password.isEmpty || _isDeleting) return;

    setState(() => _isDeleting = true);
    try {
      await widget.repository.deleteAccount(password);
      if (!mounted) return;
      await widget.socket?.disconnect();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthPage()),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.actionableUserMessage);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '회원 탈퇴를 완료하지 못했습니다.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController?>();
    return ProfileLayout(
      title: '설정',
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '로그인 계정',
                              style: AppColors.of(context).caption,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.email ?? '계정 정보를 불러오지 못했어요.',
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('화면 설정', style: AppColors.of(context).caption),
                      const SizedBox(height: 4),
                      SwitchListTile.adaptive(
                        key: const Key('dark-mode-switch'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        title: const Text(
                          '다크모드',
                          style: TextStyle(fontSize: 15),
                        ),
                        value:
                            theme?.isDark ??
                            Theme.of(context).brightness == Brightness.dark,
                        onChanged: theme == null || theme.saving
                            ? null
                            : (enabled) => _setDarkMode(theme, enabled),
                      ),
                      const SizedBox(height: 24),
                      Text('이용 관리', style: AppColors.of(context).caption),
                      const SizedBox(height: 4),
                      AccountMenuRow(
                        label: '차단 관리',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                BlockedUsersPage(repository: widget.repository),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('안내', style: AppColors.of(context).caption),
                      const SizedBox(height: 4),
                      AccountMenuRow(
                        label: '이용약관',
                        onTap: () => openTerms(context),
                      ),
                      const SizedBox(height: 4),
                      AccountMenuRow(
                        label: '개인정보 처리방침',
                        onTap: () => openPrivacyPolicy(context),
                      ),
                      if (_errorMessage?.isNotEmpty == true)
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.of(context).error),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AccountMenuRow(label: '로그아웃', onTap: _logOut),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _isDeleting ? null : _deleteAccount,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            foregroundColor: AppColors.of(context).error,
                            textStyle: const TextStyle(
                              fontFamily: 'Noto Sans KR',
                              fontSize: 13,
                              height: 20 / 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: Text(_isDeleting ? '탈퇴 처리 중...' : '회원 탈퇴'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '달러물림 · v1.0.0',
                        style: AppColors.of(context).caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
