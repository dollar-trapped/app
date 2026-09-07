import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'my_page.dart';
import 'usd_room_page.dart';

class UsdKrwPage extends StatefulWidget {
  const UsdKrwPage({super.key});

  @override
  State<UsdKrwPage> createState() => _UsdKrwPageState();
}

class _UsdKrwPageState extends State<UsdKrwPage> {
  final _pageController = PageController(initialPage: 1);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      children: [
        MyPage(
          onBack: () => _pageController.animateToPage(
            1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
        ),
        const _UsdKrwDetailPage(),
        UsdRoomPage(
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
  const _UsdKrwDetailPage();

  @override
  State<_UsdKrwDetailPage> createState() => _UsdKrwDetailPageState();
}

class _UsdKrwDetailPageState extends State<_UsdKrwDetailPage> {
  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _periods = ['1일', '5일', '1개월', '1년', '5년', '최대'];
  var _selectedPeriod = '1개월';

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
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: _ExchangeQuote(),
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
  const _ExchangeQuote();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '미국 달러 / 대한민국 원',
          style: TextStyle(
            color: Color(0xFF667069),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 20 / 13,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '1,346.09원',
          style: TextStyle(
            color: Color(0xFF151916),
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 46 / 36,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '▼ 8.31 (−0.61%)  전일 대비',
          style: TextStyle(
            color: Color(0xFF2463B5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 20 / 13,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '9월 6일 09:18 UTC 기준',
          style: TextStyle(color: Color(0xFF667069), fontSize: 12, height: 1.5),
        ),
      ],
    );
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
