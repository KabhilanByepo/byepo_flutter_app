import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/watchlist_repository.dart';
import '../datasources/watchlist_local_data_source.dart';

/// Implements the domain contract. This is the ONLY place that owns
/// add/remove/dedupe logic for the watchlist — the cubit and every screen
/// only ever reach it through the domain use cases.
class WatchlistRepositoryImpl implements WatchlistRepository {
  final WatchlistLocalDataSource localDataSource;

  const WatchlistRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<String>>> getWatchlist() {
    return _guard(() => localDataSource.getSymbols());
  }

  @override
  Future<Either<Failure, List<String>>> addSymbol(String symbol) {
    return _guard(() async {
      final current = await localDataSource.getSymbols();
      final normalized = symbol.trim().toUpperCase();
      if (current.contains(normalized)) return current; // dedupe: no-op
      final updated = [...current, normalized];
      await localDataSource.saveSymbols(updated);
      return updated;
    });
  }

  @override
  Future<Either<Failure, List<String>>> removeSymbol(String symbol) {
    return _guard(() async {
      final current = await localDataSource.getSymbols();
      final normalized = symbol.trim().toUpperCase();
      if (!current.contains(normalized)) return current; // already gone
      final updated = current.where((s) => s != normalized).toList();
      await localDataSource.saveSymbols(updated);
      return updated;
    });
  }

  /// The single exception -> Failure seam, mirroring `StockRepositoryImpl`'s
  /// `_guard`. Local storage has no server/network exception vocabulary of
  /// its own, so any failure here is a cache failure.
  Future<Either<Failure, List<String>>> _guard(
    Future<List<String>> Function() run,
  ) async {
    try {
      return Right(await run());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
