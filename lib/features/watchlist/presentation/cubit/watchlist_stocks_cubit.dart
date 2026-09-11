import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../stock/domain/usecases/get_stocks.dart';
import 'watchlist_cubit.dart';
import 'watchlist_state.dart';
import 'watchlist_stocks_state.dart';

/// Fetches full [Stock] data (price, change, …) for whatever symbols
/// [watchlistCubit] currently reports — reusing the existing [GetStocks] use
/// case (the same one `DashboardCubit` uses) instead of duplicating any
/// fetch/parsing logic for this screen.
class WatchlistStocksCubit extends Cubit<WatchlistStocksState> {
  final GetStocks getStocks;
  final WatchlistCubit watchlistCubit;

  StreamSubscription<WatchlistState>? _subscription;

  WatchlistStocksCubit({required this.getStocks, required this.watchlistCubit})
      : super(const WatchlistStocksInitial()) {
    _subscription = watchlistCubit.stream.listen(_onWatchlistChanged);
  }

  /// Call once from `WatchlistPage.initState()`.
  Future<void> load() async {
    final membership = watchlistCubit.state;
    if (membership is WatchlistLoaded) {
      await _fetchFor(membership.symbols);
    } else {
      emit(const WatchlistStocksLoading());
      // `watchlistCubit.stream` doesn't replay the current value to a late
      // subscriber, so read `.state` above first; this covers the case where
      // it hasn't loaded yet at all (`_onWatchlistChanged` picks up the
      // eventual `Loaded` emission below).
      await watchlistCubit.load();
    }
  }

  /// Silent refresh (app resume / connectivity restored) — keeps the
  /// current list on screen instead of flashing a spinner or an error over
  /// a transient failure, mirroring `DashboardCubit._fetch({silent: true})`.
  Future<void> refresh() async {
    final membership = watchlistCubit.state;
    if (membership is WatchlistLoaded) {
      await _fetchFor(membership.symbols, silent: true);
    }
  }

  void _onWatchlistChanged(WatchlistState membership) {
    if (membership is WatchlistLoaded) _fetchFor(membership.symbols);
  }

  Future<void> _fetchFor(List<String> symbols, {bool silent = false}) async {
    if (symbols.isEmpty) {
      emit(const WatchlistStocksEmpty());
      return;
    }
    if (!silent || state is! WatchlistStocksLoaded) {
      emit(const WatchlistStocksLoading());
    }
    final result = await getStocks(SymbolsParams(symbols));
    result.fold(
      (failure) {
        if (!silent || state is! WatchlistStocksLoaded) {
          emit(WatchlistStocksError(failure.message));
        }
      },
      (stocks) => emit(WatchlistStocksLoaded(stocks)),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
