import 'package:flutter/material.dart';
import '../../profile/widgets/profile_layout.dart';

enum MessageAction { hide, block, report }

class MessageActionsSheet extends StatelessWidget {
  const MessageActionsSheet({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '메시지 관리',
            style: TextStyle(
              fontFamily: 'Noto Sans KR',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ProfileStyle.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text('이 메시지를 어떻게 할까요?', style: ProfileStyle.caption),
          const SizedBox(height: 20),
          _action(
            context,
            MessageAction.hide,
            Icons.visibility_off_outlined,
            '숨기기',
            '이번 채팅 화면에서 나에게만 숨겨요.',
          ),
          const SizedBox(height: 8),
          _action(
            context,
            MessageAction.block,
            Icons.block_outlined,
            '차단',
            '이 사용자의 메시지를 보지 않아요.',
          ),
          const SizedBox(height: 8),
          _action(
            context,
            MessageAction.report,
            Icons.flag_outlined,
            '신고하기',
            '운영자에게 검토를 요청해요.',
            destructive: true,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: ProfileStyle.ink,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Color(0xFFE1E6E2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    ),
  );

  Widget _action(
    BuildContext context,
    MessageAction action,
    IconData icon,
    String title,
    String subtitle, {
    bool destructive = false,
  }) {
    final color = destructive ? const Color(0xFFB3261E) : ProfileStyle.forest;
    return Material(
      color: const Color(0xFFF5F7F5),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: destructive ? const Color(0xFFFCEDEA) : ProfileStyle.soft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: Text(subtitle, style: ProfileStyle.caption),
        onTap: () => Navigator.of(context).pop(action),
      ),
    );
  }
}
