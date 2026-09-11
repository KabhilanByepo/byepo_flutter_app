import 'dart:async';

import 'package:byepo_stock_market/core/connectivity/connectivity_cubit.dart';
import 'package:byepo_stock_market/core/connectivity/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockConnectivityService service;
  late StreamController<bool> statusController;

  setUp(() {
    service = MockConnectivityService();
    statusController = StreamController<bool>.broadcast();
    when(() => service.onStatusChanged)
        .thenAnswer((_) => statusController.stream);
  });

  tearDown(() => statusController.close());

  test('seeds ConnectivityOnline from service.isOnline == true', () async {
    when(() => service.isOnline).thenReturn(true);
    final cubit = ConnectivityCubit(service: service);

    expect(cubit.state, const ConnectivityOnline());

    await cubit.close();
  });

  test('seeds ConnectivityOffline from service.isOnline == false', () async {
    when(() => service.isOnline).thenReturn(false);
    final cubit = ConnectivityCubit(service: service);

    expect(cubit.state, const ConnectivityOffline());

    await cubit.close();
  });

  test('relays status changes from the service', () async {
    when(() => service.isOnline).thenReturn(true);
    final cubit = ConnectivityCubit(service: service);

    statusController.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, const ConnectivityOffline());

    statusController.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, const ConnectivityOnline());

    await cubit.close();
  });
}
