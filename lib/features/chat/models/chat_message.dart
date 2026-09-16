import 'package:dollar_trapped/features/shared/data/json_helpers.dart';
import 'package:dollar_trapped/features/chat/models/message_author.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.cursor,
    required this.roomId,
    required this.author,
    required this.content,
    required this.createdAt,
  });
  final String id, cursor, roomId, content;
  final MessageAuthor author;
  final DateTime createdAt;
  factory ChatMessage.fromJson(Json json) => ChatMessage(
    id: json['id'] as String,
    cursor: json['cursor'] as String,
    roomId: json['roomId'] as String,
    author: MessageAuthor.fromJson(Json.from(json['author'] as Map)),
    content: json['content'] as String,
    createdAt: jsonDate(json, 'createdAt'),
  );
}
