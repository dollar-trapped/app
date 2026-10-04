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
        final points =
            (snapshot.data?.points ?? const <ExchangeRatePoint>[])
                .map((point) {
                  final rate = double.tryParse(point.rate);
                  return rate == null || !rate.isFinite
                      ? null
                      : _ChartPoint(point.time, rate);
                })
                .whereType<_ChartPoint>()
                .toList()
              ..sort((a, b) => a.time.compareTo(b.time));
        if (points.isEmpty) {
          return const SizedBox(
            height: 278,
            child: Center(child: Text('환율 데이터가 없어요.')),
          );
        }
        return Column(
          children: [
            _InteractiveHistoryChart(
              key: ObjectKey(snapshot.data),
              points: points,
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

class _InteractiveHistoryChart extends StatefulWidget {
  const _InteractiveHistoryChart({super.key, required this.points});
  final List<_ChartPoint> points;

  @override
  State<_InteractiveHistoryChart> createState() =>
      _InteractiveHistoryChartState();
}

class _InteractiveHistoryChartState extends State<_InteractiveHistoryChart> {
  int? _selected;

  void _select(double x, double width) {
    final geometry = _ChartGeometry(widget.points, Size(width, 266));
    final fraction = ((x - geometry.chart.left) / geometry.chart.width).clamp(
      0.0,
      1.0,
    );
    final target = geometry.firstTime + geometry.timeSpan * fraction;
    var nearest = 0;
    var distance = double.infinity;
    for (var i = 0; i < widget.points.length; i++) {
      final candidate = (widget.points[i].time.millisecondsSinceEpoch - target)
          .abs();
      if (candidate < distance) {
        distance = candidate;
        nearest = i;
      }
    }
    if (_selected != nearest) setState(() => _selected = nearest);
  }

  void _move(int direction) => setState(() {
    _selected = ((_selected ?? widget.points.length - 1) + direction).clamp(
      0,
      widget.points.length - 1,
    );
  });

  String _description(_ChartPoint point) {
    final time = point.time.toUtc().add(const Duration(hours: 9));
    String two(int value) => value.toString().padLeft(2, '0');
    final value = point.rate
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (match) => '${match[1]},',
        );
    return '${time.year}.${two(time.month)}.${two(time.day)} ${two(time.hour)}:${two(time.minute)} 한국 시간 · $value원';
  }

  @override
  Widget build(BuildContext context) {
    final description = _selected == null
        ? null
        : _description(widget.points[_selected!]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              description ?? '차트를 눌러 조회하거나 꾹 누른 채 움직여보세요.',
              key: const Key('exchange-rate-chart-readout'),
              style: TextStyle(
                color: description == null
                    ? const Color(0xFF667069)
                    : const Color(0xFF151916),
                fontSize: 13,
                height: 1.5,
                fontWeight: description == null
                    ? FontWeight.w400
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => Semantics(
            label: '기간별 환율 차트',
            value: description ?? '지점을 선택하면 날짜와 환율을 확인할 수 있습니다.',
            increasedValue: _description(
              widget.points[((_selected ?? widget.points.length - 1) + 1).clamp(
                0,
                widget.points.length - 1,
              )],
            ),
            decreasedValue: _description(
              widget.points[((_selected ?? widget.points.length - 1) - 1).clamp(
                0,
                widget.points.length - 1,
              )],
            ),
            onIncrease: () => _move(1),
            onDecrease: () => _move(-1),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) =>
                  _select(details.localPosition.dx, constraints.maxWidth),
              // Long press scrubbing leaves ordinary swipes to page navigation.
              onLongPressStart: (details) =>
                  _select(details.localPosition.dx, constraints.maxWidth),
              onLongPressMoveUpdate: (details) =>
                  _select(details.localPosition.dx, constraints.maxWidth),
              child: SizedBox(
                key: const Key('exchange-rate-history-chart'),
                width: double.infinity,
                height: 266,
                child: CustomPaint(
                  painter: _HistoryChartPainter(
                    widget.points,
                    selected: _selected,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartGeometry {
  _ChartGeometry(this.points, Size size) {
    const padding = EdgeInsets.fromLTRB(0, 12, 48, 12);
    chart = Rect.fromLTWH(
      0,
      12,
      (size.width - padding.horizontal).clamp(1.0, double.infinity),
      size.height - padding.vertical,
    );
    minRate = points.map((point) => point.rate).reduce((a, b) => a < b ? a : b);
    maxRate = points.map((point) => point.rate).reduce((a, b) => a > b ? a : b);
  }
  final List<_ChartPoint> points;
  late final Rect chart;
  late final double minRate, maxRate;
  int get firstTime => points.first.time.millisecondsSinceEpoch;
  int get timeSpan => points.last.time.millisecondsSinceEpoch - firstTime;

  Offset offsetFor(_ChartPoint point) => Offset(
    timeSpan == 0
        ? chart.center.dx
        : chart.left +
              chart.width *
                  (point.time.millisecondsSinceEpoch - firstTime) /
                  timeSpan,
    maxRate == minRate
        ? chart.center.dy
        : chart.bottom -
              chart.height * (point.rate - minRate) / (maxRate - minRate),
  );
}

class _HistoryChartPainter extends CustomPainter {
  const _HistoryChartPainter(this.points, {this.selected});

  final List<_ChartPoint> points;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = _ChartGeometry(points, size);
    final chart = geometry.chart;
    final offsetFor = geometry.offsetFor;
    final gridPaint = Paint()
      ..color = const Color(0xFFE1E6E2)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index += 1) {
      final y = chart.top + chart.height * index / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
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
      _paintSelection(canvas, chart, offsetFor);
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
    _paintSelection(canvas, chart, offsetFor);
  }

  void _paintSelection(
    Canvas canvas,
    Rect chart,
    Offset Function(_ChartPoint) offsetFor,
  ) {
    if (selected == null) return;
    final offset = offsetFor(points[selected!]);
    canvas.drawLine(
      Offset(offset.dx, chart.top),
      Offset(offset.dx, chart.bottom),
      Paint()
        ..color = const Color(0xFF667069)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(offset, 7, Paint()..color = Colors.white);
    canvas.drawCircle(offset, 5, Paint()..color = const Color(0xFF008A29));
  }

  @override
  bool shouldRepaint(_HistoryChartPainter oldDelegate) {
    if (selected != oldDelegate.selected) return true;
    if (identical(points, oldDelegate.points)) return false;
    if (points.length != oldDelegate.points.length) return true;
    for (var i = 0; i < points.length; i++) {
      if (points[i].time != oldDelegate.points[i].time ||
          points[i].rate != oldDelegate.points[i].rate) {
        return true;
      }
    }
    return false;
  }
}
