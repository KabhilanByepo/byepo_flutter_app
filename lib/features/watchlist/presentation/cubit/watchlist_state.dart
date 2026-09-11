import 'package:equatable/equatable.dart';

/// Pure membership state — this cubit is a lookup service consumed by star
/// toggles on multiple screens, not a directly rendered list, so an empty
/// symbol set is just its normal starting condition, not a distinct `Empty`
/// state the way an empty *rendered* list would be (see `WatchlistStocksState`
/// for that).
sealed class WatchlistState extends Equatable {
  const WatchlistState();

  @override
  List<Object?> get props => [];
}

class WatchlistInitial extends WatchlistState {
  const WatchlistInitial();
}

class WatchlistLoading extends WatchlistState {
  const WatchlistLoading();
}

class WatchlistLoaded extends WatchlistState {
  final List<String> symbols;

  const WatchlistLoaded(this.symbols);

  @override
  List<Object?> get props => [symbols];
}

class WatchlistError extends WatchlistState {
  final String message;

  const WatchlistError(this.message);

  @override
  List<Object?> get props => [message];
}
