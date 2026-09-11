import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/connectivity/connectivity_banner.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/di/injection_container.dart' as di;
import 'core/lifecycle/app_lifecycle_cubit.dart';
import 'core/network/api_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/watchlist/presentation/cubit/watchlist_cubit.dart';

const _missingApiKeyMessage =
    'flutter run --dart-define=FINNHUB_API_KEY=<your-free-finnhub-key>';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check this *before* wiring the DI graph: `DioClient` sits at the bottom
  // of a long `get_it` lazy-singleton chain, so letting its assert fire from
  // inside a cubit build would print one "Error while creating X" per link
  // in that chain before finally crashing the widget tree. Bailing out here
  // instead shows one clean, actionable screen — in both debug and release
  // (this is a plain `if`, not an `assert`, so it isn't stripped in release).
  if (ApiConfig.finnhubApiKey.isEmpty) {
    runApp(const _MissingApiKeyApp());
    return;
  }

  await di.initDependencies();
  // Fire-and-forget: any of the three screens that depend on it (Dashboard,
  // Details, Watchlist) could be opened first, so no single screen owns
  // triggering this — trigger it once here instead.
  di.sl<WatchlistCubit>().load();
  runApp(const ByepoStockApp());
}

/// Shown instead of the real app when no Finnhub API key was supplied
/// at build time. Deliberately standalone (no DI, no GoRouter) so it can
/// never itself fail to build.
class _MissingApiKeyApp extends StatelessWidget {
  const _MissingApiKeyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Byepo Stock Market',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.vpn_key_off,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                const Text(
                  'Missing Finnhub API key',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get a free key at finnhub.io/dashboard, then '
                  'run the app with it:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SelectableText(
                      _missingApiKeyMessage,
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ByepoStockApp extends StatelessWidget {
  const ByepoStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ConnectivityCubit>.value(
          value: di.sl<ConnectivityCubit>(),
        ),
        BlocProvider<AppLifecycleCubit>.value(
          value: di.sl<AppLifecycleCubit>(),
        ),
        BlocProvider<ThemeCubit>.value(value: di.sl<ThemeCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          title: 'Byepo Stock Market',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: di.sl<GoRouter>(),
          builder: (context, child) => ConnectivityBanner(child: child!),
        ),
      ),
    );
  }
}
