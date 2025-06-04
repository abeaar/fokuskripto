import 'package:hive_flutter/hive_flutter.dart';
import '../model/coinGecko.dart';
import 'base_network.dart';
import '../model/coinGecko_detail.dart';

class ApiServiceGecko {
  final BaseNetworkService _networkService = BaseNetworkService();
  static const String _apiBaseUrl = 'https://api.coingecko.com/api/v3';
  static const String _cacheBoxName = 'api_gecko_cache_ttl_simple';
  static const int _cacheDurationMinutesTTL = 2;

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
    int? days, // Pastikan ini ada
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
          // Cache masih fresh, ambil data dari Hive
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
                "CACHE TTL: Error parsing cached data: $e. Akan fetch dari API.",
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
        // Ini seharusnya tidak terjadi untuk endpoint /coins/markets yang mengembalikan list
        throw NetworkException(
          'Format data API tidak valid (bukan List) untuk $dataKey.',
        );
      }
    } on NetworkException catch (e) {
      print(
        "ApiServiceGecko: NetworkException saat fetch API untuk $dataKey: $e",
      );
      rethrow;
    }
  }

  Future<CoinGeckoDetailModel?> fetchCoinDetail(
    String coinId, {
    String vsCurrency = 'idr', // Untuk market_data di dalam detail
    bool forceRefreshUiTrigger = false,
  }) async {
    final cacheBox = await _getCacheBox();
    final now = DateTime.now().millisecondsSinceEpoch;

    String dataKey = _generateCacheKey(
      "detail_data",
      coinId: coinId,
      vsCurrency: vsCurrency,
    );
    String timestampKey = _generateCacheKey(
      "detail_ts",
      coinId: coinId,
      vsCurrency: vsCurrency,
    );

    if (!forceRefreshUiTrigger) {
      final int? cachedTimestamp = cacheBox.get(timestampKey) as int?;
      if (cachedTimestamp != null) {
        final cacheAgeMinutes = (now - cachedTimestamp) / (1000 * 60);

        if (cacheAgeMinutes < _cacheDurationMinutesTTL) {
          // Atau detailCacheDurationMinutes
          final Map<String, dynamic>? cachedRawData =
              cacheBox.get(dataKey) as Map<String, dynamic>?;
          if (cachedRawData != null) {
            print(
              "CACHE TTL HIT (Coin Detail): Menggunakan data dari Hive untuk $dataKey.",
            );
            try {
              return CoinGeckoDetailModel.fromJson(cachedRawData);
            } catch (e) {
              print(
                "CACHE DETAIL: Error parsing cached data untuk $coinId: $e. Akan fetch dari API.",
              );
              await cacheBox.delete(dataKey);
              await cacheBox.delete(timestampKey);
            }
          }
        } else {
          print(
            "CACHE STALE (Coin Detail): Data di Hive kadaluwarsa untuk $dataKey.",
          );
        }
      } else {
        print(
          "CACHE EMPTY (Coin Detail): Timestamp (atau data) tidak ditemukan untuk $dataKey.",
        );
      }
    } else {
      print("CACHE TTL: Force Refresh dari UI untuk detail $dataKey.");
    }

    print(
      "API FETCH (Coin Detail): Mengambil data baru dari CoinGecko API untuk $dataKey.",
    );
    String endpoint =
        '/coins/$coinId?localization=false&tickers=false&community_data=false&developer_data=false&sparkline=false';

    try {
      final dynamic responseData = await _networkService.get(
        '$_apiBaseUrl$endpoint',
      );
      if (responseData is Map<String, dynamic>) {
        await cacheBox.put(dataKey, responseData);
        await cacheBox.put(timestampKey, now);
        print(
          "API FETCH SUCCESS (Coin Detail): Data disimpan ke Hive untuk $dataKey.",
        );
        return CoinGeckoDetailModel.fromJson(responseData);
      } else {
        throw NetworkException(
          'Format data API tidak valid (bukan Map) untuk detail $coinId.',
        );
      }
    } on NetworkException catch (e) {
      print(
        "ApiServiceGecko: NetworkException saat fetch detail untuk $coinId: $e",
      );
      rethrow;
    } catch (e) {
      print("ApiServiceGecko: Error umum saat fetch detail untuk $coinId: $e");
      throw NetworkException(
        'Gagal memproses data detail dari CoinGecko untuk $coinId: ${e.toString()}',
      );
    }
  }

  Future<List<List<double>>> fetchCoinMarketChart({
    required String coinId,
    String vsCurrency = 'idr',
    int days = 1, // Default 1 hari (24 jam)
    bool forceRefresh = false, // Parameter forceRefresh untuk chart
  }) async {
    final cacheBox = await _getCacheBox();
    final now = DateTime.now().millisecondsSinceEpoch;

    String dataKey = _generateCacheKey(
      "chart_data",
      coinId: coinId,
      vsCurrency: vsCurrency,
      days: days,
    );
    String timestampKey = _generateCacheKey(
      "chart_ts",
      coinId: coinId,
      vsCurrency: vsCurrency,
      days: days,
    );

    if (!forceRefresh) {
      final int? cachedTimestamp = cacheBox.get(timestampKey) as int?;
      if (cachedTimestamp != null) {
        final cacheAgeMinutes = (now - cachedTimestamp) / (1000 * 60);

        if (cacheAgeMinutes < _cacheDurationMinutesTTL) {
          final List<dynamic>? cachedRawData =
              cacheBox.get(dataKey) as List<dynamic>?;
          if (cachedRawData != null) {
            print(
              "CACHE TTL HIT (Coin Chart): Menggunakan data dari Hive untuk $dataKey.",
            );
            try {
              // INI BARIS YANG PERLU DIUBAH UNTUK MENGATASI ERROR TIPE
              return cachedRawData.map<List<double>>((item) {
                return (item as List<dynamic>).map<double>((value) {
                  return (value as num).toDouble();
                }).toList();
              }).toList();
            } catch (e) {
              print(
                "CACHE CHART: Error parsing cached data untuk chart $coinId: $e. Akan fetch dari API.",
              );
              await cacheBox.delete(dataKey);
              await cacheBox.delete(timestampKey);
            }
          }
        } else {
          print(
            "CACHE STALE (Coin Chart): Data di Hive kadaluwarsa untuk $dataKey.",
          );
        }
      } else {
        print(
          "CACHE EMPTY (Coin Chart): Timestamp (atau data) tidak ditemukan untuk $dataKey.",
        );
      }
    } else {
      print(
        "API FETCH (Coin Chart): Force Refresh dari UI untuk chart $dataKey.",
      );
    }

    print(
      "API FETCH (Coin Chart): Mengambil data baru dari CoinGecko API untuk chart $dataKey.",
    );
    String endpoint =
        '/coins/$coinId/market_chart?vs_currency=$vsCurrency&days=$days';

    try {
      final dynamic responseData = await _networkService.get(
        '$_apiBaseUrl$endpoint',
      );

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('prices')) {
        List<dynamic> prices = responseData['prices'];

        await cacheBox.put(dataKey, prices); // Simpan data mentah ke cache
        await cacheBox.put(timestampKey, now);
        print(
          "API FETCH SUCCESS (Coin Chart): Data disimpan ke Hive untuk $dataKey.",
        );

        // Pastikan data yang dikembalikan juga sudah dalam format double yang benar
        // Meskipun API mungkin sudah mengirim double, ini adalah praktik yang baik
        return prices.map<List<double>>((item) {
          return (item as List<dynamic>).map<double>((value) {
            return (value as num).toDouble();
          }).toList();
        }).toList();
      } else {
        throw NetworkException(
          'Format data API tidak valid (tidak ada "prices") untuk chart $coinId.',
        );
      }
    } on NetworkException catch (e) {
      print(
        "ApiServiceGecko: NetworkException saat fetch chart untuk $coinId: $e",
      );
      rethrow;
    } catch (e) {
      print("ApiServiceGecko: Error umum saat fetch chart untuk $coinId: $e");
      throw NetworkException(
        'Gagal memproses data chart dari CoinGecko untuk $coinId: ${e.toString()}',
      );
    }
  }
}
