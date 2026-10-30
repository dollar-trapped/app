import 'package:dollar_trapped/features/shared/widgets/skeleton.dart';
import 'package:dollar_trapped/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../shared/data/api_models.dart';

class RateBar extends StatelessWidget {
  const RateBar({super.key, required this.rateFuture});

  final Future<ExchangeRate> rateFuture;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: const BoxConstraints(minHeight: 88),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.of(context).line)),
    ),
    child: FutureBuilder<ExchangeRate>(
      future: rateFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Skeleton(
            label: '환율 불러오는 중',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'USD/KRW',
                      style: TextStyle(
                        color: AppColors.of(context).muted,
                        fontSize: 15,
                      ),
                    ),
                    const SkeletonLine(width: 120, height: 27),
                  ],
                ),
                const SizedBox(height: 8),
                const SkeletonLine(width: 224, height: 21),
              ],
            ),
          );
        }
        final rate = snapshot.data;
        final value = double.tryParse(rate?.rate ?? '');
        final previous = double.tryParse(rate?.previousCloseRate ?? '');
        final canCompare =
            value != null &&
            value.isFinite &&
            previous != null &&
            previous.isFinite &&
            previous > 0 &&
            rate?.previousCloseAsOf != null &&
            (rate?.marketStatus == 'OPEN' || rate?.marketStatus == 'CLOSED') &&
            rate?.isStale == false;
        final difference = canCompare ? value - previous : null;
        final percent = canCompare ? difference! / previous * 100 : null;
        final falling = difference != null && difference < 0;
        final rising = difference != null && difference > 0;
        final comparisonColor = falling
            ? AppColors.of(context).marketFall
            : rising
            ? AppColors.of(context).marketRise
            : AppColors.of(context).muted;
        final subtitle = snapshot.hasError
            ? '환율을 불러오지 못했어요'
            : rate == null
            ? '환율 불러오는 중…'
            : rate.isStale || rate.marketStatus == 'UNAVAILABLE'
            ? '마지막 확인값'
            : difference == null
            ? null
            : '${falling
                  ? '▼'
                  : rising
                  ? '▲'
                  : '—'} ${difference.abs().toStringAsFixed(2)} (${percent! > 0 ? '+' : ''}${percent.toStringAsFixed(2)}%) · 전일 대비';
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'USD/KRW',
                        style: TextStyle(
                          color: AppColors.of(context).muted,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        value == null || !value.isFinite
                            ? '—'
                            : '${_format(value)}원',
                        style: TextStyle(
                          color: AppColors.of(context).ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: comparisonColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '›',
              style: TextStyle(
                color: AppColors.of(context).muted,
                fontSize: 32,
              ),
            ),
          ],
        );
      },
    ),
  );

  static String _format(double value) => value
      .toStringAsFixed(2)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+\.)'),
        (match) => '${match[1]},',
      );
}
