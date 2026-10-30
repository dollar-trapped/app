import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

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
          Text(
            '메시지 관리',
            style: TextStyle(
              fontFamily: 'Noto Sans KR',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).ink,
            ),
          ),
          const SizedBox(height: 8),
          Text('이 메시지를 어떻게 할까요?', style: AppColors.of(context).caption),
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
              foregroundColor: AppColors.of(context).ink,
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: AppColors.of(context).line),
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
    final color = destructive
        ? AppColors.of(context).error
        : AppColors.of(context).forest;
    return Material(
      color: AppColors.of(context).surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: destructive
                ? AppColors.of(context).errorSurface
                : AppColors.of(context).soft,
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
        subtitle: Text(subtitle, style: AppColors.of(context).caption),
        onTap: () => Navigator.of(context).pop(action),
      ),
    );
  }
}
