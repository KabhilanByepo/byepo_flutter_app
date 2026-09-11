import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/stock.dart';
import '../entities/stock_search_result.dart';

/// Domain-owned contract. `StockRepositoryImpl` (data layer) provides the
/// implementation; domain and presentation only depend on this abstraction.
abstract class StockRepository {
  /// Quote + company profile merged into one [Stock] for each symbol.
  Future<Either<Failure, List<Stock>>> getStocks(List<String> symbols);

  /// A single symbol's full quote (used by the details screen / deep links).
  Future<Either<Failure, Stock>> getStockDetails(String symbol);

  /// Server-side symbol search — no quote/profile calls.
  Future<Either<Failure, List<StockSearchResult>>> searchStocks(String query);
}
