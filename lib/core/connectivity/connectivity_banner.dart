import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_cubit.dart';

/// The single, centralized UI reaction to connectivity changes — used once
/// in `MaterialApp.router`'s `builder:`, wrapping every routed screen
/// (including full-screen routes outside the bottom-nav shell). No screen
/// implements its own offline banner/logic.
class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final offline = context.select<ConnectivityCubit, bool>(
      (cubit) => cubit.state is ConnectivityOffline,
    );

    return Column(
      children: [
        if (offline)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: Text(
                    'No internet connection',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
