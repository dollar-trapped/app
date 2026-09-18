import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_exception.dart';
import '../../shared/data/dollar_repository.dart';
import '../widgets/auth_button.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({
    super.key,
    required this.repository,
    this.email = '',
  });
  final DollarRepository repository;
  final String email;
  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  int _step = 0;
  bool _busy = false;
  String? _token, _error;
  DateTime? _resendAt;
  Timer? _timer;
  int get _seconds => _resendAt == null
      ? 0
      : (_resendAt!.difference(DateTime.now()).inMilliseconds / 1000)
            .ceil()
            .clamp(0, 60);
  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in [_email, _code, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.userMessage
              : '요청을 처리하지 못했어요. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      setState(() => _error = '이메일 주소를 확인해 주세요.');
      return;
    }
    await widget.repository.requestPasswordReset(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _step = 1;
      _token = null;
      _code.clear();
      _resendAt = DateTime.now().add(const Duration(seconds: 60));
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {});
      if (_seconds == 0) timer.cancel();
    });
  });
  Future<void> _next() async {
    if (_step == 0) {
      await _send();
      return;
    }
    await _run(() async {
      if (_step == 1) {
        if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
          setState(() => _error = '인증 코드 6자리를 입력해 주세요.');
          return;
        }
        final token = await widget.repository.verifyPasswordReset(
          _email.text.trim(),
          _code.text.trim(),
        );
        if (!mounted) return;
        setState(() {
          _token = token;
          _step = 2;
        });
      } else {
        if (_password.text.isEmpty || _password.text != _confirm.text) {
          setState(() => _error = '새 비밀번호와 확인 입력을 일치시켜 주세요.');
          return;
        }
        await widget.repository.resetPassword(_token!, _password.text);
        if (!mounted) return;
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('비밀번호 재설정')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                '가입한 이메일을 입력해 주세요.',
                '인증 코드를 입력해 주세요.',
                '새 비밀번호를 입력해 주세요.',
              ][_step],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _email,
              enabled: _step == 0 && !_busy,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            if (_step == 1) ...[
              const SizedBox(height: 16),
              const Text('등록된 계정이 있다면 인증 코드가 발송됩니다. 이메일을 확인해 주세요.'),
              const SizedBox(height: 8),
              const Text('인증 코드는 발송 후 5분 동안 유효합니다. 재전송은 60초 후 가능합니다.'),
              TextField(
                controller: _code,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: '인증 코드'),
              ),
              TextButton(
                onPressed: _busy || _seconds > 0 ? null : _send,
                child: Text(_seconds > 0 ? '재전송 ($_seconds초)' : '인증 코드 재전송'),
              ),
            ],
            if (_step == 2) ...[
              const SizedBox(height: 16),
              const Text('코드 확인 후 10분 이내에 비밀번호를 변경해 주세요.'),
              TextField(
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(labelText: '새 비밀번호'),
              ),
              TextField(
                controller: _confirm,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
              ),
              const SizedBox(height: 12),
              const Text(
                '변경하면 현재 기기를 포함한 모든 기기에서 로그아웃됩니다. 새 비밀번호로 다시 로그인해 주세요.',
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB3261E)),
                ),
              ),
            const SizedBox(height: 24),
            AuthButton(
              label: _busy
                  ? '처리 중…'
                  : ['인증 코드 발송', '인증 코드 확인', '비밀번호 변경'][_step],
              color: const Color(0xFF008A29),
              foreground: Colors.white,
              onPressed: _busy ? null : _next,
            ),
            if (_step > 0)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _step = 0;
                        _token = null;
                        _error = null;
                        _password.clear();
                        _confirm.clear();
                      }),
                child: const Text('처음부터 다시 진행'),
              ),
          ],
        ),
      ),
    ),
  );
}
