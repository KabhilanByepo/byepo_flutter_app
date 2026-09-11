import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/watchlist_repository.dart';
import 'watchlist_symbol_params.dart';

/// One business operation: "remove this symbol from the watchlist" — a
/// no-op (still `Right`) if the symbol isn't on it.
class RemoveFromWatchlist
    implements UseCase<List<String>, WatchlistSymbolParams> {
  final WatchlistRepository repository;

  const RemoveFromWatchlist(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(WatchlistSymbolParams params) {
    return repository.removeSymbol(params.symbol);
  }
}
