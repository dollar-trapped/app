import 'package:dollar_trapped/features/shared/data/json_helpers.dart';

class ExchangeRatePoint {
  const ExchangeRatePoint({
    required this.time,
    required this.rate,
    required this.asOf,
    required this.source,
  });
  final DateTime time, asOf;
  final String rate, source;
  factory ExchangeRatePoint.fromJson(Json json) => ExchangeRatePoint(
    time: jsonDate(json, 'time'),
    rate: json['rate'] as String,
    asOf: jsonDate(json, 'asOf'),
    source: json['source'] as String,
  );
}
