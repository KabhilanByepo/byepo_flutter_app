import 'package:byepo_stock_market/features/stock/data/datasources/mock_stock_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StaticStockMockDataSource dataSource;

  setUp(() => dataSource = StaticStockMockDataSource());

  group('getStock', () {
    test('returns the mock stock for a covered symbol', () {
      final stock = dataSource.getStock('AAPL');

      expect(stock, isNotNull);
      expect(stock!.symbol, 'AAPL');
      expect(stock.companyName, 'Apple Inc');
    });

    test('is case-insensitive', () {
      expect(dataSource.getStock('aapl')?.symbol, 'AAPL');
    });

    test('returns null for a symbol with no mock coverage', () {
      expect(dataSource.getStock('ZZZZ'), isNull);
    });
  });

  group('search', () {
    test('matches by symbol substring, case-insensitively', () {
      final results = dataSource.search('msf');

      expect(results, hasLength(1));
      expect(results.single.symbol, 'MSFT');
    });

    test('matches by company-name substring', () {
      final results = dataSource.search('walt disney');

      expect(results, hasLength(1));
      expect(results.single.symbol, 'DIS');
    });

    test('returns an empty list for no matches', () {
      expect(dataSource.search('no-such-company'), isEmpty);
    });
  });
}
