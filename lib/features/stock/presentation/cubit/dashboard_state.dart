import 'package:equatable/equatable.dart';

import '../../domain/entities/stock.dart';

/// Exhaustive Dashboard states — the UI renders each distinctly, with `Empty`
/// as its own state (never "Loaded with an empty list").
sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<Stock> stocks;

  /// Whether the periodic background refresh is currently running.
  final bool autoRefreshing;

  const DashboardLoaded(this.stocks, {this.autoRefreshing = false});

  @override
  List<Object?> get props => [stocks, autoRefreshing];
}

class DashboardEmpty extends DashboardState {
  const DashboardEmpty();
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
