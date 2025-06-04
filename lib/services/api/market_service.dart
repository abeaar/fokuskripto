import 'package:hive_flutter/hive_flutter.dart';
import '../../model/coinGecko.dart';
import '../base_network.dart';
import '../../model/coinGecko_detail.dart';

class MarketService {
  final BaseNetworkService _networkService = BaseNetworkService();
  static const String _apiBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String _cacheBoxName = 'market_data_cache';
  static const int _cacheDurationMinutesTTL = 2;

  // Singleton pattern
  static final MarketService _instance = MarketService._internal();
  factory MarketService() => _instance;
  MarketService._internal();

  Future<Box> _getCacheBox() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      return await Hive.openBox(_cacheBoxName);
    }
    return Hive.box(_cacheBoxName);
  }

  String _generateCacheKey(
    String prefix, {
    String vsCurrency = 'idr',
    String? ids,
    String? coinId,
    int perPage = 100,
    int page = 1,
    int? days,
  }) {
    if (prefix.startsWith("detail_")) {
      return "${prefix}_${coinId}_$vsCurrency";
    } else if (prefix.startsWith("chart_")) {
      return "${prefix}_${coinId}_${vsCurrency}_${days ?? '1'}d";
    }
    return "${prefix}_${vsCurrency}_ids-${ids ?? "all"}_p-${page}_pp-$perPage";
  }

  Future<List<CoinGeckoMarketModel>> fetchCoinMarkets({
    String vsCurrency = 'idr',
    String? ids,
    int perPage = 100,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final cacheBox = await _getCacheBox();
    final now = DateTime.now().millisecondsSinceEpoch;
    String dataKey = _generateCacheKey(
      "data",
      vsCurrency: vsCurrency,
      ids: ids,
      page: page,
      perPage: perPage,
    );
    String timestampKey = _generateCacheKey(
      "ts",
      vsCurrency: vsCurrency,
      ids: ids,
      page: page,
      perPage: perPage,
    );

    if (!forceRefresh) {
      final int? cachedTimestamp = cacheBox.get(timestampKey) as int?;
      if (cachedTimestamp != null) {
        final cacheAgeMinutes = (now - cachedTimestamp) / (1000 * 60);
        if (cacheAgeMinutes < _cacheDurationMinutesTTL) {
          final List<dynamic>? cachedRawList =
              cacheBox.get(dataKey) as List<dynamic>?;
          if (cachedRawList != null) {
            print("Cache hit: Using cached data for $dataKey");
            try {
              return cachedRawList
                  .map((json) => CoinGeckoMarketModel.fromJson(
                      Map<String, dynamic>.from(json)))
                  .toList();
            } catch (e) {
              print("Error parsing cached data: $e. Will fetch from API.");
              await cacheBox.delete(dataKey);
              await cacheBox.delete(timestampKey);
            }
          }
        }
      }
    }

    print("Cache miss/stale: Fetching fresh data from API for $dataKey");
    String endpoint =
        '/coins/markets?vs_currency=$vsCurrency&order=market_cap_desc&per_page=$perPage&page=$page&sparkline=false&price_change_percentage=24h';
    if (ids != null && ids.isNotEmpty) {
      endpoint =
          '/coins/markets?vs_currency=$vsCurrency&ids=$ids&order=market_cap_desc&sparkline=false&price_change_percentage=24h';
    }

    try {
      final dynamic responseData =
          await _networkService.get('$_apiBaseUrl$endpoint');
      if (responseData is List) {
        await cacheBox.put(dataKey, responseData);
        await cacheBox.put(timestampKey, now);
        print("API fetch success: Data cached for $dataKey");
        return responseData
            .map((json) =>
                CoinGeckoMarketModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw NetworkException('Invalid API response format (not a List)');
      }
    } catch (e) {
      print("Error fetching market data: $e");
      rethrow;
    }
  }
}
