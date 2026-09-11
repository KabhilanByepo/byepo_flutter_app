import 'package:equatable/equatable.dart';

/// Shared param type for [AddToWatchlist] and [RemoveFromWatchlist] — kept in
/// one file so both use cases can be imported together without colliding
/// with the stock feature's own `SymbolParams`/`SymbolsParams`.
class WatchlistSymbolParams extends Equatable {
  final String symbol;

  const WatchlistSymbolParams(this.symbol);

  @override
  List<Object?> get props => [symbol];
}
