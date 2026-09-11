import 'package:byepo_stock_market/core/error/exceptions.dart';
import 'package:byepo_stock_market/features/stock/data/models/quote_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a well-formed quote payload', () {
    final model = QuoteModel.fromJson(const {
      'c': 261.74,
      'h': 263.31,
      'l': 260.68,
      'o': 261.07,
      'pc': 259.71,
      'd': 2.03,
      'dp': 0.7817,
      't': 1694275200,
    });

    expect(model.current, 261.74);
    expect(model.change, 2.03);
    expect(model.percentChange, 0.7817);
    expect(model.high, 263.31);
    expect(model.low, 260.68);
    expect(model.open, 261.07);
    expect(model.previousClose, 259.71);
  });

  test('tolerates int-vs-double mixing in the JSON numbers', () {
    final model = QuoteModel.fromJson(const {
      'c': 100, // int, not double
      'h': 101,
      'l': 99,
      'o': 100,
      'pc': 99,
      'd': 1,
      'dp': 1,
    });

    expect(model.current, 100.0);
    expect(model.high, 101.0);
  });

  test('treats missing d/dp (outside market hours) as zero', () {
    final model = QuoteModel.fromJson(const {
      'c': 100.0,
      'h': 101.0,
      'l': 99.0,
      'o': 100.0,
      'pc': 99.0,
    });

    expect(model.change, 0);
    expect(model.percentChange, 0);
  });

  test('throws ServerException for an all-zero quote (unknown symbol)', () {
    expect(
      () => QuoteModel.fromJson(const {
        'c': 0,
        'h': 0,
        'l': 0,
        'o': 0,
        'pc': 0,
      }),
      throwsA(isA<ServerException>()),
    );
  });

  test('throws ServerException when a required field is not a number', () {
    expect(
      () => QuoteModel.fromJson(const {
        'c': 'oops',
        'h': 1,
        'l': 1,
        'o': 1,
        'pc': 1,
      }),
      throwsA(isA<ServerException>()),
    );
  });
}
