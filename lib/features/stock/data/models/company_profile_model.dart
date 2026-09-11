import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';

/// Data-layer representation of Finnhub's `/stock/profile2` response.
///
/// ```json
/// { "name": "Apple Inc", "logo": "https://...png", "exchange": "NASDAQ",
///   "finnhubIndustry": "Technology", "marketCapitalization": 3900000,
///   "currency": "USD", ... }
/// ```
/// `marketCapitalization` is already reported in millions of the listing
/// currency, unlike some other providers. Finnhub returns `{}` (HTTP 200)
/// for an unknown symbol.
class CompanyProfileModel extends Equatable {
  final String name;
  final String logo;
  final String exchange;
  final String industry;
  final double marketCapitalization;
  final String currency;

  const CompanyProfileModel({
    required this.name,
    required this.logo,
    required this.exchange,
    required this.industry,
    required this.marketCapitalization,
    required this.currency,
  });

  factory CompanyProfileModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    // Finnhub returns `{}` for an unknown symbol — fail loudly instead of
    // producing a blank profile.
    if (name is! String || name.isEmpty) {
      throw const ServerException('Unknown symbol or missing company profile');
    }

    final logo = json['logo'];
    final exchange = json['exchange'];
    if (logo is! String || exchange is! String) {
      throw const ServerException(
          'Malformed company profile payload from server');
    }

    final industry = json['finnhubIndustry'];
    final currency = json['currency'];
    final marketCapRaw = json['marketCapitalization'];

    return CompanyProfileModel(
      name: name,
      logo: logo,
      exchange: exchange,
      industry:
          industry is String && industry.isNotEmpty ? industry : 'Unknown',
      currency: currency is String && currency.isNotEmpty ? currency : 'USD',
      marketCapitalization: marketCapRaw is num ? marketCapRaw.toDouble() : 0,
    );
  }

  @override
  List<Object?> get props =>
      [name, logo, exchange, industry, marketCapitalization, currency];
}
