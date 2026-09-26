import 'package:flutter/material.dart';

class MessageReportInput {
  const MessageReportInput(this.reason, this.description);
  final String reason;
  final String? description;
}

class ReportMessageDialog extends StatefulWidget {
  const ReportMessageDialog({super.key});

  @override
  State<ReportMessageDialog> createState() => _ReportMessageDialogState();
}

class _ReportMessageDialogState extends State<ReportMessageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String? _reason;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final description = _description.text.trim();
    Navigator.of(context).pop(
      MessageReportInput(_reason!, description.isEmpty ? null : description),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('메시지 신고'),
    scrollable: true,
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: '신고 사유'),
            items: const [
              DropdownMenuItem(value: 'SPAM', child: Text('스팸·광고')),
              DropdownMenuItem(value: 'ABUSE', child: Text('욕설·괴롭힘')),
              DropdownMenuItem(value: 'OTHER', child: Text('기타')),
            ],
            onChanged: (value) => setState(() => _reason = value),
            validator: (value) => value == null ? '신고 사유를 선택해 주세요.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: _reason == 'OTHER' ? '상세 사유 (필수)' : '상세 사유 (선택)',
              alignLabelWithHint: true,
            ),
            validator: (value) =>
                _reason == 'OTHER' && (value == null || value.trim().isEmpty)
                ? '기타 신고는 상세 사유를 입력해 주세요.'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('취소'),
      ),
      FilledButton(onPressed: _submit, child: const Text('신고 접수')),
    ],
  );
}
