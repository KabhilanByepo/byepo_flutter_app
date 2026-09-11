import 'package:bloc_test/bloc_test.dart';
import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/features/stock/domain/entities/stock.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/get_stock_details.dart';
import 'package:byepo_stock_market/features/stock/presentation/cubit/stock_details_cubit.dart';
import 'package:byepo_stock_market/features/stock/presentation/cubit/stock_details_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetStockDetails extends Mock implements GetStockDetails {}

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
  late MockGetStockDetails getStockDetails;

  setUpAll(() => registerFallbackValue(const SymbolParams('')));

  setUp(() => getStockDetails = MockGetStockDetails());

  blocTest<StockDetailsCubit, StockDetailsState>(
    'load without a seed emits [Loading, Loaded]',
    build: () => StockDetailsCubit(getStockDetails: getStockDetails),
    setUp: () => when(() => getStockDetails(any()))
        .thenAnswer((_) async => const Right(_tStock)),
    act: (cubit) => cubit.load('AAPL'),
    expect: () => const [
      StockDetailsLoading(),
      StockDetailsLoaded(_tStock),
    ],
  );

  blocTest<StockDetailsCubit, StockDetailsState>(
    'load with a seed carries it on the Loading state',
    build: () => StockDetailsCubit(getStockDetails: getStockDetails),
    setUp: () => when(() => getStockDetails(any()))
        .thenAnswer((_) async => const Right(_tStock)),
    act: (cubit) => cubit.load('AAPL', seed: _tStock),
    expect: () => const [
      StockDetailsLoading(seed: _tStock),
      StockDetailsLoaded(_tStock),
    ],
  );

  blocTest<StockDetailsCubit, StockDetailsState>(
    'load emits [Loading, Error] on failure',
    build: () => StockDetailsCubit(getStockDetails: getStockDetails),
    setUp: () => when(() => getStockDetails(any()))
        .thenAnswer((_) async => const Left(ServerFailure('Unknown symbol'))),
    act: (cubit) => cubit.load('BAD'),
    expect: () => const [
      StockDetailsLoading(),
      StockDetailsError('Unknown symbol'),
    ],
  );

  blocTest<StockDetailsCubit, StockDetailsState>(
    'a silent refresh failure keeps the last Loaded state',
    build: () => StockDetailsCubit(getStockDetails: getStockDetails),
    seed: () => const StockDetailsLoaded(_tStock),
    setUp: () => when(() => getStockDetails(any()))
        .thenAnswer((_) async => const Left(NetworkFailure())),
    act: (cubit) => cubit.refresh('AAPL'),
    expect: () => const <StockDetailsState>[],
  );
}
