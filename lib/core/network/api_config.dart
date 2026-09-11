/// Static configuration for the Finnhub Quote API.
///
/// The API token is supplied at build time and never committed:
///
/// ```
/// flutter run  --dart-define=FINNHUB_API_KEY=your_key
/// flutter test --dart-define=FINNHUB_API_KEY=test   # tests mock Dio; any value works
/// ```
class ApiConfig {
  const ApiConfig._();

  static const String finnhubBaseUrl = 'https://finnhub.io/api/v1';

  /// Free personal token from https://finnhub.io/dashboard.
  /// Empty when the `--dart-define` is missing — [DioClient] asserts on that
  /// in debug, and `main()` shows a friendly error screen in any build mode.
  static const String finnhubApiKey = String.fromEnvironment('FINNHUB_API_KEY');

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
