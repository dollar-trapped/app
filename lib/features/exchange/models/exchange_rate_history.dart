import 'package:dollar_trapped/features/shared/data/json_helpers.dart';
import 'package:dollar_trapped/features/exchange/models/exchange_rate_point.dart';

class ExchangeRateHistory {
  const ExchangeRateHistory({
    required this.pair,
    required this.range,
    required this.interval,
    required this.from,
    required this.to,
    required this.points,
    required this.isPartial,
  });
  final String pair, range, interval;
  final DateTime from, to;
  final List<ExchangeRatePoint> points;
  final bool isPartial;
  factory ExchangeRateHistory.fromJson(Json json) {
    // Keep every chart consumer independent from the server's delivery order.
    final points =
        (json['points'] as List)
            .map((item) => ExchangeRatePoint.fromJson(Json.from(item as Map)))
            .toList()
          ..sort((left, right) => left.time.compareTo(right.time));
    return ExchangeRateHistory(
      pair: json['pair'] as String,
      range: json['range'] as String,
      interval: json['interval'] as String,
      from: jsonDate(json, 'from'),
      to: jsonDate(json, 'to'),
      points: points,
      isPartial: json['isPartial'] as bool,
    );
  }
}
