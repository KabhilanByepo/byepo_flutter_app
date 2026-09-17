import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/bridge/presentation/cubit/bridge_cubit.dart';
import '../../features/bridge/presentation/pages/bridge_poc_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/stock/domain/entities/stock.dart';
import '../../features/stock/presentation/cubit/dashboard_cubit.dart';
import '../../features/stock/presentation/cubit/stock_details_cubit.dart';
import '../../features/stock/presentation/cubit/stock_search_cubit.dart';
import '../../features/stock/presentation/pages/accounts_page.dart';
import '../../features/stock/presentation/pages/dashboard_page.dart';
import '../../features/stock/presentation/pages/stock_details_page.dart';
import '../../features/stock/presentation/widgets/app_shell.dart';
import '../../features/watchlist/presentation/cubit/watchlist_cubit.dart';
import '../../features/watchlist/presentation/cubit/watchlist_stocks_cubit.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';
import '../di/injection_container.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _dashboardNavigatorKey = GlobalKey<NavigatorState>();
final _watchlistNavigatorKey = GlobalKey<NavigatorState>();
final _accountsNavigatorKey = GlobalKey<NavigatorState>();

/// The single navigation graph for the app.
///
/// - `/splash`, `/bridge-poc`, and `/stock-details/:symbol` are top-level
///   routes on the root navigator (full screen, no bottom bar).
/// - `/dashboard`, `/watchlist`, `/accounts` are the three branches of a
///   `StatefulShellRoute.indexedStack`, so each tab keeps its own navigation
///   stack and widget state, and the selected tab is derived from the URL.
class AppRouter {
  GoRouter get config => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            name: 'splash',
            builder: (context, state) => const SplashPage(),
          ),
          GoRoute(
            path: '/bridge-poc',
            name: 'bridgePoc',
            builder: (context, state) => BlocProvider(
              create: (_) => sl<BridgeCubit>(),
              child: const BridgePocPage(),
            ),
          ),
          GoRoute(
            path: '/stock-details/:symbol',
            name: 'stockDetails',
            builder: (context, state) {
              final symbol = state.pathParameters['symbol']!;
              final seed = state.extra is Stock ? state.extra as Stock : null;
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (_) => sl<StockDetailsCubit>()),
                  BlocProvider<WatchlistCubit>.value(
                    value: sl<WatchlistCubit>(),
                  ),
                ],
                child: StockDetailsPage(symbol: symbol, seed: seed),
              );
            },
          ),
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                AppShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                navigatorKey: _dashboardNavigatorKey,
                routes: [
                  GoRoute(
                    path: '/dashboard',
                    name: 'dashboard',
                    builder: (context, state) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => sl<DashboardCubit>()),
                        BlocProvider(create: (_) => sl<StockSearchCubit>()),
                        BlocProvider<WatchlistCubit>.value(
                          value: sl<WatchlistCubit>(),
                        ),
                      ],
                      child: const DashboardPage(),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: _watchlistNavigatorKey,
                routes: [
                  GoRoute(
                    path: '/watchlist',
                    name: 'watchlist',
                    builder: (context, state) => MultiBlocProvider(
                      providers: [
                        BlocProvider<WatchlistCubit>.value(
                          value: sl<WatchlistCubit>(),
                        ),
                        BlocProvider(create: (_) => sl<WatchlistStocksCubit>()),
                      ],
                      child: const WatchlistPage(),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: _accountsNavigatorKey,
                routes: [
                  GoRoute(
                    path: '/accounts',
                    name: 'accounts',
                    builder: (context, state) => const AccountsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
        errorBuilder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Page not found')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text('No route for ${state.uri}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Go to Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
