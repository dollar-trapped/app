import 'package:dollar_trapped/features/shared/data/json_helpers.dart';
import 'package:dollar_trapped/features/chat/models/chat_message.dart';

class MessagePage {
  const MessagePage({
    required this.items,
    required this.hasMore,
    required this.nextCursor,
    required this.latestCursor,
  });
  final List<ChatMessage> items;
  final bool hasMore;
  final String? nextCursor;
  final String latestCursor;
  factory MessagePage.fromJson(Json json) {
    final page = Json.from(json['page'] as Map);
    return MessagePage(
      items: (json['items'] as List)
          .map((item) => ChatMessage.fromJson(Json.from(item as Map)))
          .toList(),
      hasMore: page['hasMore'] as bool,
      nextCursor: jsonString(page, 'nextCursor'),
      latestCursor: page['latestCursor'] as String,
    );
  }
}
