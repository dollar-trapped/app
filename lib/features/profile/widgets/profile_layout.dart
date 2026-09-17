import 'package:flutter/material.dart';

abstract final class ProfileStyle {
  static const ink = Color(0xFF151916);
  static const muted = Color(0xFF667069);
  static const action = Color(0xFF008A29);
  static const soft = Color(0xFFEAF7EE);
  static const forest = Color(0xFF163C2B);
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.5,
    color: muted,
    fontWeight: FontWeight.w400,
  );
  static const title = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    color: ink,
  );
}

class ProfileLayout extends StatelessWidget {
  const ProfileLayout({
    super.key,
    required this.title,
    required this.child,
    this.onBack,
    this.action,
  });
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.apply(
        fontFamily: 'Noto Sans KR',
        bodyColor: ProfileStyle.ink,
        displayColor: ProfileStyle.ink,
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: TextButton(
                        onPressed:
                            onBack ?? () => Navigator.of(context).maybePop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: ProfileStyle.ink,
                        ),
                        child: const Text(
                          '‹',
                          semanticsLabel: '뒤로',
                          style: TextStyle(
                            fontSize: 24,
                            height: 32 / 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ?action,
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class AccountMenuRow extends StatelessWidget {
  const AccountMenuRow({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, height: 24 / 15),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '›',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: ProfileStyle.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProfileSecondaryButton extends StatelessWidget {
  const ProfileSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: Colors.white,
        foregroundColor: ProfileStyle.ink,
        side: const BorderSide(color: Color(0xFFE1E6E2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Noto Sans KR',
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

void showProfileComingSoon(BuildContext context, String title) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: const Text('아직 준비 중이에요. 준비되면 안내해 드릴게요.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
