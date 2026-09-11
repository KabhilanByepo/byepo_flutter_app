import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_lifecycle_service.dart';

/// Relays [AppLifecycleService]'s stream into the app's Cubit-based state
/// pattern. Long-lived (registered once in `get_it`, provided via `.value`
/// at the app root) — screens read this instead of mixing in their own
/// `WidgetsBindingObserver`.
class AppLifecycleCubit extends Cubit<AppLifecycleState> {
  final AppLifecycleService service;
  late final StreamSubscription<AppLifecycleState> _subscription;

  AppLifecycleCubit({required this.service}) : super(service.current) {
    _subscription = service.stream.listen(emit);
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
