import 'package:byepo_stock_market/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to ThemeMode.system when nothing is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = ThemeCubit(prefs: await SharedPreferences.getInstance());

    expect(cubit.state, ThemeMode.system);
  });

  test('reads a previously persisted theme mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final cubit = ThemeCubit(prefs: await SharedPreferences.getInstance());

    expect(cubit.state, ThemeMode.dark);
  });

  test('setThemeMode emits and persists the new mode', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cubit = ThemeCubit(prefs: prefs);

    await cubit.setThemeMode(ThemeMode.dark);

    expect(cubit.state, ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');
  });

  test('setThemeMode is a no-op when the mode is unchanged', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = ThemeCubit(prefs: await SharedPreferences.getInstance());
    final states = <ThemeMode>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.setThemeMode(ThemeMode.system); // already the default state

    expect(states, isEmpty);
    await subscription.cancel();
  });
}
