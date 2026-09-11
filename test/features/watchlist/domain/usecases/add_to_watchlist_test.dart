import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/features/watchlist/domain/repositories/watchlist_repository.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/add_to_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/watchlist_symbol_params.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

void main() {
  late AddToWatchlist useCase;
  late MockWatchlistRepository repository;

  setUp(() {
    repository = MockWatchlistRepository();
    useCase = AddToWatchlist(repository);
  });

  test('delegates to the repository with the given symbol', () async {
    when(() => repository.addSymbol('AAPL'))
        .thenAnswer((_) async => const Right(['AAPL']));

    final result = await useCase(const WatchlistSymbolParams('AAPL'));

    expect(result.getOrElse(() => []), ['AAPL']);
    verify(() => repository.addSymbol('AAPL')).called(1);
  });

  test('propagates a Failure unchanged', () async {
    when(() => repository.addSymbol(any()))
        .thenAnswer((_) async => const Left(CacheFailure()));

    final result = await useCase(const WatchlistSymbolParams('AAPL'));

    expect(result, const Left(CacheFailure()));
  });
}
