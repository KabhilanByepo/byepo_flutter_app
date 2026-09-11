import 'package:equatable/equatable.dart';

import '../../../stock/domain/entities/stock.dart';

/// Exhaustive states for rendering the Watchlist screen's stock list —
/// same shape as `DashboardState`, with `Empty` as its own state (never
/// "Loaded with an empty list").
sealed class WatchlistStocksState extends Equatable {
  const WatchlistStocksState();

  @override
  List<Object?> get props => [];
}

class WatchlistStocksInitial extends WatchlistStocksState {
  const WatchlistStocksInitial();
}

class WatchlistStocksLoading extends WatchlistStocksState {
  const WatchlistStocksLoading();
}

class WatchlistStocksLoaded extends WatchlistStocksState {
  final List<Stock> stocks;

  const WatchlistStocksLoaded(this.stocks);

  @override
  List<Object?> get props => [stocks];
}

class WatchlistStocksEmpty extends WatchlistStocksState {
  const WatchlistStocksEmpty();
}

class WatchlistStocksError extends WatchlistStocksState {
  final String message;

  const WatchlistStocksError(this.message);

  @override
  List<Object?> get props => [message];
}
