import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/lifecycle/refresh_on_foreground_mixin.dart';
import '../../../watchlist/presentation/widgets/watchlist_toggle_icon.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../cubit/stock_search_cubit.dart';
import '../cubit/stock_search_state.dart';
import '../widgets/stock_card.dart';

/// The main screen: a curated list of quote cards, pull-to-refresh, a toggle for
/// the 30s auto-refresh, and a server-side search. `DashboardCubit` +
/// `StockSearchCubit` are provided by the router above this widget.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with RefreshOnForegroundMixin<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().load();
  }

  @override
  void onForegroundRefresh() =>
      context.read<DashboardCubit>().resumeForForeground();

  @override
  void onBackground() => context.read<DashboardCubit>().pauseForBackground();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searchOpen = true);

  void _closeSearch() {
    _searchController.clear();
    context.read<StockSearchCubit>().clear();
    setState(() => _searchOpen = false);
  }

  void _openDetails(String symbol) => context.push('/stock-details/$symbol');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _searchOpen ? _buildSearchAppBar() : _buildDefaultAppBar(),
      body: _searchOpen
          ? _SearchResults(onTapResult: _openDetails)
          : _DashboardList(onTapStock: _openDetails),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
      title: const Text('Dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search stocks',
          onPressed: _openSearch,
        ),
        BlocBuilder<DashboardCubit, DashboardState>(
          buildWhen: (a, b) =>
              a.runtimeType != b.runtimeType || b is DashboardLoaded,
          builder: (context, state) {
            final on = state is DashboardLoaded && state.autoRefreshing;
            return IconButton(
              icon: Icon(on ? Icons.autorenew : Icons.autorenew_outlined),
              tooltip: on ? 'Auto-refresh on (30s)' : 'Auto-refresh off',
              color: on ? Theme.of(context).colorScheme.primary : null,
              onPressed: () =>
                  context.read<DashboardCubit>().toggleAutoRefresh(),
            );
          },
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _closeSearch,
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search symbol or company…',
          border: InputBorder.none,
        ),
        onChanged: (q) => context.read<StockSearchCubit>().search(q),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            context.read<StockSearchCubit>().clear();
          },
        ),
      ],
    );
  }
}

class _DashboardList extends StatelessWidget {
  final void Function(String symbol) onTapStock;

  const _DashboardList({required this.onTapStock});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) => switch (state) {
        DashboardInitial() ||
        DashboardLoading() =>
          const Center(child: CircularProgressIndicator()),
        DashboardEmpty() => const Center(child: Text('No stocks to show.')),
        DashboardError(:final message) => _ErrorView(
            message: message,
            onRetry: () => context.read<DashboardCubit>().load(),
          ),
        DashboardLoaded(:final stocks) => RefreshIndicator(
            onRefresh: () => context.read<DashboardCubit>().refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks[index];
                return StockCard(
                  stock: stock,
                  onTap: () => onTapStock(stock.symbol),
                  trailing: WatchlistToggleIcon(symbol: stock.symbol),
                );
              },
            ),
          ),
      },
    );
  }
}

class _SearchResults extends StatelessWidget {
  final void Function(String symbol) onTapResult;

  const _SearchResults({required this.onTapResult});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockSearchCubit, StockSearchState>(
      builder: (context, state) => switch (state) {
        StockSearchInitial() => const Center(
            child: Text('Type to search for a stock.'),
          ),
        StockSearchLoading() =>
          const Center(child: CircularProgressIndicator()),
        StockSearchEmpty() => const Center(child: Text('No matches.')),
        StockSearchError(:final message) => _ErrorView(message: message),
        StockSearchLoaded(:final results) => ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                leading: const Icon(Icons.trending_up),
                title: Text(result.symbol),
                subtitle: Text(
                  result.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => onTapResult(result.symbol),
              );
            },
          ),
      },
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
