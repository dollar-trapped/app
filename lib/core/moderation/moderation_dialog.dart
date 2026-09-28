import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'moderation_status.dart';

Future<void> showModerationDialog(
  BuildContext context,
  ModerationNotice notice, {
  String? userId,
}) async {
  const storage = FlutterSecureStorage();
  final key = notice.type == 'WARNING' && userId != null
      ? 'moderation.warning.${jsonEncode([userId, notice.id])}'
      : null;
  if (key != null) {
    try {
      if (await storage.read(key: key) == 'confirmed') return;
    } catch (_) {
      // Storage failure must not prevent the notice from being displayed.
    }
  }
  if (!context.mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: !notice.suspended,
    builder: (context) => AlertDialog(
      title: Text(notice.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice.message),
            if (notice.blocksChat) ...[
              const SizedBox(height: 16),
              Text(notice.period),
            ],
            if (notice.type == 'WARNING') ...[
              const SizedBox(height: 12),
              const Text('경고는 이용 제한이 아닙니다. 서비스는 계속 이용할 수 있습니다.'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('확인'),
        ),
      ],
    ),
  );
  if (confirmed == true && key != null) {
    try {
      await storage.write(key: key, value: 'confirmed');
    } catch (_) {
      // Keep the notice eligible next launch if persistence is unavailable.
    }
  }
}
