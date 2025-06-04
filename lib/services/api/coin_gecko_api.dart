import 'package:fokuskripto/services/api/api_exception.dart';
import 'package:fokuskripto/services/api/endpoints.dart';
import 'package:fokuskripto/services/base_network.dart';
import 'package:fokuskripto/services/cache/cache_manager.dart ';
import 'package:fokuskripto/model/coinGecko.dart';
import 'package:fokuskripto/model/coinGecko_detail.dart';

class CoinGeckoApi {
  static const String _apiKey = 'CG-fG8KAiNzkZtwkafsmTVTjnXT';
  static const Map<String, String> _headers = {
    'x-cg-demo-api-key': _apiKey,
  };
  final BaseNetworkService _network;
  final CacheManager _cache;

  CoinGeckoApi({
    BaseNetworkService? network,
    CacheManager? cache,
  })  : _network = network ?? BaseNetworkService(),
        _cache = cache ?? CacheManager(boxName: 'api_gecko_cache');

  Future<List<CoinGeckoMarketModel>> getMarkets({
    String vsCurrency = 'idr',
    String? ids,
    int perPage = 10,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cache.generateKey(
      prefix: 'markets',
      vsCurrency: vsCurrency,
      ids: ids,
      perPage: perPage,
      page: page,
    );

    // Cek cache dulu jika tidak force refresh
    if (!forceRefresh) {
      try {
        final cached = await _cache.get<List<dynamic>>(cacheKey);
        if (cached != null) {
          print('[DEBUG] getMarkets: Data diambil dari CACHE untuk $cacheKey');
          return _parseMarketData(cached); // Mengembalikan data dari cache
        }
      } catch (e) {
        print('Cache error: ${e}');
      }
    }
    // fetch API
    try {
      final endpoint = CoinGeckoEndpoints.markets(
        vsCurrency: vsCurrency,
        ids: ids,
        perPage: perPage,
        page: page,
      );

      final response = await _network
          .get('${CoinGeckoEndpoints.baseUrl}$endpoint', headers: _headers);

      if (response is List) {
        // Simpan ke cache untuk penggunaan berikutnya
        await _cache.set(cacheKey, response);
        print(
            '[DEBUG] getMarkets: Data diambil dari API dan disimpan ke CACHE untuk $cacheKey');
        return _parseMarketData(response);
      }

      throw ApiException('Invalid response format for markets');
    } catch (e) {
      throw ApiException(
        'Failed to fetch markets: ${e.toString()}',
        data: {'vsCurrency': vsCurrency, 'ids': ids},
      );
    }
  }

  List<CoinGeckoMarketModel> _parseMarketData(List<dynamic> data) {
    try {
      return data
          .map((json) =>
              CoinGeckoMarketModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Failed to parse market data: ${e.toString()}');
    }
  }

  Future<CoinGeckoDetailModel?> getCoinDetail(
    String coinId, {
    String vsCurrency = 'idr',
    bool forceRefresh = true,
  }) async {
    final cacheKey = _cache.generateKey(
      prefix: 'detailcache',
      coinId: coinId,
      vsCurrency: vsCurrency,
    );
    print(
        '[DEBUG] getCoinDetail cacheKey: $cacheKey, forceRefresh: $forceRefresh');

    if (!forceRefresh) {
      try {
        final cached = await _cache.get<Map<String, dynamic>>(cacheKey);
        if (cached != null) {
          print(
              '[DEBUG] getCoinDetail: Data diambil dari CACHE untuk $cacheKey');
          return CoinGeckoDetailModel.fromJson(cached);
        }
        print(
            '[DEBUG] getCoinDetail: Cache MISS, akan fetch dari API untuk $cacheKey');
      } catch (e) {
        print('Cache error: ${e}');
      }
    }

    try {
      final endpoint = CoinGeckoEndpoints.coinDetail(coinId);
      final response = await _network
          .get('${CoinGeckoEndpoints.baseUrl}$endpoint', headers: _headers);

      if (response is Map<String, dynamic>) {
        await _cache.set(cacheKey, response);
        print(
            '[DEBUG] getCoinDetail: Data diambil dari API dan disimpan ke CACHE untuk $cacheKey');
        return CoinGeckoDetailModel.fromJson(response);
      }

      throw ApiException('Invalid response format for coin detail');
    } catch (e) {
      throw ApiException(
        'Failed to fetch coin detail: ${e.toString()}',
        data: {'coinId': coinId},
      );
    }
  }

  Future<List<List<double>>> getMarketChart({
    required String coinId,
    String vsCurrency = 'idr',
    int days = 1,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cache.generateKey(
      prefix: 'chart',
      coinId: coinId,
      vsCurrency: vsCurrency,
      days: days,
    );
    print(
        '[DEBUG] getCoinDetail cacheKey: $cacheKey, forceRefresh: $forceRefresh');

    if (!forceRefresh) {
      try {
        final cached = await _cache.get<List<dynamic>>(cacheKey);
        if (cached != null) {
          print(
              '[DEBUG] getMarketChart: Data diambil dari CACHE untuk $cacheKey');
          return _parseChartData(cached);
        }
        print(
            '[DEBUG] getMarketChart: Cache MISS, akan fetch dari API untuk $cacheKey');
      } catch (e) {
        print('Cache error: ${e}');
      }
    }

    try {
      final endpoint = CoinGeckoEndpoints.marketChart(
        coinId: coinId,
        vsCurrency: vsCurrency,
        days: days,
      );

      final response = await _network
          .get('${CoinGeckoEndpoints.baseUrl}$endpoint', headers: _headers);

      if (response is Map<String, dynamic> && response['prices'] is List) {
        final List<dynamic> prices = response['prices'];
        print(
            '[DEBUG] getMarketChart: Data diambil dari API dan disimpan ke CACHE untuk $cacheKey');
        await _cache.set(cacheKey, prices);
        return _parseChartData(prices);
      }

      throw ApiException('Invalid response format for market chart');
    } catch (e) {
      throw ApiException(
        'Failed to fetch market chart: ${e.toString()}',
        data: {'coinId': coinId, 'days': days},
      );
    }
  }

  List<List<double>> _parseChartData(List<dynamic> data) {
    try {
      return data
          .map((item) => (item as List<dynamic>)
              .map((value) => (value as num).toDouble())
              .toList())
          .toList();
    } catch (e) {
      throw ApiException('Failed to parse chart data: ${e.toString()}');
    }
  }
}
