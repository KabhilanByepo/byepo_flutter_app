import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_service.dart';

sealed class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}

/// The app's single source of truth for online/offline. Long-lived
/// (registered once in `get_it`, provided via `.value` at the app root) —
/// screens/widgets react to this instead of each holding their own
/// `connectivity_plus` subscription.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService service;
  late final StreamSubscription<bool> _subscription;

  ConnectivityCubit({required this.service})
      : super(
          service.isOnline
              ? const ConnectivityOnline()
              : const ConnectivityOffline(),
        ) {
    _subscription = service.onStatusChanged.listen(
      (online) =>
          emit(online ? const ConnectivityOnline() : const ConnectivityOffline()),
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
