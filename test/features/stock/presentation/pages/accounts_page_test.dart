import 'package:byepo_stock_market/core/theme/theme_cubit.dart';
import 'package:byepo_stock_market/features/stock/presentation/pages/accounts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ThemeCubit themeCubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    themeCubit = ThemeCubit(prefs: await SharedPreferences.getInstance());
  });

  tearDown(() => themeCubit.close());

  Widget host() => MaterialApp(
        home: BlocProvider<ThemeCubit>.value(
          value: themeCubit,
          child: const AccountsPage(),
        ),
      );

  testWidgets('defaults to the System segment selected', (tester) async {
    await tester.pumpWidget(host());

    final segmented = tester.widget<SegmentedButton<ThemeMode>>(
      find.byType(SegmentedButton<ThemeMode>),
    );
    expect(segmented.selected, {ThemeMode.system});
  });

  testWidgets(
    'tapping Dark updates the Cubit and persists the choice',
    (tester) async {
      await tester.pumpWidget(host());

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(themeCubit.state, ThemeMode.dark);
    },
  );

  testWidgets(
    'tapping Light updates the Cubit and persists the choice',
    (tester) async {
      await tester.pumpWidget(host());

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      expect(themeCubit.state, ThemeMode.light);
    },
  );
}
