import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/stock_search_result.dart';
import '../repositories/stock_repository.dart';

/// One business operation: "search for symbols matching a query".
class SearchStocks implements UseCase<List<StockSearchResult>, QueryParams> {
  final StockRepository repository;

  const SearchStocks(this.repository);

  @override
  Future<Either<Failure, List<StockSearchResult>>> call(QueryParams params) {
    return repository.searchStocks(params.query);
  }
}

class QueryParams extends Equatable {
  final String query;

  const QueryParams(this.query);

  @override
  List<Object?> get props => [query];
}
