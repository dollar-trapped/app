import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Shared Figma auth shell. The OS owns safe-area sizes; short screens scroll.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.onBack,
  });
  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.apply(
        fontFamily: 'Noto Sans KR',
        bodyColor: AppColors.of(context).ink,
        displayColor: AppColors.of(context).ink,
      ),
    ),
    child: Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: AppColors.of(context).ink,
                      ),
                      child: const Text(
                        '‹',
                        semanticsLabel: '뒤로',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 32 / 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
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
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
