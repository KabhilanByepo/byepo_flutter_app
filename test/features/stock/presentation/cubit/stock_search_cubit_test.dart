import 'package:bloc_test/bloc_test.dart';
import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/features/stock/domain/entities/stock_search_result.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/search_stocks.dart';
import 'package:byepo_stock_market/features/stock/presentation/cubit/stock_search_cubit.dart';
import 'package:byepo_stock_market/features/stock/presentation/cubit/stock_search_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchStocks extends Mock implements SearchStocks {}

const _tResult = StockSearchResult(
  symbol: 'AAPL',
  description: 'APPLE INC',
  displaySymbol: 'AAPL',
  type: 'Common Stock',
);

const _debounceWait = Duration(milliseconds: 450);

void main() {
  late MockSearchStocks searchStocks;

  setUpAll(() => registerFallbackValue(const QueryParams('')));

  setUp(() => searchStocks = MockSearchStocks());

  blocTest<StockSearchCubit, StockSearchState>(
    'a query emits [Loading, Loaded] after the debounce',
    build: () => StockSearchCubit(searchStocks: searchStocks),
    setUp: () => when(() => searchStocks(any()))
        .thenAnswer((_) async => const Right([_tResult])),
    act: (cubit) => cubit.search('app'),
    wait: _debounceWait,
    expect: () => const [
      StockSearchLoading(),
      StockSearchLoaded([_tResult]),
    ],
  );

  blocTest<StockSearchCubit, StockSearchState>(
    'a query with no matches emits [Loading, Empty]',
    build: () => StockSearchCubit(searchStocks: searchStocks),
    setUp: () => when(() => searchStocks(any()))
        .thenAnswer((_) async => const Right(<StockSearchResult>[])),
    act: (cubit) => cubit.search('zzz'),
    wait: _debounceWait,
    expect: () => const [StockSearchLoading(), StockSearchEmpty()],
  );

  blocTest<StockSearchCubit, StockSearchState>(
    'a query failure emits [Loading, Error]',
    build: () => StockSearchCubit(searchStocks: searchStocks),
    setUp: () => when(() => searchStocks(any()))
        .thenAnswer((_) async => const Left(ServerFailure('boom'))),
    act: (cubit) => cubit.search('app'),
    wait: _debounceWait,
    expect: () => const [StockSearchLoading(), StockSearchError('boom')],
  );

  blocTest<StockSearchCubit, StockSearchState>(
    'clear() after results resets to Initial',
    build: () => StockSearchCubit(searchStocks: searchStocks),
    seed: () => const StockSearchLoaded([_tResult]),
    act: (cubit) => cubit.clear(),
    expect: () => const [StockSearchInitial()],
  );
}
