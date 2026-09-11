import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../connectivity/connectivity_cubit.dart';
import 'app_lifecycle_cubit.dart';

/// Reusable screen-level lifecycle + connectivity awareness.
///
/// Subscribes once (in `initState`) to the app's centralized
/// [AppLifecycleCubit] and [ConnectivityCubit], cancels both in `dispose()`
/// — screens using this never touch a raw `WidgetsBindingObserver` or a raw
/// `connectivity_plus` stream themselves.
///
/// [onForegroundRefresh] fires when the app resumes to the foreground *or*
/// connectivity is restored, but only if the screen is actually mounted and
/// visible (`TickerMode.valuesOf(context).enabled` is false for
/// `StatefulShellRoute` branches kept alive off-screen by `IndexedStack`) —
/// so backgrounded/off-screen tabs don't silently refetch. Implement it with
/// a Cubit's *silent* refresh method, never a full reload, so there's no
/// spinner flash and no clobbering of good data with a transient error.
mixin RefreshOnForegroundMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<AppLifecycleState>? _lifecycleSubscription;
  StreamSubscription<ConnectivityState>? _connectivitySubscription;

  void onForegroundRefresh();

  /// Called when the app is backgrounded (paused/inactive/detached).
  /// Override to pause screen-owned polling; default is a no-op.
  void onBackground() {}

  @override
  void initState() {
    super.initState();
    _lifecycleSubscription =
        context.read<AppLifecycleCubit>().stream.listen(_onLifecycleChanged);
    _connectivitySubscription = context
        .read<ConnectivityCubit>()
        .stream
        .listen(_onConnectivityChanged);
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _maybeRefresh();
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        onBackground();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onConnectivityChanged(ConnectivityState state) {
    if (state is ConnectivityOnline) _maybeRefresh();
  }

  void _maybeRefresh() {
    if (!mounted || !TickerMode.valuesOf(context).enabled) return;
    onForegroundRefresh();
  }

  @override
  void dispose() {
    _lifecycleSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
