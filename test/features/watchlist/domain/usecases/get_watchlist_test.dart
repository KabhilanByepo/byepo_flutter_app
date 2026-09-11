import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/core/usecase/usecase.dart';
import 'package:byepo_stock_market/features/watchlist/domain/repositories/watchlist_repository.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/get_watchlist.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchlistRepository extends Mock implements WatchlistRepository {}

void main() {
  late GetWatchlist useCase;
  late MockWatchlistRepository repository;

  setUp(() {
    repository = MockWatchlistRepository();
    useCase = GetWatchlist(repository);
  });

  test('delegates to the repository', () async {
    when(() => repository.getWatchlist())
        .thenAnswer((_) async => const Right(['AAPL', 'MSFT']));

    final result = await useCase(const NoParams());

    expect(result.getOrElse(() => []), ['AAPL', 'MSFT']);
    verify(() => repository.getWatchlist()).called(1);
  });

  test('propagates a Failure unchanged', () async {
    when(() => repository.getWatchlist())
        .thenAnswer((_) async => const Left(CacheFailure()));

    final result = await useCase(const NoParams());

    expect(result, const Left(CacheFailure()));
  });
}
