import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/features/watchlist/domain/repositories/watchlist_repository.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/remove_from_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/watchlist_symbol_params.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

void main() {
  late RemoveFromWatchlist useCase;
  late MockWatchlistRepository repository;

  setUp(() {
    repository = MockWatchlistRepository();
    useCase = RemoveFromWatchlist(repository);
  });

  test('delegates to the repository with the given symbol', () async {
    when(() => repository.removeSymbol('AAPL'))
        .thenAnswer((_) async => const Right(<String>[]));

    final result = await useCase(const WatchlistSymbolParams('AAPL'));

    expect(result.getOrElse(() => []), isEmpty);
    verify(() => repository.removeSymbol('AAPL')).called(1);
  });

  test('propagates a Failure unchanged', () async {
    when(() => repository.removeSymbol(any()))
        .thenAnswer((_) async => const Left(CacheFailure()));

    final result = await useCase(const WatchlistSymbolParams('AAPL'));

    expect(result, const Left(CacheFailure()));
  });
}
