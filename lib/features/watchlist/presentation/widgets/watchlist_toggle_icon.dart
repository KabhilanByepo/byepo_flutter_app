import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../cubit/watchlist_cubit.dart';

/// A star icon reflecting/toggling one symbol's watchlist membership. Used
/// on both the Dashboard (quick-add) and Symbol Details (add/remove) — the
/// only two places that call `WatchlistCubit.add()`/`.remove()` from the UI,
/// so the toggle behavior lives in exactly one widget.
///
/// Reads `WatchlistCubit` via `context.select` so only this row's icon
/// rebuilds when its own membership flips, not every row watching the same
/// shared cubit.
class WatchlistToggleIcon extends StatelessWidget {
  final String symbol;

  const WatchlistToggleIcon({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final inWatchlist = context.select<WatchlistCubit, bool>(
      (cubit) => cubit.contains(symbol),
    );
    final starred = Theme.of(context).extension<AppSemanticColors>()!.starred;
    return IconButton(
      icon: Icon(inWatchlist ? Icons.star : Icons.star_border),
      color: inWatchlist ? starred : null,
      tooltip: inWatchlist ? 'Remove from watchlist' : 'Add to watchlist',
      onPressed: () {
        final cubit = context.read<WatchlistCubit>();
        inWatchlist ? cubit.remove(symbol) : cubit.add(symbol);
      },
    );
  }
}
