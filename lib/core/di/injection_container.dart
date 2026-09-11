import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/stock/data/datasources/mock_stock_data.dart';
import '../../features/stock/data/datasources/stock_local_data_source.dart';
import '../../features/stock/data/datasources/stock_remote_data_source.dart';
import '../../features/stock/data/repositories/stock_repository_impl.dart';
import '../../features/stock/domain/repositories/stock_repository.dart';
import '../../features/stock/domain/usecases/get_stock_details.dart';
import '../../features/stock/domain/usecases/get_stocks.dart';
import '../../features/stock/domain/usecases/search_stocks.dart';
import '../../features/stock/presentation/cubit/dashboard_cubit.dart';
import '../../features/stock/presentation/cubit/stock_details_cubit.dart';
import '../../features/stock/presentation/cubit/stock_search_cubit.dart';
import '../../features/watchlist/data/datasources/watchlist_local_data_source.dart';
import '../../features/watchlist/data/repositories/watchlist_repository_impl.dart';
import '../../features/watchlist/domain/repositories/watchlist_repository.dart';
import '../../features/watchlist/domain/usecases/add_to_watchlist.dart';
import '../../features/watchlist/domain/usecases/get_watchlist.dart';
import '../../features/watchlist/domain/usecases/remove_from_watchlist.dart';
import '../../features/watchlist/presentation/cubit/watchlist_cubit.dart';
import '../../features/watchlist/presentation/cubit/watchlist_stocks_cubit.dart';
import '../connectivity/connectivity_cubit.dart';
import '../connectivity/connectivity_service.dart';
import '../lifecycle/app_lifecycle_cubit.dart';
import '../lifecycle/app_lifecycle_service.dart';
import '../network/dio_client.dart';
import '../router/app_router.dart';
import '../theme/theme_cubit.dart';

final sl =
    GetIt.instance; // service locator, wired ONLY here (composition root)

Future<void> initDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // Connectivity is checked once up front so the app's initial
  // online/offline status is correct before first paint, not a flash of
  // "online" while an async check catches up.
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();
  sl.registerLazySingleton<ConnectivityService>(() => connectivityService);

  sl.registerLazySingleton<AppLifecycleService>(() => AppLifecycleService());

  sl.registerLazySingleton<Dio>(
    () => DioClient.create(connectivityService: sl()),
  );

  // Navigation
  sl.registerLazySingleton<GoRouter>(() => AppRouter().config);

  // Data
  sl.registerLazySingleton<StockRemoteDataSource>(
    () => StockRemoteDataSourceImpl(dio: sl()),
  );
  sl.registerLazySingleton<StockLocalDataSource>(
    () => InMemoryStockLocalDataSource(),
  );
  sl.registerLazySingleton<StockMockDataSource>(
    () => StaticStockMockDataSource(),
  );
  sl.registerLazySingleton<StockRepository>(
    () => StockRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      mockDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<WatchlistLocalDataSource>(
    () => SharedPreferencesWatchlistLocalDataSource(prefs: sl()),
  );
  sl.registerLazySingleton<WatchlistRepository>(
    () => WatchlistRepositoryImpl(localDataSource: sl()),
  );

  // Domain
  sl.registerLazySingleton(() => GetStocks(sl()));
  sl.registerLazySingleton(() => GetStockDetails(sl()));
  sl.registerLazySingleton(() => SearchStocks(sl()));
  sl.registerLazySingleton(() => GetWatchlist(sl()));
  sl.registerLazySingleton(() => AddToWatchlist(sl()));
  sl.registerLazySingleton(() => RemoveFromWatchlist(sl()));

  // Presentation
  sl.registerFactory(() => DashboardCubit(getStocks: sl()));
  sl.registerFactory(() => StockSearchCubit(searchStocks: sl()));
  sl.registerFactory(() => StockDetailsCubit(getStockDetails: sl()));
  // Singleton: shared live across Dashboard, Details, and Watchlist via
  // BlocProvider.value (never `create:`, which would auto-close it on pop).
  sl.registerLazySingleton(
    () => WatchlistCubit(
      getWatchlist: sl(),
      addToWatchlist: sl(),
      removeFromWatchlist: sl(),
    ),
  );
  sl.registerFactory(
    () => WatchlistStocksCubit(getStocks: sl(), watchlistCubit: sl()),
  );

  // Cross-cutting: lifecycle, connectivity, theme. Each computes its
  // initial state synchronously in its constructor (from the services
  // registered above, or from `prefs` directly), so — unlike WatchlistCubit
  // — none of these need an eager `.load()` call from main.dart.
  sl.registerLazySingleton<ConnectivityCubit>(
    () => ConnectivityCubit(service: sl()),
  );
  sl.registerLazySingleton<AppLifecycleCubit>(
    () => AppLifecycleCubit(service: sl()),
  );
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs: sl()));
}
