import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/company_profile_model.dart';
import '../models/quote_model.dart';
import '../models/stock_search_result_model.dart';

/// Talks to the Finnhub API, and only to the network. No business rules, no
/// merging — it returns models or throws [ServerException].
///
/// Dio throws a [DioException] for non-2xx / timeout / connection errors; that
/// is intentionally left to propagate. `StockRepositoryImpl` is the single seam
/// that catches and translates every exception type into a [Failure].
abstract class StockRemoteDataSource {
  Future<QuoteModel> getQuote(String symbol);
  Future<CompanyProfileModel> getProfile(String symbol);
  Future<List<StockSearchResultModel>> searchSymbols(String query);
}

class StockRemoteDataSourceImpl implements StockRemoteDataSource {
  final Dio dio;

  StockRemoteDataSourceImpl({required this.dio});

  @override
  Future<QuoteModel> getQuote(String symbol) async {
    final response =
        await dio.get('/quote', queryParameters: {'symbol': symbol});
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ServerException('Unexpected response format from server');
    }
    return QuoteModel.fromJson(data);
  }

  @override
  Future<CompanyProfileModel> getProfile(String symbol) async {
    final response =
        await dio.get('/stock/profile2', queryParameters: {'symbol': symbol});
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ServerException('Unexpected response format from server');
    }
    return CompanyProfileModel.fromJson(data);
  }

  @override
  Future<List<StockSearchResultModel>> searchSymbols(String query) async {
    final response = await dio.get('/search', queryParameters: {'q': query});
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ServerException('Unexpected response format from server');
    }

    final results = data['result'];
    if (results is! List) return const [];

    return results
        .map((item) =>
            StockSearchResultModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
