import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dollar_trapped/core/realtime/dollar_socket.dart';
import 'package:dollar_trapped/features/chat/widgets/message_list.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';

void main() {
  testWidgets(
    'hidden realtime messages retain a placeholder; later blocked messages stay absent',
    (tester) async {
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final future = Future.value(
        const MessagePage(
          items: [],
          hasMore: false,
          nextCursor: null,
          latestCursor: '',
        ),
      );
      RealtimeMessage message(String id, String userId, String text) =>
          RealtimeMessage(
            id: id,
            content: text,
            data: {
              'author': {'id': userId, 'nickname': '사용자'},
            },
          );
      final messages = [
        message('hidden', 'visible-user', '숨길 본문'),
        message('blocked-old', 'blocked-user', '차단 이전 메시지'),
      ];
      Widget app(Set<String> blocked) => MaterialApp(
        home: Scaffold(
          body: MessageList(
            future: future,
            realtimeMessages: messages,
            blockedUserIds: blocked,
            hiddenMessageIds: const {'hidden'},
            currentUserId: 'me',
            scrollController: scroll,
            onRetry: () {},
            onModerate: ({required messageId, required authorId}) async {},
          ),
        ),
      );
      await tester.pumpWidget(app({'blocked-user'}));
      await tester.pumpAndSettle();
      expect(find.text('숨겨진 메시지'), findsOneWidget);
      expect(find.text('숨길 본문'), findsNothing);
      expect(find.text('차단 이전 메시지'), findsNothing);
      messages.add(message('blocked-new', 'blocked-user', '차단 이후 메시지'));
      await tester.pumpWidget(app({'blocked-user'}));
      await tester.pumpAndSettle();
      expect(find.text('차단 이후 메시지'), findsNothing);
      await tester.pumpWidget(app({}));
      await tester.pumpAndSettle();
      expect(find.text('차단 이전 메시지'), findsOneWidget);
      expect(find.text('차단 이후 메시지'), findsOneWidget);
      expect(find.text('숨겨진 메시지'), findsOneWidget);
    },
  );
}
