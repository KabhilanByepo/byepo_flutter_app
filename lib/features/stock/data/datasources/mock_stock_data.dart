import '../../domain/entities/stock.dart';
import '../../domain/entities/stock_search_result.dart';

/// Static/mock stand-in for a live quote, used only when the real API can't
/// provide one (missing fields, rate-limited, unreachable) — see
/// [StockRepositoryImpl]'s `_withMockFallback`. Exists solely to satisfy that
/// requirement and can be deleted, along with its DI registration
/// (`injection_container.dart`) and the `mockDataSource` constructor param on
/// `StockRepositoryImpl`, with no other code changes required.
abstract class StockMockDataSource {
  /// A plausible static [Stock] for [symbol], or `null` if it isn't covered.
  Stock? getStock(String symbol);

  /// Static search results whose symbol or company name contains [query].
  List<StockSearchResult> search(String query);
}

class StaticStockMockDataSource implements StockMockDataSource {
  @override
  Stock? getStock(String symbol) {
    final target = symbol.toUpperCase();
    for (final stock in kMockStocks) {
      if (stock.symbol == target) return stock;
    }
    return null;
  }

  @override
  List<StockSearchResult> search(String query) {
    final q = query.toLowerCase();
    return kMockStocks
        .where((stock) =>
            stock.symbol.toLowerCase().contains(q) ||
            stock.companyName.toLowerCase().contains(q))
        .map((stock) => StockSearchResult(
              symbol: stock.symbol,
              description: stock.companyName,
              displaySymbol: stock.symbol,
              type: 'Common Stock',
            ))
        .toList();
  }
}

/// Covers every `kDashboardSymbols` entry (so the Dashboard can always render
/// a full screen) plus a handful of extra well-known tickers, so search has
/// more than the curated 12 to demonstrate against. `logoUrl` is left empty
/// everywhere (no static logo assets are bundled) — `StockCard`'s existing
/// letter-avatar fallback already handles that, same as any other missing
/// logo URL.
const List<Stock> kMockStocks = [
  Stock(
    symbol: 'AAPL',
    companyName: 'Apple Inc',
    logoUrl: '',
    ltp: 227.50,
    change: 1.85,
    changePercent: 0.82,
    open: 226.10,
    high: 228.40,
    low: 225.30,
    previousClose: 225.65,
    exchange: 'NASDAQ',
    industry: 'Technology',
    marketCap: 3450000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'MSFT',
    companyName: 'Microsoft Corporation',
    logoUrl: '',
    ltp: 421.30,
    change: -2.10,
    changePercent: -0.50,
    open: 423.00,
    high: 424.60,
    low: 419.80,
    previousClose: 423.40,
    exchange: 'NASDAQ',
    industry: 'Technology',
    marketCap: 3130000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'GOOGL',
    companyName: 'Alphabet Inc',
    logoUrl: '',
    ltp: 172.85,
    change: 0.95,
    changePercent: 0.55,
    open: 171.90,
    high: 173.50,
    low: 171.20,
    previousClose: 171.90,
    exchange: 'NASDAQ',
    industry: 'Technology',
    marketCap: 2140000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'AMZN',
    companyName: 'Amazon.com Inc',
    logoUrl: '',
    ltp: 186.40,
    change: 2.30,
    changePercent: 1.25,
    open: 184.10,
    high: 187.00,
    low: 183.90,
    previousClose: 184.10,
    exchange: 'NASDAQ',
    industry: 'Consumer Cyclical',
    marketCap: 1950000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'NVDA',
    companyName: 'NVIDIA Corporation',
    logoUrl: '',
    ltp: 118.20,
    change: 3.40,
    changePercent: 2.96,
    open: 114.80,
    high: 119.50,
    low: 114.10,
    previousClose: 114.80,
    exchange: 'NASDAQ',
    industry: 'Technology',
    marketCap: 2900000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'META',
    companyName: 'Meta Platforms Inc',
    logoUrl: '',
    ltp: 512.60,
    change: -4.75,
    changePercent: -0.92,
    open: 517.35,
    high: 519.00,
    low: 510.20,
    previousClose: 517.35,
    exchange: 'NASDAQ',
    industry: 'Technology',
    marketCap: 1300000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'TSLA',
    companyName: 'Tesla Inc',
    logoUrl: '',
    ltp: 248.90,
    change: 6.20,
    changePercent: 2.55,
    open: 242.70,
    high: 251.30,
    low: 241.80,
    previousClose: 242.70,
    exchange: 'NASDAQ',
    industry: 'Consumer Cyclical',
    marketCap: 792000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'NFLX',
    companyName: 'Netflix Inc',
    logoUrl: '',
    ltp: 684.15,
    change: -1.55,
    changePercent: -0.23,
    open: 685.70,
    high: 689.90,
    low: 680.40,
    previousClose: 685.70,
    exchange: 'NASDAQ',
    industry: 'Communication Services',
    marketCap: 295000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'JPM',
    companyName: 'JPMorgan Chase & Co',
    logoUrl: '',
    ltp: 213.40,
    change: 0.80,
    changePercent: 0.38,
    open: 212.60,
    high: 214.10,
    low: 211.90,
    previousClose: 212.60,
    exchange: 'NYSE',
    industry: 'Financial Services',
    marketCap: 610000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'V',
    companyName: 'Visa Inc',
    logoUrl: '',
    ltp: 279.75,
    change: 1.10,
    changePercent: 0.40,
    open: 278.65,
    high: 280.90,
    low: 277.50,
    previousClose: 278.65,
    exchange: 'NYSE',
    industry: 'Financial Services',
    marketCap: 570000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'DIS',
    companyName: 'The Walt Disney Company',
    logoUrl: '',
    ltp: 96.30,
    change: -0.45,
    changePercent: -0.46,
    open: 96.75,
    high: 97.40,
    low: 95.80,
    previousClose: 96.75,
    exchange: 'NYSE',
    industry: 'Communication Services',
    marketCap: 175000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'KO',
    companyName: 'The Coca-Cola Company',
    logoUrl: '',
    ltp: 63.85,
    change: 0.20,
    changePercent: 0.31,
    open: 63.65,
    high: 64.10,
    low: 63.40,
    previousClose: 63.65,
    exchange: 'NYSE',
    industry: 'Consumer Defensive',
    marketCap: 275000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'AMD',
    companyName: 'Advanced Micro Devices Inc',
    logoUrl: '',
    ltp: 142.10,
    change: 2.05,
    changePercent: 1.46,
    open: 140.05,
    high: 143.60,
    low: 139.70,
    previousClose: 140.05,
    exchange: 'NASDAQ',
    industry: 'Technology',
    marketCap: 230000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'INTC',
    companyName: 'Intel Corporation',
    logoUrl: '',
    ltp: 22.40,
    change: -0.30,
    changePercent: -1.32,
    open: 22.70,
    high: 22.95,
    low: 22.15,
    previousClose: 22.70,
    exchange: 'NASDAQ',
    industry: 'Technology',
    marketCap: 96000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'ADBE',
    companyName: 'Adobe Inc',
    logoUrl: '',
    ltp: 498.70,
    change: 3.15,
    changePercent: 0.64,
    open: 495.55,
    high: 501.20,
    low: 494.10,
    previousClose: 495.55,
    exchange: 'NASDAQ',
    industry: 'Technology',
    marketCap: 220000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'ORCL',
    companyName: 'Oracle Corporation',
    logoUrl: '',
    ltp: 178.25,
    change: 1.40,
    changePercent: 0.79,
    open: 176.85,
    high: 179.30,
    low: 176.20,
    previousClose: 176.85,
    exchange: 'NYSE',
    industry: 'Technology',
    marketCap: 495000,
    currency: 'USD',
  ),
  Stock(
    symbol: 'PYPL',
    companyName: 'PayPal Holdings Inc',
    logoUrl: '',
    ltp: 74.60,
    change: -0.85,
    changePercent: -1.13,
    open: 75.45,
    high: 75.90,
    low: 74.10,
    previousClose: 75.45,
    exchange: 'NASDAQ',
    industry: 'Financial Services',
    marketCap: 78000,
    currency: 'USD',
  ),
];
