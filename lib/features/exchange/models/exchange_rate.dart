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
  });
  final String pair, rate, source, marketStatus;
  final DateTime asOf, fetchedAt;
  final bool isStale;
  factory ExchangeRate.fromJson(Json json) => ExchangeRate(
    pair: json['pair'] as String,
    rate: json['rate'] as String,
    asOf: jsonDate(json, 'asOf'),
    fetchedAt: jsonDate(json, 'fetchedAt'),
    source: json['source'] as String,
    marketStatus: json['marketStatus'] as String,
    isStale: json['isStale'] as bool,
  );
}
