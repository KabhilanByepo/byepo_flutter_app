import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/features/watchlist/data/datasources/watchlist_local_data_source.dart';
import 'package:byepo_stock_market/features/watchlist/data/repositories/watchlist_repository_impl.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchlistLocalDataSource extends Mock
    implements WatchlistLocalDataSource {}

/// dartz's `Right.==` compares its payload by `==`, which for `List` is
/// reference equality — so a freshly built list never equals a list
/// literal. Unwrap first and let `expect`'s deep list comparison do the work.
List<String> _symbols(Either<Failure, List<String>> result) =>
    result.getOrElse(() => throw StateError('expected Right'));

void main() {
  late WatchlistRepositoryImpl repository;
  late MockWatchlistLocalDataSource localDataSource;

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() {
    localDataSource = MockWatchlistLocalDataSource();
    repository = WatchlistRepositoryImpl(localDataSource: localDataSource);
  });

  test('getWatchlist returns the persisted symbols', () async {
    when(() => localDataSource.getSymbols())
        .thenAnswer((_) async => ['AAPL']);

    final result = await repository.getWatchlist();

    expect(_symbols(result), ['AAPL']);
  });

  group('addSymbol', () {
    test('appends a new symbol and persists the updated list', () async {
      when(() => localDataSource.getSymbols())
          .thenAnswer((_) async => ['AAPL']);
      when(() => localDataSource.saveSymbols(any())).thenAnswer((_) async {});

      final result = await repository.addSymbol('MSFT');

      expect(_symbols(result), ['AAPL', 'MSFT']);
      verify(() => localDataSource.saveSymbols(['AAPL', 'MSFT'])).called(1);
    });

    test('normalizes casing/whitespace before comparing and storing',
        () async {
      when(() => localDataSource.getSymbols())
          .thenAnswer((_) async => ['AAPL']);
      when(() => localDataSource.saveSymbols(any())).thenAnswer((_) async {});

      final result = await repository.addSymbol(' msft ');

      expect(_symbols(result), ['AAPL', 'MSFT']);
    });

    test('adding an already-present symbol is a no-op (dedupe)', () async {
      when(() => localDataSource.getSymbols())
          .thenAnswer((_) async => ['AAPL']);

      final result = await repository.addSymbol('aapl');

      expect(_symbols(result), ['AAPL']);
      verifyNever(() => localDataSource.saveSymbols(any()));
    });

    test('a thrown exception maps to CacheFailure', () async {
      when(() => localDataSource.getSymbols()).thenThrow(Exception('boom'));

      final result = await repository.addSymbol('AAPL');

      expect(result, const Left(CacheFailure('Exception: boom')));
    });
  });

  group('removeSymbol', () {
    test('removes a present symbol and persists the updated list', () async {
      when(() => localDataSource.getSymbols())
          .thenAnswer((_) async => ['AAPL', 'MSFT']);
      when(() => localDataSource.saveSymbols(any())).thenAnswer((_) async {});

      final result = await repository.removeSymbol('AAPL');

      expect(_symbols(result), ['MSFT']);
      verify(() => localDataSource.saveSymbols(['MSFT'])).called(1);
    });

    test('removing the last remaining symbol results in an empty list',
        () async {
      when(() => localDataSource.getSymbols())
          .thenAnswer((_) async => ['AAPL']);
      when(() => localDataSource.saveSymbols(any())).thenAnswer((_) async {});

      final result = await repository.removeSymbol('AAPL');

      expect(_symbols(result), isEmpty);
      verify(() => localDataSource.saveSymbols(const [])).called(1);
    });

    test('removing an absent symbol is a no-op', () async {
      when(() => localDataSource.getSymbols())
          .thenAnswer((_) async => ['AAPL']);

      final result = await repository.removeSymbol('MSFT');

      expect(_symbols(result), ['AAPL']);
      verifyNever(() => localDataSource.saveSymbols(any()));
    });
  });
}
