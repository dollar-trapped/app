import 'package:flutter/material.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';

class HistoryChartSection extends StatelessWidget {
  const HistoryChartSection({
    super.key,
    required this.future,
    required this.onRetry,
  });

  final Future<ExchangeRateHistory> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExchangeRateHistory>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 278,
            child: Center(child: Text('환율 이력을 불러오는 중이에요.')),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 278,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('환율 이력을 불러오지 못했어요.'),
                  TextButton(onPressed: onRetry, child: const Text('차트 다시 시도')),
                ],
              ),
            ),
          );
        }
        final points = (snapshot.data?.points ?? const <ExchangeRatePoint>[])
            .map((point) {
              final rate = double.tryParse(point.rate);
              return rate == null ? null : _ChartPoint(point.time, rate);
            })
            .whereType<_ChartPoint>()
            .toList();
        if (points.isEmpty) {
          return const SizedBox(
            height: 278,
            child: Center(child: Text('환율 데이터가 없어요.')),
          );
        }
        return Column(
          children: [
            SizedBox(
              key: const Key('exchange-rate-history-chart'),
              width: double.infinity,
              height: 266,
              child: CustomPaint(painter: _HistoryChartPainter(points)),
            ),
            if (points.length == 1)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  '데이터가 한 건만 있어요.',
                  style: TextStyle(color: Color(0xFF667069), fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChartPoint {
  const _ChartPoint(this.time, this.rate);

  final DateTime time;
  final double rate;
}

class _HistoryChartPainter extends CustomPainter {
  const _HistoryChartPainter(this.points);

  final List<_ChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const chartPadding = EdgeInsets.fromLTRB(0, 12, 48, 12);
    final chart = Rect.fromLTWH(
      chartPadding.left,
      chartPadding.top,
      size.width - chartPadding.horizontal,
      size.height - chartPadding.vertical,
    );
    final gridPaint = Paint()
      ..color = const Color(0xFFE1E6E2)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index += 1) {
      final y = chart.top + chart.height * index / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    final minRate = points
        .map((point) => point.rate)
        .reduce((a, b) => a < b ? a : b);
    final maxRate = points
        .map((point) => point.rate)
        .reduce((a, b) => a > b ? a : b);
    final rateSpan = maxRate - minRate;
    final firstTime = points.first.time.millisecondsSinceEpoch;
    final lastTime = points.last.time.millisecondsSinceEpoch;
    final timeSpan = lastTime - firstTime;
    Offset offsetFor(_ChartPoint point) {
      final x = timeSpan == 0
          ? chart.center.dx
          : chart.left +
                chart.width *
                    (point.time.millisecondsSinceEpoch - firstTime) /
                    timeSpan;
      final y = rateSpan == 0
          ? chart.center.dy
          : chart.bottom - chart.height * (point.rate - minRate) / rateSpan;
      return Offset(x, y);
    }

    final linePaint = Paint()
      ..color = const Color(0xFF008A29)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    if (points.length == 1) {
      // A single sample has no segment, so render only its position.
      canvas.drawCircle(
        offsetFor(points.single),
        4,
        Paint()..color = const Color(0xFF008A29),
      );
      return;
    }
    final path = Path()
      ..moveTo(offsetFor(points.first).dx, offsetFor(points.first).dy);
    for (final point in points.skip(1)) {
      final offset = offsetFor(point);
      path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(path, linePaint);
    canvas.drawCircle(
      offsetFor(points.last),
      4,
      Paint()..color = const Color(0xFF008A29),
    );
  }

  @override
  bool shouldRepaint(_HistoryChartPainter oldDelegate) =>
      !identical(points, oldDelegate.points);
}
