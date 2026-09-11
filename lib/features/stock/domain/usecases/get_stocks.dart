import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/stock.dart';
import '../repositories/stock_repository.dart';

/// One business operation: "get quotes for these symbols". Used by the
/// Dashboard (with the curated list) and reusable by any future screen.
class GetStocks implements UseCase<List<Stock>, SymbolsParams> {
  final StockRepository repository;

  const GetStocks(this.repository);

  @override
  Future<Either<Failure, List<Stock>>> call(SymbolsParams params) {
    return repository.getStocks(params.symbols);
  }
}

class SymbolsParams extends Equatable {
  final List<String> symbols;

  const SymbolsParams(this.symbols);

  @override
  List<Object?> get props => [symbols];
}
