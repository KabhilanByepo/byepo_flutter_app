import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/features/stock/domain/entities/stock.dart';
import 'package:byepo_stock_market/features/stock/domain/repositories/stock_repository.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/get_stock_details.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStockRepository extends Mock implements StockRepository {}

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
  late GetStockDetails useCase;
  late MockStockRepository repository;

  setUp(() {
    repository = MockStockRepository();
    useCase = GetStockDetails(repository);
  });

  test('delegates to the repository for the given symbol', () async {
    when(() => repository.getStockDetails('AAPL'))
        .thenAnswer((_) async => const Right(_tStock));

    final result = await useCase(const SymbolParams('AAPL'));

    expect(result, const Right(_tStock));
    verify(() => repository.getStockDetails('AAPL')).called(1);
  });

  test('propagates a Failure unchanged', () async {
    when(() => repository.getStockDetails(any()))
        .thenAnswer((_) async => const Left(ServerFailure('Unknown symbol')));

    final result = await useCase(const SymbolParams('BAD'));

    expect(result, const Left(ServerFailure('Unknown symbol')));
  });
}
