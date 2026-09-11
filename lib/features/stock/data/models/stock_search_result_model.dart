import '../../../../core/error/exceptions.dart';
import '../../domain/entities/stock_search_result.dart';

/// Data-layer representation of one item in Finnhub's `/search` ->
/// `result[]`.
///
/// ```json
/// { "symbol": "AAPL", "description": "APPLE INC", "displaySymbol": "AAPL",
///   "type": "Common Stock" }
/// ```
class StockSearchResultModel extends StockSearchResult {
  const StockSearchResultModel({
    required super.symbol,
    required super.description,
    required super.displaySymbol,
    required super.type,
  });

  factory StockSearchResultModel.fromJson(Map<String, dynamic> json) {
    final symbol = json['symbol'];
    final description = json['description'];

    if (symbol is! String || description is! String) {
      throw const ServerException('Malformed search payload from server');
    }

    final displaySymbol = json['displaySymbol'];
    final type = json['type'];

    return StockSearchResultModel(
      symbol: symbol,
      description: description,
      displaySymbol: displaySymbol is String ? displaySymbol : symbol,
      type: type is String ? type : '',
    );
  }
}
