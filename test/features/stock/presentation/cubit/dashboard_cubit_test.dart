import 'package:bloc_test/bloc_test.dart';
import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/features/stock/domain/entities/stock.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/get_stocks.dart';
import 'package:byepo_stock_market/features/stock/presentation/cubit/dashboard_cubit.dart';
import 'package:byepo_stock_market/features/stock/presentation/cubit/dashboard_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetStocks extends Mock implements GetStocks {}

const _tStock = Stock(
  symbol: 'AAPL',
  companyName: 'Apple Inc',
  logoUrl: '',
  ltp: 100,
  change: 1,
  changePercent: 1,
  open: 99,
  high: 101,
  low: 98,
  previousClose: 99,
  exchange: 'NASDAQ',
  industry: 'Tech',
  marketCap: 1,
  currency: 'USD',
);

void main() {
  late MockGetStocks getStocks;

  setUpAll(() => registerFallbackValue(const SymbolsParams([])));

  setUp(() => getStocks = MockGetStocks());

  blocTest<DashboardCubit, DashboardState>(
    'load emits [Loading, Loaded] on success',
    build: () => DashboardCubit(getStocks: getStocks),
    setUp: () => when(() => getStocks(any()))
        .thenAnswer((_) async => const Right([_tStock])),
    act: (cubit) => cubit.load(),
    expect: () => const [
      DashboardLoading(),
      DashboardLoaded([_tStock]),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'load emits [Loading, Empty] when the API returns nothing',
    build: () => DashboardCubit(getStocks: getStocks),
    setUp: () => when(() => getStocks(any()))
        .thenAnswer((_) async => const Right(<Stock>[])),
    act: (cubit) => cubit.load(),
    expect: () => const [DashboardLoading(), DashboardEmpty()],
  );

  blocTest<DashboardCubit, DashboardState>(
    'load emits [Loading, Error] on failure',
    build: () => DashboardCubit(getStocks: getStocks),
    setUp: () => when(() => getStocks(any()))
        .thenAnswer((_) async => const Left(NetworkFailure())),
    act: (cubit) => cubit.load(),
    expect: () => const [
      DashboardLoading(),
      DashboardError('No internet connection'),
    ],
  );

  blocTest<DashboardCubit, DashboardState>(
    'a silent refresh failure keeps the last Loaded state',
    build: () => DashboardCubit(getStocks: getStocks),
    seed: () => const DashboardLoaded([_tStock]),
    setUp: () => when(() => getStocks(any()))
        .thenAnswer((_) async => const Left(NetworkFailure())),
    act: (cubit) => cubit.refresh(),
    expect: () => const <DashboardState>[],
  );

  test(
    'pauseForBackground stops the timer without changing the user\'s '
    'auto-refresh intent',
    () async {
      when(() => getStocks(any()))
          .thenAnswer((_) async => const Right([_tStock]));
      final cubit = DashboardCubit(getStocks: getStocks);

      cubit.toggleAutoRefresh();
      expect(cubit.isAutoRefreshing, isTrue);

      cubit.pauseForBackground();
      expect(
        cubit.isAutoRefreshing,
        isTrue,
        reason: 'backgrounding must not silently flip the user\'s toggle',
      );

      await cubit.close();
    },
  );

  blocTest<DashboardCubit, DashboardState>(
    'resumeForForeground fires exactly one silent refresh',
    build: () => DashboardCubit(getStocks: getStocks),
    seed: () => const DashboardLoaded([_tStock]),
    setUp: () => when(() => getStocks(any()))
        .thenAnswer((_) async => const Right([_tStock])),
    act: (cubit) => cubit.resumeForForeground(),
    verify: (_) => verify(() => getStocks(any())).called(1),
  );
}
