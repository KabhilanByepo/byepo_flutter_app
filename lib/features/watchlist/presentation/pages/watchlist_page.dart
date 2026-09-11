import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/lifecycle/refresh_on_foreground_mixin.dart';
import '../../../stock/presentation/widgets/stock_card.dart';
import '../cubit/watchlist_cubit.dart';
import '../cubit/watchlist_stocks_cubit.dart';
import '../cubit/watchlist_stocks_state.dart';

/// The watchlist: every symbol the user has starred, rendered with the same
/// `StockCard` the Dashboard uses, each with a delete action. Backed by
/// `WatchlistStocksCubit`, which reacts live to `WatchlistCubit` (the shared
/// membership source of truth) — added/removed symbols from any screen show
/// up here without a manual refresh.
class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage>
    with RefreshOnForegroundMixin<WatchlistPage> {
  @override
  void initState() {
    super.initState();
    context.read<WatchlistStocksCubit>().load();
  }

  @override
  void onForegroundRefresh() =>
      context.read<WatchlistStocksCubit>().refresh();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: BlocBuilder<WatchlistStocksCubit, WatchlistStocksState>(
        builder: (context, state) => switch (state) {
          WatchlistStocksInitial() ||
          WatchlistStocksLoading() =>
            const Center(child: CircularProgressIndicator()),
          WatchlistStocksEmpty() => const _EmptyWatchlist(),
          WatchlistStocksError(:final message) => _ErrorView(
              message: message,
              onRetry: () => context.read<WatchlistStocksCubit>().load(),
            ),
          WatchlistStocksLoaded(:final stocks) => ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks[index];
                return StockCard(
                  stock: stock,
                  onTap: () => context.push('/stock-details/${stock.symbol}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove from watchlist',
                    onPressed: () =>
                        context.read<WatchlistCubit>().remove(stock.symbol),
                  ),
                );
              },
            ),
        },
      ),
    );
  }
}

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border,
                size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No stocks in your watchlist yet',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap the star on any stock — from the Dashboard or its '
              'details screen — to add it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
