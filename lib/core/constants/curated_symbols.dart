/// The fixed set of symbols the Dashboard shows.
///
/// Finnhub's free tier has no "all stocks" quote endpoint (and loading one
/// would be wasteful), so the Dashboard tracks a curated list of US
/// large-caps. Users reach anything else through the Dashboard search field.
const List<String> kDashboardSymbols = [
  'AAPL',
  'MSFT',
  'GOOGL',
  'AMZN',
  'NVDA',
  'META',
  'TSLA',
  'NFLX',
  'JPM',
  'V',
  'DIS',
  'KO',
];
