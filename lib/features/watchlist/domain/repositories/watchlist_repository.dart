import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

/// Domain-owned contract. `WatchlistRepositoryImpl` (data layer) provides the
/// implementation; domain and presentation only depend on this abstraction.
///
/// A watched symbol is just a bare `String` (no wrapper entity) — the same
/// level of abstraction `SymbolParams`/`SymbolsParams` already use elsewhere.
abstract class WatchlistRepository {
  /// All watched symbols, oldest-added first. An empty list means nothing
  /// has been added yet — a normal state, not an error.
  Future<Either<Failure, List<String>>> getWatchlist();

  /// Adds [symbol] if not already present (case-insensitive); a no-op that
  /// still returns `Right(current list)` if it already is. Returns the
  /// resulting list either way.
  Future<Either<Failure, List<String>>> addSymbol(String symbol);

  /// Removes [symbol] if present; a no-op (still `Right`) if it isn't.
  /// Returns the resulting list.
  Future<Either<Failure, List<String>>> removeSymbol(String symbol);
}
