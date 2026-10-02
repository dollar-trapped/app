import 'package:dollar_trapped/features/shared/data/json_helpers.dart';

class ExchangeRate {
  const ExchangeRate({
    required this.pair,
    required this.rate,
    required this.asOf,
    required this.fetchedAt,
    required this.source,
    required this.marketStatus,
    required this.isStale,
    this.previousCloseRate,
    this.previousCloseAsOf,
  });
  final String pair, rate, source, marketStatus;
  final DateTime asOf, fetchedAt;
  final bool isStale;

  /// Previous trading day close, supplied by the server for day comparison.
  final String? previousCloseRate;

  /// Actual observation time of the previous close; not the session cutoff.
  final DateTime? previousCloseAsOf;
  factory ExchangeRate.fromJson(Json json) => ExchangeRate(
    pair: json['pair'] as String,
    rate: json['rate'] as String,
    asOf: jsonDate(json, 'asOf'),
    fetchedAt: jsonDate(json, 'fetchedAt'),
    source: json['source'] as String,
    marketStatus: json['marketStatus'] as String,
    isStale: json['isStale'] as bool,
    previousCloseRate: json['previousCloseRate']?.toString(),
    previousCloseAsOf: json['previousCloseAsOf'] == null
        ? null
        : DateTime.tryParse(json['previousCloseAsOf'].toString()),
  );
}
