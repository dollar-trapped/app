import 'package:flutter/material.dart';
import 'moderation_status.dart';

Future<void> showModerationDialog(
  BuildContext context,
  ModerationNotice notice,
) => showDialog<void>(
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
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('확인'),
      ),
    ],
  ),
);
