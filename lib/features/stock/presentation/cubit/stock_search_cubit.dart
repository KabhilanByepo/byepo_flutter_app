import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/search_stocks.dart';
import 'stock_search_state.dart';

/// Debounced server-side symbol search. Every keystroke calls [search]; the
/// actual API call only fires after the user pauses, and a blank query resets
/// to [StockSearchInitial] so the Dashboard shows its curated list again.
class StockSearchCubit extends Cubit<StockSearchState> {
  final SearchStocks searchStocks;

  static const Duration _debounce = Duration(milliseconds: 350);

  Timer? _debounceTimer;

  StockSearchCubit({required this.searchStocks})
      : super(const StockSearchInitial());

  void search(String query) {
    _debounceTimer?.cancel();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      emit(const StockSearchInitial());
      return;
    }

    _debounceTimer = Timer(_debounce, () => _run(trimmed));
  }

  void clear() {
    _debounceTimer?.cancel();
    emit(const StockSearchInitial());
  }

  Future<void> _run(String query) async {
    emit(const StockSearchLoading());

    final result = await searchStocks(QueryParams(query));

    result.fold(
      (failure) => emit(StockSearchError(failure.message)),
      (results) => emit(
        results.isEmpty ? const StockSearchEmpty() : StockSearchLoaded(results),
      ),
    );
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
