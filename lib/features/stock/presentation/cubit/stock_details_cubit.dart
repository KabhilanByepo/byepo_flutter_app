import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/stock.dart';
import '../../domain/usecases/get_stock_details.dart';
import 'stock_details_state.dart';

/// Orchestration only: fetches one symbol's full quote and folds the result
/// into a state. Always fetches by symbol so the screen works from a cold deep
/// link (`/stock-details/AAPL`) with no entity passed.
class StockDetailsCubit extends Cubit<StockDetailsState> {
  final GetStockDetails getStockDetails;

  StockDetailsCubit({required this.getStockDetails})
      : super(const StockDetailsInitial());

  Future<void> load(String symbol, {Stock? seed}) async {
    emit(StockDetailsLoading(seed: seed));

    final result = await getStockDetails(SymbolParams(symbol));

    result.fold(
      (failure) => emit(StockDetailsError(failure.message)),
      (stock) => emit(StockDetailsLoaded(stock)),
    );
  }

  /// Silent refresh — a transient failure must not clobber a good
  /// [StockDetailsLoaded] state with an error screen (mirrors
  /// `DashboardCubit`'s silent-refresh convention).
  Future<void> refresh(String symbol) async {
    final result = await getStockDetails(SymbolParams(symbol));

    result.fold(
      (failure) {
        if (state is! StockDetailsLoaded) {
          emit(StockDetailsError(failure.message));
        }
      },
      (stock) => emit(StockDetailsLoaded(stock)),
    );
  }
}
