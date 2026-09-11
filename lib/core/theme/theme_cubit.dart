import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's Light/Dark/System choice via the app's existing
/// `SharedPreferences` singleton. Long-lived (registered once in `get_it`,
/// provided via `.value` at the app root), matching `WatchlistCubit`'s
/// pattern — its initial state is computed synchronously in the constructor,
/// so unlike `WatchlistCubit` it needs no separate `load()` call before
/// `runApp`.
class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'theme_mode';

  final SharedPreferences prefs;

  ThemeCubit({required this.prefs}) : super(_readInitial(prefs));

  static ThemeMode _readInitial(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await prefs.setString(_key, mode.name);
  }
}
