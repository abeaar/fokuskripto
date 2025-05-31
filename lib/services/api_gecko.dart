import '../model/coinGecko.dart';
import 'base_network.dart';

class ApiServiceGecko {
  final BaseNetworkService _networkService = BaseNetworkService();

  static const String _apiBaseUrl = 'https://api.coingecko.com/api/v3';
  Future<List<CoinGeckoMarketModel>> fetchCoinMarkets({
    String vsCurrency = 'idr', // Default ke IDR
    String? ids,
    int perPage = 100,
    int page = 1,
  }) async {
    String endpoint =
        '/coins/markets?vs_currency=$vsCurrency&order=market_cap_desc&per_page=$perPage&page=$page&sparkline=false';
    if (ids != null && ids.isNotEmpty) {
      endpoint += '&ids=$ids';
    }
    try {
      final responseData = await _networkService.get('$_apiBaseUrl$endpoint');

      if (responseData is List) {
        return responseData
            .map(
              (json) =>
                  CoinGeckoMarketModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw NetworkException(
          'Format data tidak valid diterima dari CoinGecko API.',
        );
      }
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Gagal memproses data dari CoinGecko: ${e.toString()}',
      );
    }
  }

  // Future<CoinGeckoDetailModel> fetchCoinDetail(String coinId) async { ... }
}
