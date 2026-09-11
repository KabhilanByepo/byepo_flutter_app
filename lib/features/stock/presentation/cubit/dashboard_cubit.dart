import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/curated_symbols.dart';
import '../../domain/usecases/get_stocks.dart';
import 'dashboard_state.dart';

/// Orchestration only: calls [GetStocks], folds the result into a state, and
/// owns the one lifecycle resource this screen needs — the periodic refresh
/// timer. No Dio, no JSON, no error-mapping here.
class DashboardCubit extends Cubit<DashboardState> {
  final GetStocks getStocks;

  static const Duration _refreshInterval = Duration(seconds: 30);

  Timer? _timer;
  bool _inFlight = false;

  /// The user's on/off intent, distinct from whether [_timer] currently
  /// exists — backgrounding stops the timer via [pauseForBackground] without
  /// the user having touched the toggle, so this must not silently flip.
  bool _autoRefreshEnabled = false;

  DashboardCubit({required this.getStocks}) : super(const DashboardInitial());

  bool get isAutoRefreshing => _autoRefreshEnabled;

  /// First load — shows the full-screen spinner path.
  Future<void> load() async {
    emit(const DashboardLoading());
    await _fetch(silent: false);
  }

  /// Pull-to-refresh — the `RefreshIndicator` shows its own spinner, so keep the
  /// current list on screen and don't flip to an error over a transient blip.
  Future<void> refresh() => _fetch(silent: true);

  void toggleAutoRefresh() {
    _autoRefreshEnabled = !_autoRefreshEnabled;
    if (_autoRefreshEnabled) {
      _startTimer();
    } else {
      _stopTimer();
    }
    final current = state;
    if (current is DashboardLoaded) {
      emit(DashboardLoaded(current.stocks, autoRefreshing: _autoRefreshEnabled));
    }
  }

  /// Called when the app backgrounds — stops the periodic timer so it
  /// doesn't keep polling Finnhub's rate-limited free tier while nothing is
  /// on screen. Leaves [_autoRefreshEnabled] (the user's toggle choice)
  /// untouched.
  void pauseForBackground() => _stopTimer();

  /// Called when the app foregrounds (or connectivity returns) — restarts
  /// the timer if the user had it on, and does one silent refresh right
  /// away (guarded by [_inFlight] like any other refresh, so it can never
  /// stack with a timer tick).
  void resumeForForeground() {
    if (_autoRefreshEnabled) _startTimer();
    refresh();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_refreshInterval, (_) => _fetch(silent: true));
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetch({required bool silent}) async {
    if (_inFlight) return; // don't stack a timer tick on an in-progress fetch
    _inFlight = true;
    try {
      final result = await getStocks(const SymbolsParams(kDashboardSymbols));
      result.fold(
        (failure) {
          if (!silent || state is! DashboardLoaded) {
            emit(DashboardError(failure.message));
          }
        },
        (stocks) => emit(
          stocks.isEmpty
              ? const DashboardEmpty()
              : DashboardLoaded(stocks, autoRefreshing: _autoRefreshEnabled),
        ),
      );
    } finally {
      _inFlight = false;
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
