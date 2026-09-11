import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/watchlist_repository.dart';

/// One business operation: "get every symbol currently on the watchlist".
class GetWatchlist implements UseCase<List<String>, NoParams> {
  final WatchlistRepository repository;

  const GetWatchlist(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(NoParams params) {
    return repository.getWatchlist();
  }
}
