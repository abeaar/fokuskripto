import 'package:fokuskripto/services/api/api_exception.dart';
import 'package:fokuskripto/services/api/endpoints.dart';
import 'package:fokuskripto/services/base_network.dart';
import 'package:fokuskripto/services/cache/cache_manager.dart ';
import 'package:fokuskripto/model/coinGecko.dart';
import 'package:fokuskripto/model/coinGecko_detail.dart';

class CoinGeckoApi {
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

      final response =
          await _network.get('${CoinGeckoEndpoints.baseUrl}$endpoint');

      if (response is List) {
        // Simpan ke cache untuk penggunaan berikutnya
        await _cache.set(cacheKey, response);
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
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cache.generateKey(
      prefix: 'detail',
      coinId: coinId,
      vsCurrency: vsCurrency,
    );

    if (!forceRefresh) {
      try {
        final cached = await _cache.get<Map<String, dynamic>>(cacheKey);
        if (cached != null) {
          return CoinGeckoDetailModel.fromJson(cached);
        }
      } catch (e) {
        print('Cache error: ${e}');
      }
    }

    try {
      final endpoint = CoinGeckoEndpoints.coinDetail(coinId);
      final response =
          await _network.get('${CoinGeckoEndpoints.baseUrl}$endpoint');

      if (response is Map<String, dynamic>) {
        await _cache.set(cacheKey, response);
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

    if (!forceRefresh) {
      try {
        final cached = await _cache.get<List<dynamic>>(cacheKey);
        if (cached != null) {
          return _parseChartData(cached);
        }
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

      final response =
          await _network.get('${CoinGeckoEndpoints.baseUrl}$endpoint');

      if (response is Map<String, dynamic> && response['prices'] is List) {
        final List<dynamic> prices = response['prices'];
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
