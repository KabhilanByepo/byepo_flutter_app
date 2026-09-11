import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';

/// Data-layer representation of Finnhub's `/quote` response.
///
/// ```json
/// { "c": 261.74, "h": 263.31, "l": 260.10, "o": 260.68, "pc": 259.71,
///   "d": 2.03, "dp": 0.7817, "t": 1694275200 }
/// ```
/// Finnhub mixes `int`/`double` JSON numbers depending on the value, so every
/// numeric field is guarded with `is! num` rather than `is! double`.
class QuoteModel extends Equatable {
  final double current; // c
  final double change; // d
  final double percentChange; // dp
  final double high; // h
  final double low; // l
  final double open; // o
  final double previousClose; // pc

  const QuoteModel({
    required this.current,
    required this.change,
    required this.percentChange,
    required this.high,
    required this.low,
    required this.open,
    required this.previousClose,
  });

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    final current = json['c'];
    final high = json['h'];
    final low = json['l'];
    final open = json['o'];
    final previousClose = json['pc'];

    if (current is! num ||
        high is! num ||
        low is! num ||
        open is! num ||
        previousClose is! num) {
      throw const ServerException('Malformed quote payload from server');
    }

    // Finnhub omits `d`/`dp` (change / change %) outside market hours.
    final change = json['d'];
    final percentChange = json['dp'];

    // Finnhub returns all-zero fields (HTTP 200) for an unknown symbol.
    if (current == 0 && high == 0 && low == 0 && previousClose == 0) {
      throw const ServerException('Unknown symbol');
    }

    return QuoteModel(
      current: current.toDouble(),
      change: change is num ? change.toDouble() : 0,
      percentChange: percentChange is num ? percentChange.toDouble() : 0,
      high: high.toDouble(),
      low: low.toDouble(),
      open: open.toDouble(),
      previousClose: previousClose.toDouble(),
    );
  }

  @override
  List<Object?> get props =>
      [current, change, percentChange, high, low, open, previousClose];
}
