import 'dart:async';
import 'package:dollar_trapped/features/ads/widgets/adaptive_banner.dart';
import 'package:dollar_trapped/features/exchange/widgets/exchange_quote.dart';
import 'package:dollar_trapped/features/exchange/widgets/period_tab.dart';
import 'package:dollar_trapped/features/exchange/widgets/history_chart.dart';
import 'package:flutter/material.dart';
import 'package:dollar_trapped/features/shared/data/api_models.dart';
import 'package:dollar_trapped/features/shared/data/dollar_repository.dart';

class UsdKrwDetailPage extends StatefulWidget {
  const UsdKrwDetailPage({super.key, required this.repository});

  final DollarRepository repository;

  @override
  State<UsdKrwDetailPage> createState() => _UsdKrwDetailPageState();
}

class _UsdKrwDetailPageState extends State<UsdKrwDetailPage>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  static const _ink = Color(0xFF151916);
  static const _muted = Color(0xFF667069);
  static const _periods = {'1일': '1D', '1주': '1W', '1개월': '1M'};
  var _selectedRange = '1M';
  late Future<ExchangeRate> _rateFuture;
  late Future<ExchangeRateHistory> _historyFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _refreshQuoteAndHistory(),
    );
    _rateFuture = widget.repository.getUsdKrwRate();
    _historyFuture = widget.repository.getUsdKrwHistory(_selectedRange);
  }

  void _refreshQuoteAndHistory() {
    if (!mounted) return;
    setState(() {
      _rateFuture = widget.repository.getUsdKrwRate();
      _historyFuture = widget.repository.getUsdKrwHistory(_selectedRange);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshQuoteAndHistory();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
                      child: ExchangeQuote(
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
                                child: PeriodTab(
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
                      child: HistoryChartSection(
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
            const SafeArea(top: false, child: AdaptiveBanner()),
          ],
        ),
      ),
    );
  }
}
