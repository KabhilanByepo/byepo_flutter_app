import '../models/company_profile_model.dart';

/// In-memory cache for company profiles.
///
/// A profile (name, logo, exchange, industry, market cap) is effectively static
/// for a session, while the quote changes constantly. Caching profiles means a
/// Dashboard refresh only re-hits the quote endpoint — Nx fewer calls against
/// Finnhub's free-tier limit — and the details screen reuses a profile the
/// Dashboard already fetched.
abstract class StockLocalDataSource {
  CompanyProfileModel? getCachedProfile(String symbol);
  void cacheProfile(String symbol, CompanyProfileModel profile);
}

class InMemoryStockLocalDataSource implements StockLocalDataSource {
  final Map<String, CompanyProfileModel> _profiles = {};

  @override
  CompanyProfileModel? getCachedProfile(String symbol) => _profiles[symbol];

  @override
  void cacheProfile(String symbol, CompanyProfileModel profile) {
    _profiles[symbol] = profile;
  }
}
