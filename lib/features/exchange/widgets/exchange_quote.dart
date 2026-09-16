import 'package:flutter/material.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';

class ExchangeQuote extends StatelessWidget {
  const ExchangeQuote({
    super.key,
    required this.rateFuture,
    required this.onRetry,
  });

  final Future<ExchangeRate> rateFuture;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExchangeRate>(
      future: rateFuture,
      builder: (context, snapshot) {
        final rate = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '미국 달러 / 대한민국 원',
              style: TextStyle(
                color: Color(0xFF667069),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 20 / 13,
              ),
            ),
            const SizedBox(height: 8),
            if (snapshot.connectionState == ConnectionState.waiting)
              const SizedBox(
                height: 46,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CircularProgressIndicator(),
                ),
              )
            else if (rate != null) ...[
              Text(
                '${_formatRate(rate.rate)}원',
                style: const TextStyle(
                  color: Color(0xFF151916),
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 46 / 36,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                rate.isStale ? '마지막으로 확인된 환율' : '실시간 환율',
                style: const TextStyle(
                  color: Color(0xFF008A29),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 20 / 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatDate(rate.asOf)} UTC 기준 · ${rate.source}',
                style: const TextStyle(
                  color: Color(0xFF667069),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ] else ...[
              const Text(
                '환율을 불러오지 못했어요.',
                style: TextStyle(color: Color(0xFF151916), fontSize: 18),
              ),
              TextButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ],
        );
      },
    );
  }

  static String _formatRate(String value) {
    final rate = double.tryParse(value);
    if (rate == null) return value;
    return rate
        .toStringAsFixed(2)
        .replaceFirstMapped(RegExp(r'(?<!^)(?=(\d{3})+\.)'), (_) => ',');
  }

  static String _formatDate(DateTime date) {
    final utc = date.toUtc();
    return '${utc.month}월 ${utc.day}일 ${utc.hour.toString().padLeft(2, '0')}:${utc.minute.toString().padLeft(2, '0')}';
  }
}
