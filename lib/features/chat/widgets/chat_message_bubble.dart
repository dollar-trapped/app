import '../../gacha/data/cosmetic_models.dart';
import '../../gacha/widgets/server_cosmetic_preview.dart';
import 'package:flutter/material.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.nickname,
    required this.holding,
    required this.profit,
    required this.message,
    required this.time,
    this.profitColor = const Color(0xFF008A29),
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
  final Color profitColor;
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
            Row(
              mainAxisSize: MainAxisSize.min,
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
                    style: const TextStyle(
                      color: Color(0xFF151916),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 20 / 13,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  holding,
                  style: const TextStyle(
                    color: Color(0xFF667069),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  profit,
                  style: TextStyle(
                    color: profitColor,
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
                    ? const Color(0xFFEAF7EE)
                    : const Color(0xFFF5F7F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF151916),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: const TextStyle(
                color: Color(0xFF667069),
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
