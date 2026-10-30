import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const chatGuidelinesParagraphs = [
  '달러물림은 자유로운 의견 교환을 존중합니다.',
  '다만 타인에 대한 반복적인 괴롭힘, 협박, 개인정보 유포, 도배 및 불법 콘텐츠 게시 등의 행위는 금지됩니다.',
  '위반 시 운영 정책에 따라 메시지 삭제, 채팅 이용 제한 또는 계정 정지 등의 조치가 이루어질 수 있습니다.',
  '이용 중 부적절한 메시지는 신고 기능을 통해 알려주세요.',
];

class ChatGuidelinesStore {
  const ChatGuidelinesStore({this.storage = const FlutterSecureStorage()});

  static const storageKey = 'chat.guidelines.v1.seen';
  final FlutterSecureStorage storage;

  Future<bool> hasSeen() async => await storage.read(key: storageKey) == 'true';

  Future<void> acknowledge() async {
    try {
      await storage.write(key: storageKey, value: 'true');
    } catch (_) {
      // Keep it eligible next launch if the confirmation cannot be saved.
    }
  }
}

class ChatGuidelinesDialog extends StatelessWidget {
  const ChatGuidelinesDialog({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('채팅 이용 안내'),
    scrollable: true,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < chatGuidelinesParagraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Text(
            chatGuidelinesParagraphs[i],
            style: const TextStyle(fontSize: 15, height: 1.7),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('확인'),
      ),
    ],
  );
}

Future<void> showChatGuidelines(
  BuildContext context, {
  ChatGuidelinesStore store = const ChatGuidelinesStore(),
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => const ChatGuidelinesDialog(),
  );
  if (confirmed == true) await store.acknowledge();
}
