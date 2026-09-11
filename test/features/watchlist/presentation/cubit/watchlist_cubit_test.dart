import 'package:bloc_test/bloc_test.dart';
import 'package:byepo_stock_market/core/error/failures.dart';
import 'package:byepo_stock_market/core/usecase/usecase.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/add_to_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/get_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/remove_from_watchlist.dart';
import 'package:byepo_stock_market/features/watchlist/domain/usecases/watchlist_symbol_params.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_cubit.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetWatchlist extends Mock implements GetWatchlist {}

class MockAddToWatchlist extends Mock implements AddToWatchlist {}

class MockRemoveFromWatchlist extends Mock implements RemoveFromWatchlist {}

void main() {
  late MockGetWatchlist getWatchlist;
  late MockAddToWatchlist addToWatchlist;
  late MockRemoveFromWatchlist removeFromWatchlist;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const WatchlistSymbolParams(''));
  });

  setUp(() {
    getWatchlist = MockGetWatchlist();
    addToWatchlist = MockAddToWatchlist();
    removeFromWatchlist = MockRemoveFromWatchlist();
  });

  WatchlistCubit build() => WatchlistCubit(
        getWatchlist: getWatchlist,
        addToWatchlist: addToWatchlist,
        removeFromWatchlist: removeFromWatchlist,
      );

  blocTest<WatchlistCubit, WatchlistState>(
    'load emits [Loading, Loaded] on success',
    build: build,
    setUp: () => when(() => getWatchlist(any()))
        .thenAnswer((_) async => const Right(['AAPL'])),
    act: (cubit) => cubit.load(),
    expect: () => const [
      WatchlistLoading(),
      WatchlistLoaded(['AAPL']),
    ],
  );

  blocTest<WatchlistCubit, WatchlistState>(
    'load emits [Loading, Loaded([])] when nothing has ever been added',
    build: build,
    setUp: () => when(() => getWatchlist(any()))
        .thenAnswer((_) async => const Right(<String>[])),
    act: (cubit) => cubit.load(),
    expect: () => const [
      WatchlistLoading(),
      WatchlistLoaded(<String>[]),
    ],
  );

  blocTest<WatchlistCubit, WatchlistState>(
    'load emits [Loading, Error] on failure',
    build: build,
    setUp: () => when(() => getWatchlist(any()))
        .thenAnswer((_) async => const Left(CacheFailure('boom'))),
    act: (cubit) => cubit.load(),
    expect: () => const [WatchlistLoading(), WatchlistError('boom')],
  );

  blocTest<WatchlistCubit, WatchlistState>(
    'add appends a new symbol to the current list',
    build: build,
    seed: () => const WatchlistLoaded(['AAPL']),
    setUp: () => when(() => addToWatchlist(any()))
        .thenAnswer((_) async => const Right(['AAPL', 'MSFT'])),
    act: (cubit) => cubit.add('MSFT'),
    expect: () => const [
      WatchlistLoaded(['AAPL', 'MSFT']),
    ],
  );

  blocTest<WatchlistCubit, WatchlistState>(
    'adding an already-present symbol emits no new state (Cubit skips '
    'equal states)',
    build: build,
    seed: () => const WatchlistLoaded(['AAPL']),
    setUp: () => when(() => addToWatchlist(any()))
        .thenAnswer((_) async => const Right(['AAPL'])),
    act: (cubit) => cubit.add('AAPL'),
    expect: () => const <WatchlistState>[],
  );

  blocTest<WatchlistCubit, WatchlistState>(
    'remove drops a symbol from the current list',
    build: build,
    seed: () => const WatchlistLoaded(['AAPL', 'MSFT']),
    setUp: () => when(() => removeFromWatchlist(any()))
        .thenAnswer((_) async => const Right(['MSFT'])),
    act: (cubit) => cubit.remove('AAPL'),
    expect: () => const [
      WatchlistLoaded(['MSFT']),
    ],
  );

  blocTest<WatchlistCubit, WatchlistState>(
    'removing the last remaining symbol emits Loaded with an empty list',
    build: build,
    seed: () => const WatchlistLoaded(['AAPL']),
    setUp: () => when(() => removeFromWatchlist(any()))
        .thenAnswer((_) async => const Right(<String>[])),
    act: (cubit) => cubit.remove('AAPL'),
    expect: () => const [
      WatchlistLoaded(<String>[]),
    ],
  );

  group('contains', () {
    test('is false before anything has loaded', () async {
      final cubit = build();
      expect(cubit.contains('AAPL'), isFalse);
      await cubit.close();
    });

    test('is true for a present symbol, case-insensitively', () async {
      when(() => getWatchlist(any()))
          .thenAnswer((_) async => const Right(['AAPL']));
      final cubit = build();

      await cubit.load();

      expect(cubit.contains('aapl'), isTrue);
      expect(cubit.contains('MSFT'), isFalse);
      await cubit.close();
    });
  });
}
