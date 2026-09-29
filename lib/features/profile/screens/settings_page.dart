import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) => ProfileLayout(
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
                        color: const Color(0xFFF5F7F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('로그인 계정', style: ProfileStyle.caption),
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
                    const Text('이용 관리', style: ProfileStyle.caption),
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
                    const Text('안내', style: ProfileStyle.caption),
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
                        style: const TextStyle(color: Color(0xFFB42318)),
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
                          foregroundColor: const Color(0xFFB42318),
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
                    const Text('달러물림 · v1.0.0', style: ProfileStyle.caption),
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
