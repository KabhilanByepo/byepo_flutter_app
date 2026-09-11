import 'package:equatable/equatable.dart';

/// Business object for a single stock quote.
///
/// Pure Dart — no `fromJson`, no dependency on `dio` or the data layer. It is
/// assembled by the repository from two Finnhub calls (`/quote` +
/// `/stock/profile2`); the presentation layer only ever sees this.
class Stock extends Equatable {
  final String symbol;
  final String companyName;
  final String logoUrl;

  /// Last traded price.
  final double ltp;
  final double change;
  final double changePercent;

  // Extra quote data shown on the details screen.
  final double open;
  final double high;
  final double low;
  final double previousClose;
  final String exchange;
  final String industry;
  final double marketCap;
  final String currency;

  const Stock({
    required this.symbol,
    required this.companyName,
    required this.logoUrl,
    required this.ltp,
    required this.change,
    required this.changePercent,
    required this.open,
    required this.high,
    required this.low,
    required this.previousClose,
    required this.exchange,
    required this.industry,
    required this.marketCap,
    required this.currency,
  });

  bool get isUp => change >= 0;

  @override
  List<Object?> get props => [
        symbol,
        companyName,
        logoUrl,
        ltp,
        change,
        changePercent,
        open,
        high,
        low,
        previousClose,
        exchange,
        industry,
        marketCap,
        currency,
      ];
}
