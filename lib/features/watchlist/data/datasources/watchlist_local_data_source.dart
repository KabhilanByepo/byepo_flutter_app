import 'package:shared_preferences/shared_preferences.dart';

/// Raw local I/O only — no dedupe, no ordering logic. Callers (the
/// repository) own that; this mirrors `StockLocalDataSource`'s role.
abstract class WatchlistLocalDataSource {
  /// Symbols persisted, in insertion order. `[]` if nothing was ever saved.
  Future<List<String>> getSymbols();

  /// Persists [symbols] verbatim, replacing whatever was stored before.
  Future<void> saveSymbols(List<String> symbols);
}

class SharedPreferencesWatchlistLocalDataSource
    implements WatchlistLocalDataSource {
  static const _key = 'watchlist_symbols';

  final SharedPreferences prefs;

  const SharedPreferencesWatchlistLocalDataSource({required this.prefs});

  @override
  Future<List<String>> getSymbols() async =>
      prefs.getStringList(_key) ?? const [];

  @override
  Future<void> saveSymbols(List<String> symbols) async {
    await prefs.setStringList(_key, symbols);
  }
}
