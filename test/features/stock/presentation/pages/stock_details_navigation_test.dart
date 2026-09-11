import 'package:byepo_stock_market/core/connectivity/connectivity_cubit.dart';
import 'package:byepo_stock_market/core/connectivity/connectivity_service.dart';
import 'package:byepo_stock_market/core/di/injection_container.dart';
import 'package:byepo_stock_market/core/lifecycle/app_lifecycle_cubit.dart';
import 'package:byepo_stock_market/core/lifecycle/app_lifecycle_service.dart';
import 'package:byepo_stock_market/core/router/app_router.dart';
import 'package:byepo_stock_market/core/theme/app_theme.dart';
import 'package:byepo_stock_market/core/usecase/usecase.dart';
import 'package:byepo_stock_market/features/stock/domain/entities/stock.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/get_stock_details.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/get_stocks.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/search_stocks.dart';
import 'package:byepo_stock_market/features/stock/presentation/cubit/dashboard_cubit.dart';
import 'package:byepo_stock_market/features/stock/presentation/cubit/stock_details_cubit.dart';
import 'package:byepo_stock_market/features/stock/presentation/cubit/stock_search_cubit.dart';
import 'package:byepo_stock_market/features/stock/presentation/widgets/stock_card.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/add_to_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/get_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/remove_from_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/watchlist_symbol_params.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_cubit.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/widgets/watchlist_toggle_icon.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockGetStocks extends Mock implements GetStocks {}

class MockGetStockDetails extends Mock implements GetStockDetails {}

class MockSearchStocks extends Mock implements SearchStocks {}

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
  late MockGetStockDetails getStockDetails;
  late MockSearchStocks searchStocks;
  late MockGetWatchlist getWatchlist;
  late MockAddToWatchlist addToWatchlist;
  late MockRemoveFromWatchlist removeFromWatchlist;
  late AppLifecycleCubit appLifecycleCubit;
  late ConnectivityCubit connectivityCubit;

  setUpAll(() {
    registerFallbackValue(const SymbolsParams([]));
    registerFallbackValue(const SymbolParams(''));
    registerFallbackValue(const QueryParams(''));
    registerFallbackValue(const NoParams());
    registerFallbackValue(const WatchlistSymbolParams(''));
  });

  setUp(() {
    getStocks = MockGetStocks();
    getStockDetails = MockGetStockDetails();
    searchStocks = MockSearchStocks();
    getWatchlist = MockGetWatchlist();
    addToWatchlist = MockAddToWatchlist();
    removeFromWatchlist = MockRemoveFromWatchlist();
    when(() => getWatchlist(any())).thenAnswer((_) async => const Right([]));
    when(() => addToWatchlist(any()))
        .thenAnswer((_) async => const Right(['AAPL']));
    when(() => removeFromWatchlist(any()))
        .thenAnswer((_) async => const Right([]));
    sl.registerFactory(() => DashboardCubit(getStocks: getStocks));
    sl.registerFactory(() => StockSearchCubit(searchStocks: searchStocks));
    sl.registerFactory(
        () => StockDetailsCubit(getStockDetails: getStockDetails));
    // Registered as a singleton, matching production: Dashboard and Details
    // must observe the exact same WatchlistCubit instance.
    sl.registerLazySingleton(() => WatchlistCubit(
          getWatchlist: getWatchlist,
          addToWatchlist: addToWatchlist,
          removeFromWatchlist: removeFromWatchlist,
        ));
    // Dashboard/StockDetails now read these via RefreshOnForegroundMixin —
    // not `.initialize()`d, so no real platform-channel call happens (this
    // mirrors ByepoStockApp's top-level providers, not sl, since the mixin
    // reads from the widget tree).
    appLifecycleCubit = AppLifecycleCubit(service: AppLifecycleService());
    connectivityCubit = ConnectivityCubit(service: ConnectivityService());
  });

  tearDown(() {
    sl.reset();
    appLifecycleCubit.close();
    connectivityCubit.close();
  });

  /// Mirrors `ByepoStockApp`'s top-level providers so pages using
  /// `RefreshOnForegroundMixin` (Dashboard, StockDetails) can find their
  /// ancestors via `context.read`.
  Widget host(GoRouter router) => MultiBlocProvider(
        providers: [
          BlocProvider<AppLifecycleCubit>.value(value: appLifecycleCubit),
          BlocProvider<ConnectivityCubit>.value(value: connectivityCubit),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      );

  testWidgets('tapping a StockCard on the Dashboard opens the details screen',
      (tester) async {
    when(() => getStocks(any()))
        .thenAnswer((_) async => const Right([_tStock]));
    when(() => getStockDetails(any()))
        .thenAnswer((_) async => const Right(_tStock));

    await tester.pumpWidget(host(AppRouter().config));

    // Splash holds for 2s, then routes to the Dashboard.
    await tester.pump(const Duration(seconds: 2));
    await _tick(tester);

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
    expect(find.byType(StockCard), findsOneWidget);

    await tester.tap(find.byType(StockCard));
    await _tick(tester);

    // Details-only content confirms we navigated to /stock-details/AAPL.
    expect(find.text('Previous close'), findsOneWidget);
    expect(find.text('Market cap'), findsOneWidget);
    verify(() => getStockDetails(const SymbolParams('AAPL'))).called(1);
  });

  testWidgets(
      'tapping the watchlist star on a Dashboard card adds it without '
      'navigating away', (tester) async {
    when(() => getStocks(any()))
        .thenAnswer((_) async => const Right([_tStock]));

    await tester.pumpWidget(host(AppRouter().config));
    await tester.pump(const Duration(seconds: 2));
    await _tick(tester);

    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);

    await tester.tap(find.byType(WatchlistToggleIcon));
    await _tick(tester);

    verify(() => addToWatchlist(const WatchlistSymbolParams('AAPL')))
        .called(1);
    // Still on the Dashboard — quick-add doesn't open Details.
    expect(find.widgetWithText(AppBar, 'Dashboard'), findsOneWidget);
  });

  testWidgets('an unknown route shows the error page', (tester) async {
    when(() => getStocks(any()))
        .thenAnswer((_) async => const Right([_tStock]));

    final router = AppRouter().config;
    await tester.pumpWidget(host(router));
    await tester.pump(const Duration(seconds: 2));
    await _tick(tester);

    router.go('/nonsense');
    await _tick(tester);

    expect(find.text('Page not found'), findsOneWidget);
  });
}
