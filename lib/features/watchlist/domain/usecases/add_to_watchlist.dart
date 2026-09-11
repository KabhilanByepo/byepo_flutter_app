import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/watchlist_repository.dart';
import 'watchlist_symbol_params.dart';

/// One business operation: "add this symbol to the watchlist" — deduping is
/// owned entirely by [WatchlistRepository]'s implementation, not here.
class AddToWatchlist implements UseCase<List<String>, WatchlistSymbolParams> {
  final WatchlistRepository repository;

  const AddToWatchlist(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(WatchlistSymbolParams params) {
    return repository.addSymbol(params.symbol);
  }
}
