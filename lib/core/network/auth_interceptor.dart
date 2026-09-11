import 'package:dio/dio.dart';

import 'api_config.dart';

/// Adds the Finnhub token to every outgoing request.
///
/// Keeps the secret out of logged/handwritten URLs — every request gets it
/// added here rather than each data-source call setting it itself.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Finnhub-Token'] = ApiConfig.finnhubApiKey;
    handler.next(options);
  }
}
