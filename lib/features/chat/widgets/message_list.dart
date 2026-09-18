import '../../gacha/data/cosmetic_models.dart';
import 'package:dollar_trapped/features/chat/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/core/realtime/dollar_socket.dart';

class MessageList extends StatelessWidget {
  const MessageList({
    super.key,
    required this.future,
    required this.realtimeMessages,
    required this.blockedUserIds,
    required this.currentUserId,
    required this.scrollController,
    required this.onRetry,
    required this.onModerate,
  });

  final Future<MessagePage> future;
  final List<RealtimeMessage> realtimeMessages;
  final Set<String> blockedUserIds;
  final String? currentUserId;
  final ScrollController scrollController;
  final VoidCallback onRetry;
  final Future<void> Function({
    required String messageId,
    required String authorId,
  })
  onModerate;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MessagePage>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            realtimeMessages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: onRetry,
              child: const Text('메시지를 다시 불러오기'),
            ),
          );
        }
        final messages = (snapshot.data?.items ?? const <ChatMessage>[])
            .where(
              (message) =>
                  message.author.id == null ||
                  !blockedUserIds.contains(message.author.id),
            )
            .toList();
        messages.sort(
          (first, second) => first.createdAt.compareTo(second.createdAt),
        );
        if (messages.isEmpty && realtimeMessages.isEmpty) {
          return const Center(
            child: Text(
              '아직 메시지가 없어요.',
              style: TextStyle(color: Color(0xFF667069)),
            ),
          );
        }
        // Filter data now, but construct bubbles only for the visible viewport.
        final visibleRealtime = realtimeMessages.where((message) {
          final author = message.data['author'];
          final authorId = author is Map ? author['id'] as String? : null;
          return authorId == null || !blockedUserIds.contains(authorId);
        }).toList();
        final headerCount = messages.isEmpty ? 0 : 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!scrollController.hasClients) return;
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });
        return ListView.separated(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          itemCount: headerCount + messages.length + visibleRealtime.length,
          separatorBuilder: (_, _) => const SizedBox(height: 24),
          itemBuilder: (_, index) {
            if (headerCount == 1 && index == 0) {
              return _DateLabel(date: messages.first.createdAt);
            }
            final messageIndex = index - headerCount;
            if (messageIndex < messages.length) {
              return _messageWidget(
                messages[messageIndex],
                currentUserId: currentUserId,
                onModerate: onModerate,
              );
            }
            return _RealtimeChatMessage(
              message: visibleRealtime[messageIndex - messages.length],
              currentUserId: currentUserId,
              onModerate: onModerate,
            );
          },
        );
      },
    );
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final period = local.hour < 12 ? '오전' : '오후';
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$period $hour:${local.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime time) {
    const weekdays = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
    final local = time.toLocal();
    return '${local.month}월 ${local.day}일 ${weekdays[local.weekday - 1]}';
  }

  static Widget _messageWidget(
    ChatMessage message, {
    required String? currentUserId,
    required Future<void> Function({
      required String messageId,
      required String authorId,
    })
    onModerate,
  }) {
    final profit = message.author.profitRate;
    return ChatMessageBubble(
      nickname: message.author.nickname,
      cosmetics: message.author.cosmetics,
      holding: message.author.usdAmount == null
          ? ''
          : r'$' + message.author.usdAmount!,
      profit: _profitText(profit),
      profitColor: profit?.startsWith('-') ?? false
          ? const Color(0xFF2463B5)
          : const Color(0xFF008A29),
      message: message.content,
      time: _formatTime(message.createdAt),
      isMine: message.author.id == currentUserId,
      onLongPress:
          currentUserId == null ||
              message.author.id == null ||
              message.author.id == currentUserId
          ? null
          : () =>
                onModerate(messageId: message.id, authorId: message.author.id!),
    );
  }

  static String _profitText(String? profit) {
    if (profit == null) return '';
    final prefix = double.tryParse(profit) != null && !profit.startsWith('-')
        ? '+'
        : '';
    return '$prefix$profit%';
  }
}

class _RealtimeChatMessage extends StatelessWidget {
  const _RealtimeChatMessage({
    required this.message,
    required this.currentUserId,
    required this.onModerate,
  });

  final RealtimeMessage message;
  final String? currentUserId;
  final Future<void> Function({
    required String messageId,
    required String authorId,
  })
  onModerate;

  @override
  Widget build(BuildContext context) {
    final author = message.data['author'] is Map
        ? Map<String, dynamic>.from(message.data['author'] as Map)
        : const <String, dynamic>{};
    final authorId = author['id'] as String?;
    return ChatMessageBubble(
      nickname: author['nickname'] as String? ?? '익명',
      cosmetics: author['cosmetics'] is Map
          ? MessageCosmetics.fromJson(
              Map<String, dynamic>.from(author['cosmetics'] as Map),
            )
          : null,
      holding: author['usdAmount'] == null ? '' : "\$${author['usdAmount']}",
      profit: MessageList._profitText(author['profitRate'] as String?),
      profitColor: (author['profitRate'] as String?)?.startsWith('-') ?? false
          ? const Color(0xFF2463B5)
          : const Color(0xFF008A29),
      message: message.content,
      time: MessageList._formatTime(DateTime.now()),
      isMine: authorId == currentUserId,
      onLongPress:
          currentUserId == null || authorId == null || authorId == currentUserId
          ? null
          : () => onModerate(messageId: message.id, authorId: authorId),
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Text(
    MessageList._formatDate(date),
    style: const TextStyle(color: Color(0xFF667069), fontSize: 12, height: 1.5),
  );
}
