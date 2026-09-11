import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/stock.dart';
import '../repositories/stock_repository.dart';

/// One business operation: "get the full quote for a single symbol". Kept as
/// its own use case so the details screen works from a deep link with nothing
/// but a symbol in the URL.
class GetStockDetails implements UseCase<Stock, SymbolParams> {
  final StockRepository repository;

  const GetStockDetails(this.repository);

  @override
  Future<Either<Failure, Stock>> call(SymbolParams params) {
    return repository.getStockDetails(params.symbol);
  }
}

class SymbolParams extends Equatable {
  final String symbol;

  const SymbolParams(this.symbol);

  @override
  List<Object?> get props => [symbol];
}
