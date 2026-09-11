import 'package:byepo_stock_market/core/error/exceptions.dart';
import 'package:byepo_stock_market/features/stock/data/models/company_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a well-formed profile2 payload', () {
    final model = CompanyProfileModel.fromJson(const {
      'name': 'Apple Inc',
      'logo': 'https://logo/aapl.png',
      'exchange': 'NASDAQ',
      'finnhubIndustry': 'Technology',
      'marketCapitalization': 3900000,
      'currency': 'USD',
    });

    expect(model.name, 'Apple Inc');
    expect(model.logo, 'https://logo/aapl.png');
    expect(model.exchange, 'NASDAQ');
    expect(model.industry, 'Technology');
    expect(model.marketCapitalization, 3900000);
    expect(model.currency, 'USD');
  });

  test('defaults missing industry / currency / market cap', () {
    final model = CompanyProfileModel.fromJson(const {
      'name': 'Apple Inc',
      'logo': 'https://logo/aapl.png',
      'exchange': 'NASDAQ',
    });

    expect(model.industry, 'Unknown');
    expect(model.currency, 'USD');
    expect(model.marketCapitalization, 0);
  });

  test('throws ServerException for an empty object (unknown symbol)', () {
    expect(
      () => CompanyProfileModel.fromJson(const {}),
      throwsA(isA<ServerException>()),
    );
  });

  test('throws ServerException when name is missing', () {
    expect(
      () => CompanyProfileModel.fromJson(const {
        'logo': 'https://logo/aapl.png',
        'exchange': 'NASDAQ',
      }),
      throwsA(isA<ServerException>()),
    );
  });
}
