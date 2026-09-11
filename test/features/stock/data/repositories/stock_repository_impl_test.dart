import 'package:byepo_stock_market/core/error/exceptions.dart';
import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/features/stock/data/datasources/mock_stock_data.dart';
import 'package:byepo_stock_market/features/stock/data/datasources/stock_local_data_source.dart';
import 'package:byepo_stock_market/features/stock/data/datasources/stock_remote_data_source.dart';
import 'package:byepo_stock_market/features/stock/data/models/company_profile_model.dart';
import 'package:byepo_stock_market/features/stock/data/models/quote_model.dart';
import 'package:byepo_stock_market/features/stock/data/repositories/stock_repository_impl.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockStockRemoteDataSource extends Mock implements StockRemoteDataSource {}

class MockStockLocalDataSource extends Mock implements StockLocalDataSource {}

const _tQuote = QuoteModel(
  current: 100,
  change: 1.5,
  percentChange: 1.5,
  high: 101,
  low: 98,
  open: 99,
  previousClose: 98.5,
);

const _tProfile = CompanyProfileModel(
  name: 'Apple Inc',
  logo: 'https://logo/aapl.png',
  exchange: 'NASDAQ',
  industry: 'Technology',
  marketCapitalization: 3900000,
  currency: 'USD',
);

void main() {
  late StockRepositoryImpl repository;
  late MockStockRemoteDataSource remote;
  late MockStockLocalDataSource local;

  setUpAll(() => registerFallbackValue(_tProfile));

  setUp(() {
    remote = MockStockRemoteDataSource();
    local = MockStockLocalDataSource();
    repository = StockRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      mockDataSource: StaticStockMockDataSource(),
    );
    when(() => local.cacheProfile(any(), any())).thenReturn(null);
  });

  group('getStockDetails', () {
    test('merges quote + profile into a Stock and caches the profile',
        () async {
      when(() => local.getCachedProfile('AAPL')).thenReturn(null);
      when(() => remote.getQuote('AAPL')).thenAnswer((_) async => _tQuote);
      when(() => remote.getProfile('AAPL')).thenAnswer((_) async => _tProfile);

      final result = await repository.getStockDetails('AAPL');

      final stock = result.getOrElse(() => throw StateError('expected Right'));
      expect(stock.symbol, 'AAPL');
      expect(stock.companyName, 'Apple Inc');
      expect(stock.logoUrl, 'https://logo/aapl.png');
      expect(stock.ltp, 100);
      expect(stock.change, 1.5);
      expect(stock.previousClose, 98.5);
      expect(stock.exchange, 'NASDAQ');
      expect(stock.industry, 'Technology');
      expect(stock.marketCap, 3900000);
      verify(() => local.cacheProfile('AAPL', _tProfile)).called(1);
    });

    test('reuses a cached profile without hitting /stock/profile2', () async {
      when(() => local.getCachedProfile('AAPL')).thenReturn(_tProfile);
      when(() => remote.getQuote('AAPL')).thenAnswer((_) async => _tQuote);

      final result = await repository.getStockDetails('AAPL');

      expect(result.isRight(), isTrue);
      verifyNever(() => remote.getProfile(any()));
      verifyNever(() => local.cacheProfile(any(), any()));
    });

    test('maps ServerException to ServerFailure', () async {
      when(() => local.getCachedProfile('BAD')).thenReturn(_tProfile);
      when(() => remote.getQuote('BAD'))
          .thenThrow(const ServerException('Unknown symbol'));

      final result = await repository.getStockDetails('BAD');

      expect(result, const Left(ServerFailure('Unknown symbol')));
    });

    test('maps a connection-error DioException to NetworkFailure', () async {
      // 'ZZZZ' has no static-fallback coverage, so this still exercises the
      // exception -> Failure mapping instead of the mock-fallback path.
      when(() => local.getCachedProfile('ZZZZ')).thenReturn(_tProfile);
      when(() => remote.getQuote('ZZZZ')).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/quote'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.getStockDetails('ZZZZ');

      expect(result, const Left(NetworkFailure()));
    });

    test('maps a bad-response DioException to ServerFailure with the status',
        () async {
      when(() => local.getCachedProfile('ZZZZ')).thenReturn(_tProfile);
      final options = RequestOptions(path: '/quote');
      when(() => remote.getQuote('ZZZZ')).thenThrow(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 429),
        ),
      );

      final result = await repository.getStockDetails('ZZZZ');

      expect(
        result,
        const Left(ServerFailure('Request failed with status 429')),
      );
    });

    test('falls back to static mock data when a covered symbol fails',
        () async {
      when(() => local.getCachedProfile('AAPL')).thenReturn(_tProfile);
      when(() => remote.getQuote('AAPL'))
          .thenThrow(const ServerException('Rate limit exceeded'));

      final result = await repository.getStockDetails('AAPL');

      final stock = result.getOrElse(() => throw StateError('expected Right'));
      expect(stock.symbol, 'AAPL');
      expect(stock, StaticStockMockDataSource().getStock('AAPL'));
    });
  });

  group('getStocks', () {
    test('returns one Stock per symbol, in order', () async {
      when(() => local.getCachedProfile(any())).thenReturn(_tProfile);
      when(() => remote.getQuote(any())).thenAnswer((_) async => _tQuote);

      final result = await repository.getStocks(['AAPL', 'MSFT', 'GOOGL']);

      final stocks = result.getOrElse(() => throw StateError('expected Right'));
      expect(stocks.map((s) => s.symbol).toList(), ['AAPL', 'MSFT', 'GOOGL']);
    });

    test('one uncovered failing symbol fails the whole list', () async {
      // 'ZZZZ' has no static-fallback coverage, so this preserves the
      // original atomic-failure contract for symbols mock data can't cover.
      when(() => local.getCachedProfile(any())).thenReturn(_tProfile);
      when(() => remote.getQuote('AAPL')).thenAnswer((_) async => _tQuote);
      when(() => remote.getQuote('ZZZZ'))
          .thenThrow(const ServerException('boom'));

      final result = await repository.getStocks(['AAPL', 'ZZZZ']);

      expect(result, const Left(ServerFailure('boom')));
    });

    test(
        'a covered failing symbol falls back to mock data instead of '
        'failing the list', () async {
      when(() => local.getCachedProfile(any())).thenReturn(_tProfile);
      when(() => remote.getQuote('AAPL')).thenAnswer((_) async => _tQuote);
      when(() => remote.getQuote('MSFT'))
          .thenThrow(const ServerException('Rate limit exceeded'));

      final result = await repository.getStocks(['AAPL', 'MSFT']);

      final stocks = result.getOrElse(() => throw StateError('expected Right'));
      expect(stocks.map((s) => s.symbol).toList(), ['AAPL', 'MSFT']);
      expect(stocks[1], StaticStockMockDataSource().getStock('MSFT'));
    });
  });

  group('searchStocks', () {
    test('delegates to the remote data source', () async {
      when(() => remote.searchSymbols('app')).thenAnswer((_) async => []);

      final result = await repository.searchStocks('app');

      expect(result.isRight(), isTrue);
      verify(() => remote.searchSymbols('app')).called(1);
    });

    test('falls back to static mock search when the remote call fails',
        () async {
      when(() => remote.searchSymbols('amd'))
          .thenThrow(const ServerException('Rate limit exceeded'));

      final result = await repository.searchStocks('amd');

      final results =
          result.getOrElse(() => throw StateError('expected Right'));
      expect(results, isNotEmpty);
      expect(
          results.every((r) => r.symbol.toLowerCase().contains('amd')), isTrue);
    });
  });
}
