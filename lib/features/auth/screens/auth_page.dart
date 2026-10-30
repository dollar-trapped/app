import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../cosmetics/preview/cosmetic_expansion_preview_page.dart';
import '../../gacha/preview/gacha_presentation_preview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'package:dollar_trapped/features/home/screens/usd_krw_page.dart';
import 'package:dollar_trapped/features/shared/data/dollar_repository.dart';
import 'package:dollar_trapped/features/shared/data/mock_dollar_repository.dart';
import 'package:dollar_trapped/features/auth/screens/login_page.dart';
import 'package:dollar_trapped/features/auth/screens/sign_up_page.dart';
import 'package:dollar_trapped/features/auth/widgets/auth_button.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  static const _brand = Color(0xFF00B235);

  @override
  Widget build(BuildContext context) {
    final repository =
        context.read<DollarRepository?>() ?? MockDollarRepository();
    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
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
                        colorFilter: ColorFilter.mode(
                          AppColors.of(context).ink,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(width: 32, height: 4, color: _brand),
                    const SizedBox(height: 24),
                    Text(
                      '물려도, 혼자는 아니니까.',
                      style: TextStyle(
                        color: AppColors.of(context).muted,
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
                    AuthButton(
                      label: '로그인',
                      color: AppColors.of(context).action,
                      foreground: AppColors.of(context).onAction,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LoginPage(repository: repository),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    AuthButton(
                      label: '회원가입',
                      color: AppColors.of(context).background,
                      foreground: AppColors.of(context).ink,
                      borderColor: AppColors.of(context).line,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SignUpPage(repository: repository),
                          ),
                        );
                      },
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => UsdKrwPage(repository: repository),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: AppColors.of(context).muted,
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
                    if (kDebugMode &&
                        const bool.fromEnvironment('COSMETIC_PREVIEW_BUILD'))
                      TextButton(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                const CosmeticExpansionPreviewPage(),
                          ),
                        ),
                        child: const Text('신규 30종 개발 미리보기'),
                      ),
                    if (kDebugMode &&
                        const bool.fromEnvironment('COSMETIC_PREVIEW_BUILD'))
                      TextButton(
                        onPressed: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const GachaPresentationPreview(),
                          ),
                        ),
                        child: const Text('뽑기 연출 미리보기'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
