import 'package:dio/dio.dart';

import 'connectivity_service.dart';

/// Rejects a request before it ever reaches the wire when the device is
/// known to be offline, instead of waiting for it to time out.
///
/// The rejection is a synthetic [DioException] with
/// `type: DioExceptionType.connectionError` — the exact type
/// `StockRepositoryImpl._guard` already maps to `NetworkFailure()`, so this
/// needs no changes anywhere in the repository/use-case/cubit layers, and
/// the debug-mode mock-data fallback (`_withMockFallback`) still engages for
/// it exactly as it does for a real dropped connection.
class ConnectivityInterceptor extends Interceptor {
  final ConnectivityService connectivityService;

  ConnectivityInterceptor(this.connectivityService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!connectivityService.isOnline) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'No internet connection',
        ),
      );
      return;
    }
    handler.next(options);
  }
}
