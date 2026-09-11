import 'package:intl/intl.dart';

/// Small display-formatting helpers shared by the stock card and details screen.

String currencySymbol(String code) => switch (code.toUpperCase()) {
      'USD' => r'$',
      'INR' => '₹',
      'EUR' => '€',
      'GBP' => '£',
      'JPY' => '¥',
      _ => '$code ',
    };

String formatPrice(double value, String currencyCode) {
  return NumberFormat.currency(
    symbol: currencySymbol(currencyCode),
    decimalDigits: 2,
  ).format(value);
}

String formatSigned(double value, {int decimals = 2}) {
  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(decimals)}';
}

String formatPercent(double value) => '${formatSigned(value)}%';

/// Expects market cap already normalized to millions of the listing currency
/// (see `CompanyProfileModel.fromJson`, which converts from whatever absolute
/// unit the provider reports).
String formatMarketCap(double millions) {
  if (millions <= 0) return '—';
  if (millions >= 1e6) return '${(millions / 1e6).toStringAsFixed(2)}T';
  if (millions >= 1e3) return '${(millions / 1e3).toStringAsFixed(2)}B';
  return '${millions.toStringAsFixed(0)}M';
}
