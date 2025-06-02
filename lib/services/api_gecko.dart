// lib/services/api_service_gecko.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../model/coinGecko.dart'; // Sesuaikan path
import 'base_network.dart';

class ApiServiceGecko {
  final BaseNetworkService _networkService = BaseNetworkService();
  static const String _apiBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String _cacheBoxName = 'api_gecko_cache_ttl_v1';
  static const int _cacheDurationMinutesTTL = 1;
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
    int perPage = 100,
    int page = 1,
  }) {
    return "${prefix}_${vsCurrency}_ids-${ids ?? "all"}_p-${page}_pp-$perPage";
  }

  Future<List<CoinGeckoMarketModel>> fetchCoinMarkets({
    String vsCurrency = 'idr',
    String? ids,
    int perPage = 100,
    int page = 1,
    bool forceRefreshUiTrigger = false,
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

    if (!forceRefreshUiTrigger) {
      final int? cachedTimestamp = cacheBox.get(timestampKey) as int?;
      if (cachedTimestamp != null) {
        final cacheAgeMinutes = (now - cachedTimestamp) / (1000 * 60);
        if (cacheAgeMinutes < _cacheDurationMinutesTTL) {
          final List<dynamic>? cachedRawList =
              cacheBox.get(dataKey) as List<dynamic>?;
          if (cachedRawList != null) {
            print(
              "CACHE TTL HIT: Menggunakan data dari Hive untuk $dataKey. Usia: ${cacheAgeMinutes.toStringAsFixed(1)} menit.",
            );
            try {
              return cachedRawList
                  .map(
                    (json) => CoinGeckoMarketModel.fromJson(
                      Map<String, dynamic>.from(json),
                    ),
                  )
                  .toList();
            } catch (e) {
              print(
                "CACHE TTL: Error parsing cached data: $e. Fallback ke API.",
              );
              await cacheBox.delete(dataKey);
              await cacheBox.delete(timestampKey);
            }
          }
        } else {
          print(
            "CACHE TTL STALE: Data di Hive kadaluwarsa untuk $dataKey. Usia: ${cacheAgeMinutes.toStringAsFixed(1)} menit.",
          );
        }
      } else {
        print("CACHE TTL EMPTY: Timestamp tidak ditemukan untuk $dataKey.");
      }
    } else {
      print("CACHE TTL: Force Refresh dari UI untuk $dataKey.");
    }
    print(
      "CACHE TTL MISS/STALE/FORCED: Mengambil data baru dari CoinGecko API untuk $dataKey.",
    );
    String endpoint =
        '/coins/markets?vs_currency=$vsCurrency&order=market_cap_desc&per_page=$perPage&page=$page&sparkline=false&price_change_percentage=24h';
    if (ids != null && ids.isNotEmpty) {
      endpoint =
          '/coins/markets?vs_currency=$vsCurrency&ids=$ids&order=market_cap_desc&sparkline=false&price_change_percentage=24h';
    }
    try {
      final dynamic responseData = await _networkService.get(
        '$_apiBaseUrl$endpoint',
      );

      if (responseData is List) {
        await cacheBox.put(dataKey, responseData);
        await cacheBox.put(timestampKey, now); // Update timestamp
        print("API FETCH TTL SUCCESS: Data disimpan ke Hive untuk $dataKey.");
        return responseData
            .map(
              (json) =>
                  CoinGeckoMarketModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw NetworkException(
          'Format data API tidak valid (bukan List) untuk $dataKey.',
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
}
