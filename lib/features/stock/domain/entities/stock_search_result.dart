import 'package:equatable/equatable.dart';

/// A lightweight symbol-search hit from Finnhub's `/search` endpoint.
///
/// Deliberately holds no price data — search returns dozens of matches and
/// fetching a quote + profile for each would blow the rate limit. Tapping a
/// result navigates to the details screen, which does the full fetch by symbol.
class StockSearchResult extends Equatable {
  final String symbol;
  final String description;
  final String displaySymbol;
  final String type;

  const StockSearchResult({
    required this.symbol,
    required this.description,
    required this.displaySymbol,
    required this.type,
  });

  @override
  List<Object?> get props => [symbol, description, displaySymbol, type];
}
