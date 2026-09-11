import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/stock.dart';
import '../format.dart';

/// Reusable stock row used on the Dashboard list (and anywhere else a quote
/// summary is shown). Rendering only — it takes a [Stock] and an [onTap].
class StockCard extends StatelessWidget {
  final Stock stock;
  final VoidCallback onTap;

  /// Optional trailing action (e.g. a watchlist star/delete icon) appended
  /// after the price/change column. Renders nothing extra when omitted.
  final Widget? trailing;

  const StockCard({
    super.key,
    required this.stock,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changeColor =
        stock.isUp ? Colors.green.shade700 : theme.colorScheme.error;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Logo(url: stock.logoUrl, symbol: stock.symbol),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.symbol,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      stock.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPrice(stock.ltp, stock.currency),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatSigned(stock.change)}  ${formatPercent(stock.changePercent)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: changeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (trailing != null) ...[
                const SizedBox(width: 4),
                trailing!,
              ],
            ],
          ),
        ),
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
    const size = 40.0;
    final fallback = CircleAvatar(
      radius: size / 2,
      child: Text(
        symbol.isNotEmpty ? symbol[0] : '?',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    if (url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          width: size,
          height: size,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
