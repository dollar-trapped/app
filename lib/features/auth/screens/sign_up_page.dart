import '../widgets/auth_scaffold.dart';
import '../widgets/auth_button.dart';
import '../../legal/consent_versions.dart';
import '../../legal/legal_documents.dart';
import 'package:dollar_trapped/features/auth/widgets/sign_up_field.dart';
import 'package:dollar_trapped/features/auth/widgets/agreement_row.dart';
import 'package:flutter/material.dart';

import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';
import 'package:dollar_trapped/features/shared/data/dollar_repository.dart';
import 'package:dollar_trapped/core/network/api_exception.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.repository});

  final DollarRepository repository;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  static const _muted = Color(0xFF667069);
  static const _surface = Color(0xFFF5F7F5);
  static const _action = Color(0xFF008A29);
  static const _minimumPasswordLength = 10;

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

  bool _verificationStep = false;
  bool _showValidation = false;
  bool _showPassword = false;

  String? get _emailError =>
      RegExp(
        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
      ).hasMatch(_emailController.text.trim())
      ? null
      : '올바른 이메일 주소를 입력해 주세요.';
  String? get _passwordError =>
      _passwordController.text.length >= _minimumPasswordLength
      ? null
      : '비밀번호는 $_minimumPasswordLength자 이상 입력해 주세요. (현재 ${_passwordController.text.length}자)';
  String? get _nicknameError =>
      _nicknameController.text.trim().isEmpty ? '닉네임을 입력해 주세요.' : null;

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_isSubmitting) return;
    setState(() => _showValidation = true);
    final error =
        _emailError ??
        _passwordError ??
        _nicknameError ??
        (_verificationToken == null ? '이메일 인증을 완료해 주세요.' : null) ??
        (!_agreedToTerms || !_agreedToPrivacy ? '필수 약관에 모두 동의해 주세요.' : null);
    if (error != null) {
      _showError(error);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final versions = await widget.repository.getTermsVersions();
      if (versions['termsVersion'] != bundledTermsVersion ||
          versions['privacyVersion'] != bundledPrivacyVersion) {
        if (mounted) _showError('약관이 변경되었습니다. 앱을 최신 버전으로 업데이트해 주세요.');
        return;
      }
      await widget.repository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nickname: _nicknameController.text.trim(),
        verificationToken: _verificationToken!,
        termsVersion: bundledTermsVersion,
        privacyVersion: bundledPrivacyVersion,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) =>
              UsdKrwPage(repository: widget.repository, checkConsent: true),
        ),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (mounted) {
        _showError(_signUpErrorMessage(error));
      }
    } catch (_) {
      if (mounted) {
        _showError('가입 요청을 처리하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _requestVerification() async {
    final email = _emailController.text.trim();
    if (_isRequestingVerification) return;
    if (_emailError != null) {
      _showError(_emailError!);
      return;
    }
    setState(() {
      _isRequestingVerification = true;
      _errorMessage = null;
      _verificationMessage = null;
      _verificationToken = null;
    });
    try {
      await widget.repository.requestEmailVerification(email: email);
      if (mounted && _emailController.text.trim() == email) {
        setState(() => _verificationMessage = '인증 코드를 이메일로 보냈어요.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = error.statusCode == 409
              ? '이미 가입된 이메일입니다. 로그인해 주세요.'
              : error.userMessage,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _errorMessage = '인증 메일을 보내지 못했어요.');
    } finally {
      if (mounted) setState(() => _isRequestingVerification = false);
    }
  }

  Future<void> _verifyEmail() async {
    if (_isVerifyingEmail) return;
    if (_verificationCodeController.text.trim().isEmpty) {
      _showError('메일로 받은 인증 코드를 입력해 주세요.');
      return;
    }
    final email = _emailController.text.trim();
    setState(() {
      _isVerifyingEmail = true;
      _errorMessage = null;
    });
    try {
      final token = await widget.repository.verifyEmail(
        email: email,
        code: _verificationCodeController.text.trim(),
      );
      if (mounted && _emailController.text.trim() == email) {
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

  String _signUpErrorMessage(ApiException error) {
    if (error.details.any(
      (detail) => detail.reason == 'TERMS_VERSION_MISMATCH',
    )) {
      return '약관이 변경되었습니다. 앱을 최신 버전으로 업데이트해 주세요.';
    }
    if (error.statusCode == 409) {
      return '이미 가입된 이메일입니다. 로그인해 주세요.';
    }
    const invalidTokenCodes = {
      'INVALID_VERIFICATION_TOKEN',
      'VERIFICATION_TOKEN_EXPIRED',
      'EMAIL_VERIFICATION_EXPIRED',
    };
    return invalidTokenCodes.contains(error.code)
        ? '이메일 인증이 만료되었거나 유효하지 않습니다. 인증 메일을 다시 요청해 주세요.'
        : error.userMessage;
  }

  bool get _busy =>
      _isSubmitting || _isRequestingVerification || _isVerifyingEmail;

  void _backToDetails() {
    if (_busy) return;
    setState(() {
      _verificationStep = false;
      _errorMessage = null;
    });
  }

  Future<void> _continueToVerification() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _showValidation = true);
    final error =
        _emailError ??
        _passwordError ??
        _nicknameError ??
        (!_agreedToTerms || !_agreedToPrivacy ? '필수 약관에 모두 동의해 주세요.' : null);
    if (error != null) {
      _showError(error);
      return;
    }
    setState(() {
      _verificationStep = true;
      _errorMessage = null;
    });
    if (_verificationToken == null) await _requestVerification();
  }

  Future<void> _completeVerification() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_verificationToken == null) await _verifyEmail();
    if (!mounted || _verificationToken == null) return;
    await _signUp();
  }

  Widget _actionButton(String label, VoidCallback action) => AuthButton(
    label: label,
    color: _action,
    foreground: Colors.white,
    onPressed:
        _busy ||
            (!_verificationStep &&
                _emailController.text.isEmpty &&
                _passwordController.text.isEmpty &&
                _nicknameController.text.isEmpty)
        ? null
        : action,
  );

  List<Widget> get _errors => [
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
  ];

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_verificationStep && !_busy,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _verificationStep) _backToDetails();
    },
    child: AuthScaffold(
      title: _verificationStep ? '이메일 인증' : '회원가입',
      onBack: _busy
          ? null
          : () {
              if (_verificationStep) {
                _backToDetails();
              } else {
                Navigator.of(context).maybePop();
              }
            },
      children: _verificationStep ? _verificationContent : _detailsContent,
    ),
  );

  List<Widget> get _detailsContent => [
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
      style: TextStyle(color: _muted, fontSize: 15, height: 1.6),
    ),
    const SizedBox(height: 20),
    ..._errors,
    SignUpField(
      controller: _emailController,
      label: '이메일',
      hintText: '이메일 주소 입력',
      helperText: '로그인과 계정 복구에 사용해요.',
      errorText: _showValidation ? _emailError : null,
      keyboardType: TextInputType.emailAddress,
      onChanged: (_) => setState(() {
        _verificationToken = null;
        _verificationMessage = null;
        _verificationCodeController.clear();
      }),
    ),
    const SizedBox(height: 16),
    SignUpField(
      controller: _passwordController,
      label: '비밀번호',
      hintText: '비밀번호 입력',
      helperText: '비밀번호는 $_minimumPasswordLength자 이상 입력해 주세요.',
      obscureText: !_showPassword,
      errorText: _showValidation || _passwordController.text.isNotEmpty
          ? _passwordError
          : null,
      suffixIcon: TextButton(
        onPressed: () => setState(() => _showPassword = !_showPassword),
        style: TextButton.styleFrom(
          foregroundColor: _muted,
          minimumSize: const Size(44, 44),
        ),
        child: Text(
          _showPassword ? '숨기기' : '보기',
          semanticsLabel: _showPassword ? '비밀번호 숨기기' : '비밀번호 보기',
          style: const TextStyle(fontSize: 13, height: 20 / 13),
        ),
      ),
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 16),
    SignUpField(
      controller: _nicknameController,
      label: '닉네임',
      hintText: '닉네임 입력',
      helperText: '채팅에 표시되는 이름이에요.',
      errorText: _showValidation ? _nicknameError : null,
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 20),
    AgreementRow(
      label: '[필수] 이용약관 동의',
      onView: () => openTerms(context),
      value: _agreedToTerms,
      onChanged: (value) => setState(() => _agreedToTerms = value),
    ),
    const SizedBox(height: 4),
    AgreementRow(
      label: '[필수] 개인정보 수집·이용 동의',
      onView: () => openPrivacyPolicy(context),
      value: _agreedToPrivacy,
      onChanged: (value) => setState(() => _agreedToPrivacy = value),
    ),
    const SizedBox(height: 24),
    const Spacer(),
    _actionButton('가입하고 이메일 인증', _continueToVerification),
    const SizedBox(height: 8),
    const Text(
      '이메일 인증 후 채팅에 참여할 수 있어요.',
      style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
    ),
    const SizedBox(height: 24),
  ];

  List<Widget> get _verificationContent => [
    const SizedBox(height: 48),
    Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
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
      '아래 주소로 받은 인증 코드를 입력해주세요.\n인증이 완료되면 회원가입을 마무리합니다.',
      style: TextStyle(color: _muted, fontSize: 15, height: 1.6),
    ),
    const SizedBox(height: 24),
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _emailController.text.trim(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '메일이 없다면 스팸함도 확인해주세요.',
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    SignUpField(
      controller: _verificationCodeController,
      label: '인증 코드',
      hintText: '메일로 받은 인증 코드 입력',
      helperText: _verificationMessage ?? '인증 메일의 코드를 입력해주세요.',
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() => _verificationToken = null),
    ),
    TextButton(
      onPressed: _busy ? null : _requestVerification,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: _action,
        minimumSize: const Size(0, 44),
        alignment: Alignment.centerLeft,
      ),
      child: Text(
        _isRequestingVerification ? '인증 메일 보내는 중...' : '인증 메일 다시 보내기',
      ),
    ),
    ..._errors,
    const SizedBox(height: 24),
    const Spacer(),
    _actionButton(
      _isSubmitting
          ? '가입 중...'
          : _isVerifyingEmail
          ? '확인 중...'
          : '인증하고 가입 완료',
      _completeVerification,
    ),
    const SizedBox(height: 12),
    const Text(
      '인증 확인 후 USD방으로 이동해요.',
      style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
    ),
    const SizedBox(height: 24),
  ];
}
