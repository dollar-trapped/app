import 'package:dollar_trapped/core/theme/app_colors.dart';
import '../../cosmetics/models/cosmetic_models.dart';
import '../../cosmetics/widgets/server_cosmetic_preview.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.nickname,
    required this.holding,
    required this.profit,
    required this.message,
    required this.time,
    this.profitColor,
    this.onLongPress,
    this.isMine = false,
    this.cosmetics,
  });

  final MessageCosmetics? cosmetics;
  final String nickname;
  final String holding;
  final String profit;
  final String message;
  final String time;
  final Color? profitColor;
  final VoidCallback? onLongPress;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final alignment = isMine
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            Wrap(
              alignment: isMine ? WrapAlignment.end : WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (cosmetics != null)
                  ServerCosmeticNickname(
                    nickname: nickname,
                    size: 13,
                    color: cosmetics!.color,
                    font: cosmetics!.font,
                    background: cosmetics!.background,
                  )
                else
                  Text(
                    nickname,
                    style: TextStyle(
                      color: AppColors.of(context).ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 20 / 13,
                    ),
                  ),
                Text(
                  holding,
                  style: TextStyle(
                    color: AppColors.of(context).muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                if (profit.isEmpty && holding.isNotEmpty)
                  Tooltip(
                    message: '매수환율 또는 현재 환율 정보가 없어 수익률을 확인할 수 없어요.',
                    triggerMode: TooltipTriggerMode.tap,
                    child: Text(
                      '수익률 —',
                      style: TextStyle(
                        color: AppColors.of(context).muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  Text(
                    profit,
                    style: TextStyle(
                      color: profitColor ?? AppColors.of(context).action,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              key: Key(isMine ? 'chat-bubble-own' : 'chat-bubble-incoming'),
              constraints: const BoxConstraints(maxWidth: 304),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMine
                    ? AppColors.of(context).soft
                    : AppColors.of(context).surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: AppColors.of(context).ink,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                color: AppColors.of(context).muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
