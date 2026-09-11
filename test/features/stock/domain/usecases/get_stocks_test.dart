import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/features/stock/domain/entities/stock.dart';
import 'package:byepo_stock_market/features/stock/domain/repositories/stock_repository.dart';
import 'package:byepo_stock_market/features/stock/domain/usecases/get_stocks.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStockRepository extends Mock implements StockRepository {}

Stock _stock(String symbol) => Stock(
      symbol: symbol,
      companyName: '$symbol Inc',
      logoUrl: '',
      ltp: 10,
      change: 1,
      changePercent: 1,
      open: 9,
      high: 11,
      low: 9,
      previousClose: 9,
      exchange: 'NASDAQ',
      industry: 'Tech',
      marketCap: 1,
      currency: 'USD',
    );

void main() {
  late GetStocks useCase;
  late MockStockRepository repository;

  setUp(() {
    repository = MockStockRepository();
    useCase = GetStocks(repository);
  });

  test('delegates to the repository with the given symbols', () async {
    final stocks = [_stock('AAPL'), _stock('MSFT')];
    when(() => repository.getStocks(['AAPL', 'MSFT']))
        .thenAnswer((_) async => Right(stocks));

    final result = await useCase(const SymbolsParams(['AAPL', 'MSFT']));

    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => []), stocks);
    verify(() => repository.getStocks(['AAPL', 'MSFT'])).called(1);
  });

  test('propagates a Failure unchanged', () async {
    when(() => repository.getStocks(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    final result = await useCase(const SymbolsParams(['AAPL']));

    expect(result, const Left(NetworkFailure()));
  });
}
