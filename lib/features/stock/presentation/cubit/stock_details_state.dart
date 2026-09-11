import 'package:equatable/equatable.dart';

import '../../domain/entities/stock.dart';

/// Exhaustive details states. No `Empty` — a single symbol either resolves to a
/// [Stock] or it errors. `Loading` optionally carries a [seed] (the entity a
/// tapped Dashboard card passed along) so the screen can render immediately
/// while the full quote refreshes.
sealed class StockDetailsState extends Equatable {
  const StockDetailsState();

  @override
  List<Object?> get props => [];
}

class StockDetailsInitial extends StockDetailsState {
  const StockDetailsInitial();
}

class StockDetailsLoading extends StockDetailsState {
  final Stock? seed;

  const StockDetailsLoading({this.seed});

  @override
  List<Object?> get props => [seed];
}

class StockDetailsLoaded extends StockDetailsState {
  final Stock stock;

  const StockDetailsLoaded(this.stock);

  @override
  List<Object?> get props => [stock];
}

class StockDetailsError extends StockDetailsState {
  final String message;

  const StockDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
