import 'package:byepo_stock_market/core/connectivity/connectivity_interceptor.dart';
import 'package:byepo_stock_market/core/connectivity/connectivity_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockConnectivityService service;
  late Dio dio;

  setUp(() {
    service = MockConnectivityService();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(ConnectivityInterceptor(service));
  });

  test(
    'rejects the request before it reaches the wire when offline',
    () async {
      when(() => service.isOnline).thenReturn(false);

      await expectLater(
        () => dio.get<void>('/quote'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
    },
  );

  test('passes the request through to later interceptors when online', () async {
    when(() => service.isOnline).thenReturn(true);
    var reachedNextInterceptor = false;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          reachedNextInterceptor = true;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
            ),
          );
        },
      ),
    );

    await expectLater(() => dio.get<void>('/quote'), throwsA(isA<DioException>()));
    expect(reachedNextInterceptor, isTrue);
  });
}
