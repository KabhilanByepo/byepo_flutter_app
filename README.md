# Byepo Stock Market

A small, production-shaped Flutter app for browsing live stock quotes, built as a Clean
Architecture reference implementation: **Flutter + Dart + Clean Architecture + Dio + Bloc/Cubit +
GoRouter + Finnhub API integration + performance + testing.**

## Overview

Splash screen → 3-tab bottom navigation (Dashboard / Watchlist / Accounts) → a curated Dashboard
of live stock quotes → server-side search → a full-screen details view for any symbol, including
via a deep link. Quote data comes from the [Finnhub](https://finnhub.io) free API.

## Features

- **Splash screen** — Byepo mark, holds ~2s, auto-navigates to the Dashboard.
- **Bottom navigation** — Dashboard / Watchlist / Accounts, selected tab always correct (derived
  from the URL, not local widget state).
- **Dashboard** — a curated list of quote cards (logo, symbol, company name, LTP, change,
  change %), pull-to-refresh, an optional 30s auto-refresh, and an in-place server-side search.
- **Stock details** — full quote (open/high/low/previous close/exchange/industry/market cap) for
  any symbol; works whether you tapped a card or opened `/stock-details/AAPL` cold.
- **Watchlist** — add/remove any symbol, persisted locally via `shared_preferences`; resolves saved
  symbols into full live quotes the same way the Dashboard does.
- **Accounts** — static placeholder screen.

## Tech stack

| Concern | Choice |
|---|---|
| Language / framework | Dart, Flutter (Material 3) |
| HTTP client | `dio` |
| State management | `flutter_bloc` (Cubit) |
| Navigation | `go_router` |
| Functional error handling | `dartz` (`Either<Failure, T>`) |
| DI / composition root | `get_it` |
| Value equality | `equatable` |
| Image caching | `cached_network_image` |
| Formatting | `intl` |
| Testing | `flutter_test`, `mocktail`, `bloc_test` |

## Architecture

Clean Architecture, feature-first:

- **Presentation** — widgets, Cubits, sealed states. Never imports `data/`, never talks to Dio or
  a repository implementation directly.
- **Domain** — entities, repository *contracts* (abstract), use cases. Pure Dart: no Flutter, no
  Dio, no JSON. This is what makes it unit-testable in milliseconds.
- **Data** — models (`fromJson`, extend the domain entity), data sources (raw Dio I/O), repository
  *implementations* (the single seam that maps exceptions to `Failure`s and composes multiple API
  calls into one entity).

```
lib/
├── core/
│   ├── constants/curated_symbols.dart      # the Dashboard's fixed symbol list
│   ├── di/injection_container.dart         # get_it composition root, wired once at startup
│   ├── error/{failures,exceptions}.dart    # Failure hierarchy / data-layer exceptions
│   ├── network/                            # shared Dio client (base URL, timeouts, auth header)
│   │   ├── api_config.dart
│   │   ├── auth_interceptor.dart
│   │   └── dio_client.dart
│   ├── router/app_router.dart              # the single GoRouter config
│   └── usecase/usecase.dart                # UseCase<Type, Params> + NoParams
│
├── features/
│   ├── splash/presentation/                # splash page + placeholder Byepo mark
│   └── stock/
│       ├── domain/
│       │   ├── entities/                   # Stock, StockSearchResult
│       │   ├── repositories/stock_repository.dart
│       │   └── usecases/                   # GetStocks, GetStockDetails, SearchStocks
│       ├── data/
│       │   ├── models/                     # QuoteModel, CompanyProfileModel, StockSearchResultModel
│       │   ├── datasources/                # StockRemoteDataSource (Dio), StockLocalDataSource (cache)
│       │   └── repositories/stock_repository_impl.dart
│       └── presentation/
│           ├── cubit/                      # DashboardCubit, StockSearchCubit, StockDetailsCubit
│           ├── pages/                      # Dashboard, Accounts, StockDetails
│           └── widgets/                    # AppShell (bottom nav), StockCard
│   └── watchlist/
│       ├── domain/
│       │   ├── repositories/watchlist_repository.dart
│       │   └── usecases/                   # AddToWatchlist, RemoveFromWatchlist, GetWatchlist
│       ├── data/
│       │   ├── datasources/watchlist_local_data_source.dart   # shared_preferences-backed
│       │   └── repositories/watchlist_repository_impl.dart
│       └── presentation/
│           ├── cubit/                      # WatchlistCubit, WatchlistStocksCubit
│           ├── pages/watchlist_page.dart
│           └── widgets/watchlist_toggle_icon.dart              # reused inside StockCard
│
└── main.dart                               # wires DI, hands the GoRouter to MaterialApp.router
```

## API integration

Quotes come from [Finnhub](https://finnhub.io)'s free tier (`https://finnhub.io/api/v1`, no
credit card required, **60 requests/minute**). A single `Stock` entity is assembled from **two**
calls, composed in `StockRepositoryImpl`:

- `GET /quote?symbol=AAPL` → `{c, h, l, o, pc, d, dp, t}` — `c` is the LTP, `d`/`dp` are change and
  change %; Finnhub mixes `int`/`double` JSON numbers, so parsing guards with `is! num` rather than
  a specific numeric type.
- `GET /stock/profile2?symbol=AAPL` → `{name, logo, exchange, finnhubIndustry,
  marketCapitalization, currency, ...}` — company info, including a real logo URL (rendered via
  `cached_network_image`, with a `CircleAvatar` fallback on error/empty URL).
- `GET /search?q=apple` → `{count, result: [{symbol, description, displaySymbol, type}]}` — the
  Dashboard's search field.

Auth is an `X-Finnhub-Token` header, added to every request by `AuthInterceptor` so the token never
appears in a logged/handwritten URL. Finnhub uses ordinary HTTP status codes for errors (a bad
symbol comes back as an all-zero/empty `200`, not an error status); `StockRemoteDataSourceImpl`
turns a malformed/unexpected body into a `ServerException`, and lets `DioException` propagate
untouched for network/HTTP failures.

The API key is supplied at build/test time and never committed:

```bash
flutter run --dart-define=FINNHUB_API_KEY=your_free_key
```

Get a free key at <https://finnhub.io/dashboard>. Without it, `main()` skips DI/GoRouter entirely
and shows a standalone "Missing Finnhub API key" screen with the exact command to run — in both
debug and release builds, instead of letting the request fail later. (`DioClient` still asserts on
an empty key too, as defense-in-depth for any other call path.)

The free tier only covers **US-listed tickers, priced in USD** — the Dashboard's curated list
(`core/constants/curated_symbols.dart`) is 12 US large-caps (AAPL, MSFT, GOOGL, ...). The brief's
`₹1,420.50` example is illustrative; the app derives the currency symbol from each quote's
`currency` field.

## Static fallback data

When a symbol's live fetch fails (network error, unparseable response, an occasional rate limit)
**in a debug build only**, `StockRepositoryImpl` falls back to a fixed, plausible `Stock` for that
symbol instead of failing the screen — useful for demoing the app offline or if Finnhub is briefly
unreachable. This is gated by `kDebugMode`: a release build never shows fabricated prices as if
they were real, and always surfaces the normal `Error`/Retry state on failure instead. Finnhub's
free tier (60 req/min, no daily cap) makes hitting this in practice uncommon — it exists mainly to
satisfy the spec's static-fallback requirement and to keep the app demoable without a network
connection.

- The fallback data lives in one file, `lib/features/stock/data/datasources/mock_stock_data.dart`
  (`kMockStocks` + `StaticStockMockDataSource`), and is reached through a third injected data
  source (`StockMockDataSource`) — the same pattern as `StockRemoteDataSource`/
  `StockLocalDataSource`. It covers the 12 curated Dashboard symbols plus a handful of extra
  tickers (AMD, INTC, ADBE, ORCL, PYPL) purely so search fallback has more to match against. Its
  entries have no logo (`logoUrl: ''`), so a card backed by fallback data shows a letter avatar
  instead of the real company logo live data would have.
- It's **per-symbol, not whole-screen**: one failing symbol among twelve falls back on its own,
  silently mixed in with whatever did load live — it doesn't blank out the rest of the Dashboard.
- There's **no visual difference** between live and fallback data beyond the missing logo — same
  `StockCard`, same details screen, no badge. A symbol with no fallback coverage (e.g. most live
  search results) still shows the normal error on failure, in both debug and release.
- To remove this feature entirely: delete `mock_stock_data.dart`, the `mockDataSource` constructor
  parameter and DI registration in `stock_repository_impl.dart`/`injection_container.dart`, and the
  `_withMockFallback` helper — nothing else depends on it.

## State management

```
DashboardPage
    ↓ context.read<DashboardCubit>().load()
DashboardCubit                         (orchestration only — no Dio, no JSON)
    ↓ GetStocks(SymbolsParams(kDashboardSymbols))
StockRepository (contract)
    ↓
StockRepositoryImpl                    (composes /quote + /stock/profile2, maps exceptions)
    ↓
StockRemoteDataSource + StockLocalDataSource
    ↓
Dio  →  Finnhub
```

Every Cubit exposes an exhaustive `sealed` state and a predictable flow:

```
Initial → Loading → Loaded / Empty / Error
```

- `DashboardState` — `Initial / Loading / Loaded(stocks, autoRefreshing) / Empty / Error(message)`.
- `StockSearchState` — same shape, for the debounced search field.
- `StockDetailsState` — `Initial / Loading(seed?) / Loaded(stock) / Error(message)` (no `Empty`: a
  single symbol either resolves or it doesn't).

`DashboardLoaded` / `Empty` are always distinct states — the UI never infers "no data" from an
empty list. Pages render with `BlocBuilder` + a Dart 3 `switch` expression over the sealed state,
with a Retry button on every error.

## Navigation

`go_router` is the only navigation API used in the app (`context.go` / `context.push`, no
`Navigator.push`). Routes:

```
/splash
/dashboard          ┐
/watchlist          ├─ StatefulShellRoute.indexedStack (bottom-nav tabs)
/accounts           ┘
/stock-details/:symbol
```

- The three tabs are branches of a `StatefulShellRoute.indexedStack`: each keeps its own
  navigation stack and widget state, and the selected tab (`navigationShell.currentIndex`) is
  always derived from the URL — never local `setState`.
- `/stock-details/:symbol` is a **top-level route on the root navigator** (full-screen, no bottom
  bar), reachable identically from a Dashboard card, a search result, or a cold deep link. Because
  the shell subtree is never touched, popping back always lands on the correct tab.
- A tapped card passes the already-fetched `Stock` via `extra` so the details screen can render
  instantly; a deep link has no `extra`, so the screen always fetches by symbol regardless.
- Unmatched routes hit `errorBuilder` → a "Page not found" screen with a way back to the Dashboard.

## Performance considerations

- `ListView.builder` for every list (Dashboard, search results) — only visible rows are built.
- `cached_network_image` for company logos, with a `CircleAvatar` fallback on error/empty URL.
- **No "load everything"**: the Dashboard tracks a small curated symbol list instead of every
  tradeable symbol; the search field hits `SYMBOL_SEARCH` server-side instead of filtering a local
  copy.
- **Chunked concurrency**: `StockRepositoryImpl` fetches the curated list in chunks of 5 symbols
  (`Future.wait`) rather than firing all of them at once, to keep bursts small against Finnhub's
  60-calls/minute limit.
- **In-memory profile cache** (`StockLocalDataSource`): a company profile (name/exchange/industry/
  market cap) rarely changes, so it's fetched once per session. A refresh only re-hits the quote
  endpoint — cutting a 12-symbol refresh from 24 calls to 12 — and the details screen reuses a
  profile the Dashboard already fetched.
- **Debounced search** (~350ms) — a keystroke doesn't fire a request until typing pauses.
- **Controlled refresh**: auto-refresh is off by default, fixed at 30s, toggled explicitly; a
  background tick is silent (no spinner) and never replaces a good list with an error.
- `const` constructors throughout the widget tree; sealed/`Equatable` states avoid rebuilding on
  no-op state changes.

## Testing scenarios

Unit tests mirror `lib/` under `test/features/{stock,watchlist}/`:

- **Model parsing** (`quote_model_test.dart`, `company_profile_model_test.dart`) — success,
  int-vs-double numeric parsing, null `d`/`dp` tolerance, malformed fields, and Finnhub's
  "unknown symbol" shape (an all-zero quote / an empty profile object).
- **Repository** (`stock_repository_impl_test.dart`) — quote+profile merge, the profile
  cache-hit path (`verifyNever` on the second profile call), a `getStocks` success and a
  one-symbol failure (for a symbol with no mock coverage), every `DioException` → `Failure`
  mapping, and the static-fallback path for `getStockDetails`/`getStocks`/`searchStocks` when a
  covered symbol's live fetch fails.
- **Mock data source** (`mock_stock_data_test.dart`) — symbol/company-name lookup and search
  matching, case-insensitively.
- **Use cases** (`get_stocks_test.dart`, `get_stock_details_test.dart`) — delegation and
  Left/Right propagation.
- **Cubits** (`dashboard_cubit_test.dart`, `stock_search_cubit_test.dart`,
  `stock_details_cubit_test.dart`, via `bloc_test`) — the full `Initial → Loading → Loaded/Empty/
  Error` transition set, plus a silent-refresh-keeps-last-good-state case.
- **Widgets** (`stock_card_test.dart`, `watchlist_toggle_icon_test.dart`) — symbol/name/price/change
  rendering, gain/loss coloring, tap callback, watchlisted/not-watchlisted icon state.
- **Navigation** (`stock_details_navigation_test.dart`) — tapping a `StockCard` on the real router
  opens the details route for that symbol; an unmatched route shows the error page.
- **Watchlist** (`watchlist_local_data_source_test.dart`, `watchlist_repository_impl_test.dart`,
  `add_to_watchlist_test.dart`, `remove_from_watchlist_test.dart`, `get_watchlist_test.dart`,
  `watchlist_cubit_test.dart`, `watchlist_stocks_cubit_test.dart`, `watchlist_page_test.dart`) —
  `shared_preferences` persistence, add/remove/list use cases, cache-failure mapping, and the
  Cubit/page state transitions for both the toggle state and the resolved-stocks list.

## Setup

```bash
flutter pub get
flutter run  --dart-define=FINNHUB_API_KEY=your_free_key   # needs a device/emulator
flutter test --dart-define=FINNHUB_API_KEY=test             # tests mock Dio; any value works
```

## Known limitations

- Finnhub's free tier is **US-only** — no NSE/BSE (₹) data; demo prices are in USD.
- The profile cache has **no TTL** — a company's name/exchange/market cap is fetched once per app
  session and never refreshed.
- `getStocks` fetches the curated list **atomically for uncovered symbols** — a symbol with no
  static-fallback coverage still fails the whole Dashboard load if its live fetch fails (matches
  the original `post` feature's all-or-nothing list fetch); this only matters in debug builds,
  since release builds never consult the fallback data at all.
- No golden tests; widget tests cover `StockCard`, `WatchlistToggleIcon`, and dashboard→details
  navigation only.

## Future improvements

- Best-effort partial Dashboard loads for uncovered symbols too (today this only helps symbols
  with static-fallback coverage, and only in debug builds).
- A dedicated `RateLimitFailure` + backoff for Finnhub's `429` responses, for release builds where
  static fallback never applies.
- A real Byepo logo asset in place of the drawn splash-screen placeholder.
- An "add to watchlist" action directly from search results, not just the Dashboard/Details cards.
- An Indian-market data provider, to make the `₹` pricing in the original brief literal.
