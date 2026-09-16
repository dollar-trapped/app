import 'package:flutter/material.dart';

import '../../../home/presentation/pages/usd_krw_page.dart';
import '../../../shared/data/dollar_repository.dart';
import '../../../../core/network/api_exception.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.repository});

  final DollarRepository repository;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _surface = Color(0xFFF5F7F5);
  static const _action = Color(0xFF008A29);

  final _emailController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isSubmitting = false;
  bool _isRequestingVerification = false;
  bool _isVerifyingEmail = false;
  String? _verificationToken;
  String? _verificationMessage;
  String? _errorMessage;

  bool get _canSubmit =>
      _emailController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _nicknameController.text.isNotEmpty &&
      _agreedToTerms &&
      _agreedToPrivacy;

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_canSubmit || _isSubmitting || _verificationToken == null) {
      if (_verificationToken == null) {
        setState(() => _errorMessage = '이메일 인증을 완료해 주세요.');
      }
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.repository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
        verificationToken: _verificationToken!,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => UsdKrwPage(repository: widget.repository),
        ),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = error.statusCode == 409
              ? '이미 가입된 이메일입니다. 로그인해 주세요.'
              : error.message,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = '가입 요청을 처리하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _requestVerification() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _isRequestingVerification) return;
    setState(() {
      _isRequestingVerification = true;
      _errorMessage = null;
      _verificationMessage = null;
      _verificationToken = null;
    });
    try {
      await widget.repository.requestEmailVerification(email: email);
      if (mounted) setState(() => _verificationMessage = '인증 코드를 이메일로 보냈어요.');
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = error.statusCode == 409
              ? '이미 가입된 이메일입니다. 로그인해 주세요.'
              : error.message,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '인증 메일을 보내지 못했어요.');
    } finally {
      if (mounted) setState(() => _isRequestingVerification = false);
    }
  }

  Future<void> _verifyEmail() async {
    if (_verificationCodeController.text.trim().isEmpty || _isVerifyingEmail) {
      return;
    }
    setState(() {
      _isVerifyingEmail = true;
      _errorMessage = null;
    });
    try {
      final token = await widget.repository.verifyEmail(
        email: _emailController.text.trim(),
        code: _verificationCodeController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _verificationToken = token;
          _verificationMessage = '이메일 인증이 완료되었습니다.';
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _verificationErrorMessage(error));
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '인증 코드를 확인하지 못했어요.');
    } finally {
      if (mounted) setState(() => _isVerifyingEmail = false);
    }
  }

  String _verificationErrorMessage(ApiException error) {
    const expiredCodes = {
      'VERIFICATION_EXPIRED',
      'EMAIL_VERIFICATION_EXPIRED',
      'VERIFICATION_TOKEN_EXPIRED',
    };
    return expiredCodes.contains(error.code)
        ? '인증 코드가 만료되었습니다. 인증 메일을 다시 요청해 주세요.'
        : '인증 코드가 올바르지 않습니다.';
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
                    '회원가입',
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            const Text(
                              '달러방에서 만나요.',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 32 / 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '계정 정보와 채팅 이름만 입력해주세요.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_errorMessage != null) ...[
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFB3261E),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            _SignUpField(
                              controller: _emailController,
                              label: '이메일',
                              hintText: '이메일 주소 입력',
                              helperText: '로그인과 계정 복구에 사용해요.',
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) => setState(() {
                                _verificationToken = null;
                                _verificationMessage = null;
                              }),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed:
                                    _emailController.text.trim().isEmpty ||
                                        _isRequestingVerification
                                    ? null
                                    : _requestVerification,
                                child: Text(
                                  _isRequestingVerification
                                      ? '인증 메일 보내는 중...'
                                      : '인증 메일 받기',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _verificationCodeController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {
                                      _verificationToken = null;
                                    }),
                                    decoration: const InputDecoration(
                                      labelText: '인증 코드',
                                      hintText: '메일로 받은 인증 코드 입력',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: _isVerifyingEmail
                                        ? null
                                        : _verifyEmail,
                                    child: Text(
                                      _isVerifyingEmail ? '확인 중...' : '인증 확인',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_verificationMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _verificationMessage!,
                                style: TextStyle(
                                  color: _verificationToken == null
                                      ? _muted
                                      : _action,
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            _SignUpField(
                              controller: _passwordController,
                              label: '비밀번호',
                              hintText: '비밀번호 입력',
                              helperText: '로그인에 사용할 비밀번호예요.',
                              obscureText: true,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),
                            _SignUpField(
                              controller: _nicknameController,
                              label: '닉네임',
                              hintText: '닉네임 입력',
                              helperText: '채팅에 표시되는 이름이에요.',
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 20),
                            _AgreementRow(
                              label: '[필수] 이용약관 동의',
                              value: _agreedToTerms,
                              onChanged: (value) =>
                                  setState(() => _agreedToTerms = value),
                            ),
                            const SizedBox(height: 4),
                            _AgreementRow(
                              label: '[필수] 개인정보 수집·이용 동의',
                              value: _agreedToPrivacy,
                              onChanged: (value) =>
                                  setState(() => _agreedToPrivacy = value),
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _canSubmit && !_isSubmitting
                                    ? _signUp
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: _action,
                                  disabledBackgroundColor: _surface,
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: _muted,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.5,
                                  ),
                                ),
                                child: Text(_isSubmitting ? '가입 중...' : '가입하기'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '가입이 완료되면 바로 USD방을 이용할 수 있어요.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }
}

class _SignUpField extends StatelessWidget {
  const _SignUpField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.helperText,
    required this.onChanged,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String helperText;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 20 / 13,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 15, height: 1.6),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF667069),
                fontSize: 15,
                height: 1.6,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE1E6E2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF008A29)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          helperText,
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

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
              activeColor: const Color(0xFF008A29),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: Color(0xFFE1E6E2)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 20 / 13,
              ),
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 44),
              padding: EdgeInsets.zero,
              foregroundColor: const Color(0xFF667069),
            ),
            child: const Text(
              '보기',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
