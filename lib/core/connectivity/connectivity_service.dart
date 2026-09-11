import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps `connectivity_plus` with a single platform-stream subscription for
/// the whole app (not one per feature) and a synchronous [isOnline] getter
/// so callers that can't await (e.g. a Dio interceptor's `onRequest`) can
/// still check the latest known status.
///
/// Note: this reports network-*interface* reachability, not guaranteed
/// internet reachability (e.g. a captive portal still reads "online") — that
/// gap is already covered by the existing Dio timeout -> `NetworkFailure`
/// mapping, so a second connectivity package isn't warranted here.
class ConnectivityService {
  final Connectivity _connectivity;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  bool get isOnline => _isOnline;

  /// Only emits when online/offline actually flips.
  Stream<bool> get onStatusChanged => _controller.stream;

  Future<void> initialize() async {
    _isOnline = _computeOnline(await _connectivity.checkConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final online = _computeOnline(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  bool _computeOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
