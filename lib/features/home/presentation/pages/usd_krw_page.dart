import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  static const _periods = ['1일', '5일', '1개월', '1년', '5년', '최대'];
  var _selectedPeriod = '1개월';
  late Future<ExchangeRate> _rateFuture;

  @override
  void initState() {
    super.initState();
    _rateFuture = widget.repository.getUsdKrwRate();
  }

  void _reloadRate() {
    setState(() {
      _rateFuture = widget.repository.getUsdKrwRate();
    });
  }

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
                        children: _periods
                            .map(
                              (period) => Expanded(
                                child: _PeriodTab(
                                  label: period,
                                  selected: period == _selectedPeriod,
                                  onPressed: () =>
                                      setState(() => _selectedPeriod = period),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: _StaticPriceChart(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '최근 1개월',
                            style: TextStyle(
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

class _StaticPriceChart extends StatelessWidget {
  const _StaticPriceChart();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          height: 266,
          child: Stack(
            children: [
              Positioned(
                top: 20,
                left: 0,
                width: 296,
                height: 240,
                child: SvgPicture.asset(
                  'assets/images/usd_krw_price_grid.svg',
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: 21,
                left: 0,
                width: 292,
                height: 221,
                child: SvgPicture.asset(
                  'assets/images/usd_krw_month_sample.svg',
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                top: 239,
                left: 289,
                width: 6,
                height: 6,
                child: SvgPicture.asset(
                  'assets/images/usd_krw_latest_point.svg',
                ),
              ),
              const _ChartValue('1,420', 11),
              const _ChartValue('1,400', 71),
              const _ChartValue('1,380', 131),
              const _ChartValue('1,360', 191),
              const _ChartValue('1,340', 251),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(
          width: 296,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '8.7',
                style: TextStyle(
                  color: Color(0xFF667069),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              Text(
                '8.17',
                style: TextStyle(
                  color: Color(0xFF667069),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              Text(
                '8.27',
                style: TextStyle(
                  color: Color(0xFF667069),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              Text(
                '9.6',
                style: TextStyle(
                  color: Color(0xFF667069),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartValue extends StatelessWidget {
  const _ChartValue(this.label, this.top);
  final String label;
  final double top;

  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    left: 310,
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF667069),
        fontSize: 12,
        height: 1.5,
      ),
    ),
  );
}
