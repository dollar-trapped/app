import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/data/api_models.dart';
import '../../../shared/data/dollar_repository.dart';
import '../../../shared/data/mock_dollar_repository.dart';
import 'my_page.dart';
import 'usd_room_page.dart';

class UsdKrwPage extends StatefulWidget {
  const UsdKrwPage({super.key, this.repository, this.initialPage = 1});

  final DollarRepository? repository;
  final int initialPage;

  @override
  State<UsdKrwPage> createState() => _UsdKrwPageState();
}

class _UsdKrwPageState extends State<UsdKrwPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository =
        widget.repository ??
        context.read<DollarRepository?>() ??
        MockDollarRepository();
    return PageView(
      controller: _pageController,
      children: [
        MyPage(
          repository: repository,
          onBack: () => _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        ),
        _UsdKrwDetailPage(repository: repository),
        UsdRoomPage(
          repository: repository,
          onRateBarTap: () => _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        ),
      ],
    );
  }
}

class _UsdKrwDetailPage extends StatefulWidget {
  const _UsdKrwDetailPage({required this.repository});

  final DollarRepository repository;

  @override
  State<_UsdKrwDetailPage> createState() => _UsdKrwDetailPageState();
}

class _UsdKrwDetailPageState extends State<_UsdKrwDetailPage> {
  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _periods = {'1일': '1D', '1주': '1W', '1개월': '1M'};
  var _selectedRange = '1M';
  late Future<ExchangeRate> _rateFuture;
  late Future<ExchangeRateHistory> _historyFuture;

  @override
  void initState() {
    super.initState();
    _rateFuture = widget.repository.getUsdKrwRate();
    _historyFuture = widget.repository.getUsdKrwHistory(_selectedRange);
  }

  void _reloadRate() {
    setState(() {
      _rateFuture = widget.repository.getUsdKrwRate();
    });
  }

  void _selectRange(String range) {
    if (range == _selectedRange) return;
    setState(() {
      _selectedRange = range;
      _historyFuture = widget.repository.getUsdKrwHistory(range);
    });
  }

  void _reloadHistory() {
    setState(() {
      _historyFuture = widget.repository.getUsdKrwHistory(_selectedRange);
    });
  }

  String get _rangeCaption => switch (_selectedRange) {
    '1D' => '최근 1일',
    '1W' => '최근 1주',
    _ => '최근 1개월',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: _ink,
                      ),
                      child: const Text(
                        '‹',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'USD/KRW',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: _ExchangeQuote(
                        rateFuture: _rateFuture,
                        onRetry: _reloadRate,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: _periods.entries
                            .map(
                              (period) => Expanded(
                                child: _PeriodTab(
                                  label: period.key,
                                  selected: period.value == _selectedRange,
                                  onPressed: () => _selectRange(period.value),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: _HistoryChartSection(
                        future: _historyFuture,
                        onRetry: _reloadHistory,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _rangeCaption,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 20 / 13,
                            ),
                          ),
                          Text(
                            '1 USD 기준 · 단위: 원',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 34),
          ],
        ),
      ),
    );
  }
}

class _ExchangeQuote extends StatelessWidget {
  const _ExchangeQuote({required this.rateFuture, required this.onRetry});

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

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: selected
              ? const Color(0xFF008A29)
              : const Color(0xFF667069),
          backgroundColor: selected ? const Color(0xFFEAF7EE) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 20 / 13,
          ),
        ),
      ),
    );
  }
}

class _HistoryChartSection extends StatelessWidget {
  const _HistoryChartSection({required this.future, required this.onRetry});

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
