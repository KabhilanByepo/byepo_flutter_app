import 'dart:async';

import 'package:flutter/widgets.dart';

/// Wraps a single [AppLifecycleListener] for the whole app.
///
/// [AppLifecycleListener] already mixes in [WidgetsBindingObserver] and
/// self-registers/self-unregisters with [WidgetsBinding] — using one
/// `get_it`-owned instance here means exactly one observer reacts to
/// lifecycle changes, instead of every screen mixing in its own.
class AppLifecycleService {
  final _controller = StreamController<AppLifecycleState>.broadcast();
  late final AppLifecycleListener _listener;
  AppLifecycleState _current = AppLifecycleState.resumed;

  AppLifecycleService() {
    _listener = AppLifecycleListener(onStateChange: _onStateChange);
  }

  AppLifecycleState get current => _current;

  Stream<AppLifecycleState> get stream => _controller.stream;

  void _onStateChange(AppLifecycleState state) {
    _current = state;
    _controller.add(state);
  }

  void dispose() {
    _listener.dispose();
    _controller.close();
  }
}
