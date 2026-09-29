import 'package:flutter/material.dart';
import '../../shared/data/api_models.dart';

class RateBar extends StatelessWidget {
  const RateBar({super.key, required this.rateFuture});

  final Future<ExchangeRate> rateFuture;

  @override
  Widget build(BuildContext context) => Container(
    height: 80,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: Color(0xFFE1E6E2))),
    ),
    child: FutureBuilder<ExchangeRate>(
      future: rateFuture,
      builder: (context, snapshot) {
        final rate = snapshot.data;
        final time = rate?.asOf.toUtc().add(const Duration(hours: 9));
        final value = rate == null ? null : double.tryParse(rate.rate);
        final formatted = value
            ?.toStringAsFixed(2)
            .replaceFirstMapped(RegExp(r'(?<!^)(?=(\d{3})+\.)'), (_) => ',');
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'USD/KRW  ${formatted == null ? '—' : '$formatted원'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.hasError
                        ? '환율을 불러오지 못했어요'
                        : time == null
                        ? '환율 불러오는 중…'
                        : '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} 한국 시간 · ${rate!.isStale ? '마지막 확인값' : '5분마다 갱신'}',
                    style: const TextStyle(
                      color: Color(0xFF667069),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              '›',
              style: TextStyle(color: Color(0xFF667069), fontSize: 32),
            ),
          ],
        );
      },
    ),
  );
}
