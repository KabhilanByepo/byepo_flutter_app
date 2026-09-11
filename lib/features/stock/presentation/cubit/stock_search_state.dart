import 'package:equatable/equatable.dart';

import '../../domain/entities/stock_search_result.dart';

/// Exhaustive search states. `Initial` = no active query (show the Dashboard
/// list instead); `Empty` = a query that matched nothing.
sealed class StockSearchState extends Equatable {
  const StockSearchState();

  @override
  List<Object?> get props => [];
}

class StockSearchInitial extends StockSearchState {
  const StockSearchInitial();
}

class StockSearchLoading extends StockSearchState {
  const StockSearchLoading();
}

class StockSearchLoaded extends StockSearchState {
  final List<StockSearchResult> results;

  const StockSearchLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class StockSearchEmpty extends StockSearchState {
  const StockSearchEmpty();
}

class StockSearchError extends StockSearchState {
  final String message;

  const StockSearchError(this.message);

  @override
  List<Object?> get props => [message];
}
