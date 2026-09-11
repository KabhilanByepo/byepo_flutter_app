import 'package:bloc_test/bloc_test.dart';
import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/core/usecase/usecase.dart';
import 'package:byepo_stock_market/features/stock/domain/entities/stock.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/get_stocks.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/add_to_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/get_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/remove_from_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/watchlist_symbol_params.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_cubit.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_stocks_cubit.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_stocks_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetStocks extends Mock implements GetStocks {}

class MockGetWatchlist extends Mock implements GetWatchlist {}

class MockAddToWatchlist extends Mock implements AddToWatchlist {}

class MockRemoveFromWatchlist extends Mock implements RemoveFromWatchlist {}

Stock _stock(String symbol) => Stock(
      symbol: symbol,
      companyName: '$symbol Inc',
      logoUrl: '',
      ltp: 10,
      change: 1,
      changePercent: 1,
      open: 9,
      high: 11,
      low: 9,
      previousClose: 9,
      exchange: 'NASDAQ',
      industry: 'Tech',
      marketCap: 1,
      currency: 'USD',
    );

final _tAapl = _stock('AAPL');
final _tMsft = _stock('MSFT');

void main() {
  late MockGetStocks getStocks;
  late MockGetWatchlist getWatchlistUseCase;
  late MockAddToWatchlist addToWatchlist;
  late MockRemoveFromWatchlist removeFromWatchlist;
  late WatchlistCubit watchlistCubit;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const WatchlistSymbolParams(''));
    registerFallbackValue(const SymbolsParams([]));
  });

  setUp(() {
    getStocks = MockGetStocks();
    getWatchlistUseCase = MockGetWatchlist();
    addToWatchlist = MockAddToWatchlist();
    removeFromWatchlist = MockRemoveFromWatchlist();
    watchlistCubit = WatchlistCubit(
      getWatchlist: getWatchlistUseCase,
      addToWatchlist: addToWatchlist,
      removeFromWatchlist: removeFromWatchlist,
    );
  });

  tearDown(() => watchlistCubit.close());

  blocTest<WatchlistStocksCubit, WatchlistStocksState>(
    'membership already Loaded -> load() fetches stocks for it',
    setUp: () async {
      when(() => getWatchlistUseCase(any()))
          .thenAnswer((_) async => const Right(['AAPL']));
      when(() => getStocks(const SymbolsParams(['AAPL'])))
          .thenAnswer((_) async => Right([_tAapl]));
      await watchlistCubit.load();
    },
    build: () =>
        WatchlistStocksCubit(getStocks: getStocks, watchlistCubit: watchlistCubit),
    act: (cubit) => cubit.load(),
    expect: () => [
      const WatchlistStocksLoading(),
      WatchlistStocksLoaded([_tAapl]),
    ],
  );

  blocTest<WatchlistStocksCubit, WatchlistStocksState>(
    'membership still Initial -> load() triggers watchlistCubit.load() '
    'and then reacts to it',
    setUp: () {
      when(() => getWatchlistUseCase(any()))
          .thenAnswer((_) async => const Right(['AAPL']));
      when(() => getStocks(const SymbolsParams(['AAPL'])))
          .thenAnswer((_) async => Right([_tAapl]));
    },
    build: () =>
        WatchlistStocksCubit(getStocks: getStocks, watchlistCubit: watchlistCubit),
    act: (cubit) => cubit.load(),
    // Cubit skips a re-emitted state equal to the current one, so the
    // Loading emitted by load()'s else-branch and the one emitted by
    // _fetchFor once membership resolves collapse into a single state.
    expect: () => [
      const WatchlistStocksLoading(),
      WatchlistStocksLoaded([_tAapl]),
    ],
  );

  blocTest<WatchlistStocksCubit, WatchlistStocksState>(
    'reacts to a later watchlist change without an explicit load() call',
    setUp: () async {
      when(() => getWatchlistUseCase(any()))
          .thenAnswer((_) async => const Right(['AAPL']));
      when(() => addToWatchlist(any()))
          .thenAnswer((_) async => const Right(['AAPL', 'MSFT']));
      when(() => getStocks(const SymbolsParams(['AAPL'])))
          .thenAnswer((_) async => Right([_tAapl]));
      when(() => getStocks(const SymbolsParams(['AAPL', 'MSFT'])))
          .thenAnswer((_) async => Right([_tAapl, _tMsft]));
      await watchlistCubit.load();
    },
    build: () =>
        WatchlistStocksCubit(getStocks: getStocks, watchlistCubit: watchlistCubit),
    // First resolve the initial load (Loading -> Loaded), then mutate the
    // shared membership cubit directly — proving the reactive subscription
    // re-fetches on its own, with no explicit load() call for this part.
    act: (cubit) async {
      await cubit.load();
      await watchlistCubit.add('MSFT');
    },
    expect: () => [
      const WatchlistStocksLoading(),
      WatchlistStocksLoaded([_tAapl]),
      const WatchlistStocksLoading(),
      WatchlistStocksLoaded([_tAapl, _tMsft]),
    ],
  );

  blocTest<WatchlistStocksCubit, WatchlistStocksState>(
    'an empty watchlist emits Empty without calling GetStocks',
    setUp: () async {
      when(() => getWatchlistUseCase(any()))
          .thenAnswer((_) async => const Right(<String>[]));
      await watchlistCubit.load();
    },
    build: () =>
        WatchlistStocksCubit(getStocks: getStocks, watchlistCubit: watchlistCubit),
    act: (cubit) => cubit.load(),
    expect: () => const [WatchlistStocksEmpty()],
    verify: (_) => verifyNever(() => getStocks(any())),
  );

  blocTest<WatchlistStocksCubit, WatchlistStocksState>(
    'a GetStocks failure emits Error',
    setUp: () async {
      when(() => getWatchlistUseCase(any()))
          .thenAnswer((_) async => const Right(['AAPL']));
      when(() => getStocks(any()))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      await watchlistCubit.load();
    },
    build: () =>
        WatchlistStocksCubit(getStocks: getStocks, watchlistCubit: watchlistCubit),
    act: (cubit) => cubit.load(),
    expect: () => const [
      WatchlistStocksLoading(),
      WatchlistStocksError('No internet connection'),
    ],
  );

  blocTest<WatchlistStocksCubit, WatchlistStocksState>(
    'refresh() is silent: no Loading flash and a failure keeps the last '
    'Loaded state',
    setUp: () async {
      when(() => getWatchlistUseCase(any()))
          .thenAnswer((_) async => const Right(['AAPL']));
      when(() => getStocks(const SymbolsParams(['AAPL'])))
          .thenAnswer((_) async => Right([_tAapl]));
      await watchlistCubit.load();
    },
    build: () =>
        WatchlistStocksCubit(getStocks: getStocks, watchlistCubit: watchlistCubit),
    act: (cubit) async {
      await cubit.load();
      when(() => getStocks(const SymbolsParams(['AAPL'])))
          .thenAnswer((_) async => const Left(NetworkFailure()));
      await cubit.refresh();
    },
    expect: () => [
      const WatchlistStocksLoading(),
      WatchlistStocksLoaded([_tAapl]),
    ],
  );
}
