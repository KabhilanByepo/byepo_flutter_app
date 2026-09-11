import 'package:byepo_stock_market/features/watchlist/data/datasources/watchlist_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesWatchlistLocalDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dataSource = SharedPreferencesWatchlistLocalDataSource(
      prefs: await SharedPreferences.getInstance(),
    );
  });

  test('getSymbols returns an empty list when nothing was ever saved',
      () async {
    expect(await dataSource.getSymbols(), isEmpty);
  });

  test('saveSymbols persists, and a later getSymbols reflects it', () async {
    await dataSource.saveSymbols(['AAPL', 'MSFT']);

    expect(await dataSource.getSymbols(), ['AAPL', 'MSFT']);
  });

  test('a second saveSymbols call fully replaces the prior list', () async {
    await dataSource.saveSymbols(['AAPL', 'MSFT']);
    await dataSource.saveSymbols(['GOOGL']);

    expect(await dataSource.getSymbols(), ['GOOGL']);
  });
}
