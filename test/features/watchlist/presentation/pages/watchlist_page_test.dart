import 'package:byepo_stock_market/core/connectivity/connectivity_cubit.dart';
import 'package:byepo_stock_market/core/connectivity/connectivity_service.dart';
import 'package:byepo_stock_market/core/lifecycle/app_lifecycle_cubit.dart';
import 'package:byepo_stock_market/core/lifecycle/app_lifecycle_service.dart';
import 'package:byepo_stock_market/core/usecase/usecase.dart';
import 'package:byepo_stock_market/features/stock/domain/entities/stock.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/get_stocks.dart';
import 'package:byepo_stock_market/features/stock/presentation/widgets/stock_card.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/add_to_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/get_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/remove_from_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/watchlist_symbol_params.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_cubit.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_stocks_cubit.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/pages/watchlist_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetStocks extends Mock implements GetStocks {}

class MockGetWatchlist extends Mock implements GetWatchlist {}

class MockAddToWatchlist extends Mock implements AddToWatchlist {}

class MockRemoveFromWatchlist extends Mock implements RemoveFromWatchlist {}

const _tStock = Stock(
  symbol: 'AAPL',
  companyName: 'Apple Inc',
  logoUrl: '',
  ltp: 190.12,
  change: 2.5,
  changePercent: 1.3,
  open: 188,
  high: 191,
  low: 187.5,
  previousClose: 187.62,
  exchange: 'NASDAQ',
  industry: 'Technology',
  marketCap: 3000000,
  currency: 'USD',
);

/// Pump a few frames without settling (spinners animate forever, so
/// `pumpAndSettle` would time out).
Future<void> _tick(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late MockGetStocks getStocks;
  late MockGetWatchlist getWatchlistUseCase;
  late MockAddToWatchlist addToWatchlist;
  late MockRemoveFromWatchlist removeFromWatchlist;
  late WatchlistCubit watchlistCubit;
  late AppLifecycleCubit appLifecycleCubit;
  late ConnectivityCubit connectivityCubit;

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
    // WatchlistPage now reads these via RefreshOnForegroundMixin — not
    // `.initialize()`d, so no real platform-channel call happens.
    appLifecycleCubit = AppLifecycleCubit(service: AppLifecycleService());
    connectivityCubit = ConnectivityCubit(service: ConnectivityService());
  });

  tearDown(() {
    watchlistCubit.close();
    appLifecycleCubit.close();
    connectivityCubit.close();
  });

  Widget host() => MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<WatchlistCubit>.value(value: watchlistCubit),
            BlocProvider<AppLifecycleCubit>.value(value: appLifecycleCubit),
            BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
            BlocProvider(
              create: (_) => WatchlistStocksCubit(
                getStocks: getStocks,
                watchlistCubit: watchlistCubit,
              ),
            ),
          ],
          child: const WatchlistPage(),
        ),
      );

  testWidgets('an empty watchlist shows the empty-state placeholder',
      (tester) async {
    when(() => getWatchlistUseCase(any()))
        .thenAnswer((_) async => const Right(<String>[]));

    await tester.pumpWidget(host());
    await _tick(tester);

    expect(find.text('No stocks in your watchlist yet'), findsOneWidget);
    expect(find.byType(StockCard), findsNothing);
  });

  testWidgets(
      'a loaded watchlist renders one StockCard per symbol with a delete '
      'action', (tester) async {
    when(() => getWatchlistUseCase(any()))
        .thenAnswer((_) async => const Right(['AAPL']));
    when(() => getStocks(any()))
        .thenAnswer((_) async => const Right([_tStock]));

    await tester.pumpWidget(host());
    await _tick(tester);

    expect(find.byType(StockCard), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('deleting the only symbol shows the empty state',
      (tester) async {
    when(() => getWatchlistUseCase(any()))
        .thenAnswer((_) async => const Right(['AAPL']));
    when(() => getStocks(any()))
        .thenAnswer((_) async => const Right([_tStock]));
    when(() => removeFromWatchlist(any()))
        .thenAnswer((_) async => const Right(<String>[]));

    await tester.pumpWidget(host());
    await _tick(tester);
    expect(find.byType(StockCard), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await _tick(tester);

    expect(find.byType(StockCard), findsNothing);
    expect(find.text('No stocks in your watchlist yet'), findsOneWidget);
  });
}
