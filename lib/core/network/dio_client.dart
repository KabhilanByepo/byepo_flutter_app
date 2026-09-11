import 'package:dio/dio.dart';

import '../connectivity/connectivity_interceptor.dart';
import '../connectivity/connectivity_service.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';

/// Builds the single, shared [Dio] instance for the whole app.
///
/// Base URL, timeouts and auth live here so no feature ever configures its own
/// HTTP client — data sources just receive this `Dio` and call relative paths
/// (`dio.get('/quote', ...)`).
class DioClient {
  const DioClient._();

  static Dio create({required ConnectivityService connectivityService}) {
    assert(
      ApiConfig.finnhubApiKey.isNotEmpty,
      'Missing FINNHUB_API_KEY. Run with '
      '--dart-define=FINNHUB_API_KEY=<your-free-finnhub-key>',
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.finnhubBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/json'},
      ),
    );

    // Connectivity check first: an offline request is rejected before it
    // ever reaches AuthInterceptor, instead of being stamped and timing out.
    dio.interceptors.addAll([
      ConnectivityInterceptor(connectivityService),
      AuthInterceptor(),
    ]);
    return dio;
  }
}
