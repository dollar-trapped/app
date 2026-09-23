import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/core/realtime/dollar_socket.dart';
import 'package:dollar_trapped/features/chat/widgets/message_list.dart';
import 'package:dollar_trapped/features/chat/widgets/chat_message_bubble.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';

void main() {
  for (final realtime in [false, true]) {
    for (final currentUserId in <String?>[null, 'user-me']) {
      for (final authorId in <String?>[null, 'user-me', 'user-other']) {
        testWidgets(
          'ownership: realtime=$realtime viewer=$currentUserId author=$authorId',
          (tester) async {
            final controller = ScrollController();
            addTearDown(controller.dispose);
            final author = <String, dynamic>{
              'id': authorId,
              'nickname': authorId == null ? '탈퇴한 사용자' : '사용자',
              'usdAmount': null,
              'profitRate': null,
              'profitRateAsOf': null,
            };
            final message = ChatMessage.fromJson({
              'id': 'message-1',
              'cursor': 'cursor-1',
              'roomId': 'usd',
              'author': author,
              'content': '메시지',
              'createdAt': '2026-09-22T00:00:00Z',
            });
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: MessageList(
                    future: Future.value(
                      MessagePage(
                        items: realtime ? [] : [message],
                        hasMore: false,
                        nextCursor: null,
                        latestCursor: 'cursor-1',
                      ),
                    ),
                    realtimeMessages: realtime
                        ? [
                            RealtimeMessage(
                              id: 'message-1',
                              content: '메시지',
                              data: {'author': author},
                            ),
                          ]
                        : [],
                    blockedUserIds: const {},
                    currentUserId: currentUserId,
                    scrollController: controller,
                    onRetry: () {},
                    onModerate:
                        ({required messageId, required authorId}) async {},
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final bubble = tester.widget<ChatMessageBubble>(
              find.byType(ChatMessageBubble),
            );
            expect(
              bubble.isMine,
              currentUserId != null && authorId == currentUserId,
            );
            if (currentUserId == null || authorId == null) {
              expect(bubble.onLongPress, isNull);
            }
            if (authorId == null) expect(find.text('탈퇴한 사용자'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
