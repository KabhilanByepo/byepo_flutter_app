import 'package:bloc_test/bloc_test.dart';
import 'package:byepo_stock_market/core/theme/app_theme.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_cubit.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/cubit/watchlist_state.dart';
import 'package:byepo_stock_market/features/watchlist/presentation/widgets/watchlist_toggle_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchlistCubit extends MockCubit<WatchlistState>
    implements WatchlistCubit {}

void main() {
  late MockWatchlistCubit cubit;

  Widget host() => MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<WatchlistCubit>.value(
          value: cubit,
          child: const Scaffold(body: WatchlistToggleIcon(symbol: 'AAPL')),
        ),
      );

  setUp(() {
    cubit = MockWatchlistCubit();
    when(() => cubit.add(any())).thenAnswer((_) async {});
    when(() => cubit.remove(any())).thenAnswer((_) async {});
  });

  testWidgets('shows an outline star and calls add() when not watched',
      (tester) async {
    when(() => cubit.contains(any())).thenReturn(false);
    whenListen(
      cubit,
      const Stream<WatchlistState>.empty(),
      initialState: const WatchlistLoaded([]),
    );

    await tester.pumpWidget(host());

    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);

    await tester.tap(find.byType(IconButton));
    verify(() => cubit.add('AAPL')).called(1);
    verifyNever(() => cubit.remove(any()));
  });

  testWidgets('shows a filled star and calls remove() when already watched',
      (tester) async {
    when(() => cubit.contains(any())).thenReturn(true);
    whenListen(
      cubit,
      const Stream<WatchlistState>.empty(),
      initialState: const WatchlistLoaded(['AAPL']),
    );

    await tester.pumpWidget(host());

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNothing);

    await tester.tap(find.byType(IconButton));
    verify(() => cubit.remove('AAPL')).called(1);
    verifyNever(() => cubit.add(any()));
  });
}
