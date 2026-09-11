import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/add_to_watchlist.dart';
import '../../domain/usecases/get_watchlist.dart';
import '../../domain/usecases/remove_from_watchlist.dart';
import '../../domain/usecases/watchlist_symbol_params.dart';
import 'watchlist_state.dart';

/// The single source of truth for watchlist membership. Registered as a
/// `get_it` singleton and provided to Dashboard, Details, and Watchlist via
/// `BlocProvider.value` — never `create:` — so all three screens observe the
/// exact same instance and never disagree about what's on the watchlist.
///
/// Owns no persistence logic itself: every mutation goes through the use
/// cases, which go through `WatchlistRepositoryImpl` (the one place
/// add/remove/dedupe actually lives).
class WatchlistCubit extends Cubit<WatchlistState> {
  final GetWatchlist getWatchlist;
  final AddToWatchlist addToWatchlist;
  final RemoveFromWatchlist removeFromWatchlist;

  WatchlistCubit({
    required this.getWatchlist,
    required this.addToWatchlist,
    required this.removeFromWatchlist,
  }) : super(const WatchlistInitial());

  /// Triggered once at app start (see `main.dart`) — no single screen owns
  /// the first load, since any of the three tabs/routes could open first.
  Future<void> load() async {
    emit(const WatchlistLoading());
    final result = await getWatchlist(const NoParams());
    result.fold(
      (failure) => emit(WatchlistError(failure.message)),
      (symbols) => emit(WatchlistLoaded(symbols)),
    );
  }

  bool contains(String symbol) {
    final current = state;
    return current is WatchlistLoaded &&
        current.symbols.contains(symbol.trim().toUpperCase());
  }

  Future<void> add(String symbol) async {
    final result = await addToWatchlist(WatchlistSymbolParams(symbol));
    result.fold(
      (failure) => emit(WatchlistError(failure.message)),
      (symbols) => emit(WatchlistLoaded(symbols)),
    );
  }

  Future<void> remove(String symbol) async {
    final result = await removeFromWatchlist(WatchlistSymbolParams(symbol));
    result.fold(
      (failure) => emit(WatchlistError(failure.message)),
      (symbols) => emit(WatchlistLoaded(symbols)),
    );
  }
}
