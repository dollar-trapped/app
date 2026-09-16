import 'package:dollar_trapped/features/shared/data/json_helpers.dart';

class ReportReceipt {
  const ReportReceipt({
    required this.id,
    required this.messageId,
    required this.createdAt,
  });
  final String id, messageId;
  final DateTime createdAt;
  factory ReportReceipt.fromJson(Json json) => ReportReceipt(
    id: json['id'] as String,
    messageId: json['messageId'] as String,
    createdAt: jsonDate(json, 'createdAt'),
  );
}
