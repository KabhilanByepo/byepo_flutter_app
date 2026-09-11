import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/stock.dart';
import '../../domain/entities/stock_search_result.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/mock_stock_data.dart';
import '../datasources/stock_local_data_source.dart';
import '../datasources/stock_remote_data_source.dart';
import '../models/company_profile_model.dart';
import '../models/quote_model.dart';

/// Implements the domain contract. This is the ONLY layer allowed to catch
/// data-layer exceptions and translate them into domain [Failure]s, and the
/// place where a `/quote` and a `/stock/profile2` response are merged into one
/// [Stock].
class StockRepositoryImpl implements StockRepository {
  final StockRemoteDataSource remoteDataSource;
  final StockLocalDataSource localDataSource;
  final StockMockDataSource mockDataSource;

  const StockRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.mockDataSource,
  });

  /// Finnhub's free tier allows 60 requests/minute; fetch the curated list a
  /// few symbols at a time (each symbol fires 2 calls — quote + profile)
  /// rather than firing all of them in one burst.
  static const int _chunkSize = 5;

  @override
  Future<Either<Failure, List<Stock>>> getStocks(List<String> symbols) {
    return _guard(() async {
      final stocks = <Stock>[];
      for (final chunk in _chunks(symbols, _chunkSize)) {
        stocks
            .addAll(await Future.wait(chunk.map(_fetchOne), eagerError: true));
      }
      return stocks;
    });
  }

  @override
  Future<Either<Failure, Stock>> getStockDetails(String symbol) {
    return _guard(() => _fetchOne(symbol));
  }

  @override
  Future<Either<Failure, List<StockSearchResult>>> searchStocks(String query) {
    return _guard(() => _withMockFallback<List<StockSearchResult>>(
          () => remoteDataSource.searchSymbols(query),
          () => mockDataSource.search(query),
        ));
  }

  // --- composition helpers ---

  Future<Stock> _fetchOne(String symbol) {
    return _withMockFallback(
      () async {
        final quoteFuture = remoteDataSource.getQuote(symbol);
        final profileFuture = _profile(symbol);
        // `Future.wait` attaches error handlers to both, so a failure in one
        // never leaves the other dangling; it rethrows once both settled.
        await Future.wait([quoteFuture, profileFuture]);
        return _merge(symbol, await quoteFuture, await profileFuture);
      },
      () => mockDataSource.getStock(symbol),
    );
  }

  /// Profile via the session cache; only hits the network on a miss.
  Future<CompanyProfileModel> _profile(String symbol) async {
    final cached = localDataSource.getCachedProfile(symbol);
    if (cached != null) return cached;

    final fresh = await remoteDataSource.getProfile(symbol);
    localDataSource.cacheProfile(symbol, fresh);
    return fresh;
  }

  Stock _merge(String symbol, QuoteModel q, CompanyProfileModel p) => Stock(
        symbol: symbol,
        companyName: p.name,
        logoUrl: p.logo,
        ltp: q.current,
        change: q.change,
        changePercent: q.percentChange,
        open: q.open,
        high: q.high,
        low: q.low,
        previousClose: q.previousClose,
        exchange: p.exchange,
        industry: p.industry,
        marketCap: p.marketCapitalization,
        currency: p.currency,
      );

  Iterable<List<T>> _chunks<T>(List<T> list, int size) sync* {
    for (var i = 0; i < list.length; i += size) {
      yield list.sublist(i, i + size < list.length ? i + size : list.length);
    }
  }

  /// The single exception -> Failure seam. Mirrors `PostRepositoryImpl`; shared
  /// here because three repository methods need the same mapping.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.transformTimeout:
        case DioExceptionType.connectionError:
          return const Left(NetworkFailure());
        case DioExceptionType.badResponse:
          return Left(
            ServerFailure(
              'Request failed with status ${e.response?.statusCode}',
            ),
          );
        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          return Left(ServerFailure(e.message ?? 'Unexpected network error'));
      }
    } on FormatException {
      return const Left(ServerFailure('Received an unreadable response'));
    }
  }

  /// Debug-only static-data seam (spec: "Real-Time Data & Static Fallback").
  /// A failed [run] (rate limit, network error, unparseable response) falls
  /// back to [fallback]'s static data instead of surfacing as an error — but
  /// only in debug builds; a release build must never show a fabricated price
  /// as if it were real, so it always rethrows there. Only catches the same
  /// exception types [_guard] maps to a [Failure]; anything else (a real bug)
  /// always rethrows.
  Future<T> _withMockFallback<T>(
    Future<T> Function() run,
    T? Function() fallback,
  ) async {
    try {
      return await run();
    } catch (e, st) {
      final isKnownFailure =
          e is ServerException || e is DioException || e is FormatException;
      if (!isKnownFailure || !kDebugMode) {
        Error.throwWithStackTrace(e, st);
      }
      final mock = fallback();
      if (mock == null) Error.throwWithStackTrace(e, st);
      return mock;
    }
  }
}
