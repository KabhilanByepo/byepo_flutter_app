import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/lifecycle/refresh_on_foreground_mixin.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../watchlist/presentation/widgets/watchlist_toggle_icon.dart';
import '../../domain/entities/stock.dart';
import '../cubit/stock_details_cubit.dart';
import '../cubit/stock_details_state.dart';
import '../format.dart';

/// Full-screen quote details for one symbol. Works both from a tapped card
/// (an optional [seed] renders instantly) and from a cold deep link
/// (`/stock-details/AAPL`, no seed — fetch by symbol).
class StockDetailsPage extends StatefulWidget {
  final String symbol;
  final Stock? seed;

  const StockDetailsPage({super.key, required this.symbol, this.seed});

  @override
  State<StockDetailsPage> createState() => _StockDetailsPageState();
}

class _StockDetailsPageState extends State<StockDetailsPage>
    with RefreshOnForegroundMixin<StockDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<StockDetailsCubit>().load(widget.symbol, seed: widget.seed);
  }

  @override
  void onForegroundRefresh() =>
      context.read<StockDetailsCubit>().refresh(widget.symbol);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.symbol),
        actions: [WatchlistToggleIcon(symbol: widget.symbol)],
      ),
      body: BlocBuilder<StockDetailsCubit, StockDetailsState>(
        builder: (context, state) => switch (state) {
          StockDetailsInitial() =>
            const Center(child: CircularProgressIndicator()),
          StockDetailsLoading(:final seed) => seed == null
              ? const Center(child: CircularProgressIndicator())
              : _DetailsBody(stock: seed, refreshing: true),
          StockDetailsLoaded(:final stock) => _DetailsBody(stock: stock),
          StockDetailsError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<StockDetailsCubit>().load(widget.symbol),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  final Stock stock;

  /// True while a fresher quote is still loading behind a seed.
  final bool refreshing;

  const _DetailsBody({required this.stock, this.refreshing = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeColor = stock.isUp
        ? theme.extension<AppSemanticColors>()!.positive
        : theme.colorScheme.error;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (refreshing) const LinearProgressIndicator(),
        Row(
          children: [
            _Logo(url: stock.logoUrl, symbol: stock.symbol),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stock.companyName, style: theme.textTheme.titleLarge),
                  Text(
                    '${stock.symbol} · ${stock.exchange}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          formatPrice(stock.ltp, stock.currency),
          style: theme.textTheme.displaySmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatSigned(stock.change)}   ${formatPercent(stock.changePercent)}',
          style: theme.textTheme.titleMedium
              ?.copyWith(color: changeColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        _StatTable(rows: [
          ('Open', formatPrice(stock.open, stock.currency)),
          ('High', formatPrice(stock.high, stock.currency)),
          ('Low', formatPrice(stock.low, stock.currency)),
          ('Previous close', formatPrice(stock.previousClose, stock.currency)),
          ('Exchange', stock.exchange),
          ('Industry', stock.industry),
          ('Market cap', formatMarketCap(stock.marketCap)),
          ('Currency', stock.currency),
        ]),
      ],
    );
  }
}

class _StatTable extends StatelessWidget {
  final List<(String, String)> rows;

  const _StatTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        children: [
          for (final (label, value) in rows)
            ListTile(
              dense: true,
              title: Text(label, style: theme.textTheme.bodyMedium),
              trailing: Text(
                value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String url;
  final String symbol;

  const _Logo({required this.url, required this.symbol});

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final fallback = CircleAvatar(
      radius: size / 2,
      child: Text(symbol.isNotEmpty ? symbol[0] : '?',
          style: const TextStyle(fontWeight: FontWeight.w700)),
    );
    if (url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
