import 'package:hive_flutter/hive_flutter.dart';
// import 'dart:convert'; // Tidak perlu jika BaseNetworkService sudah decode dan kita simpan List<Map>

// Sesuaikan path import model Anda
import '../model/coinGecko.dart'; // Jika nama filenya coin_gecko_market_model.dart
// atau import '../model/coinGecko.dart'; // Jika nama filenya coinGecko.dart

import 'base_network.dart'; // Pastikan path ini benar

class ApiServiceGecko {
  final BaseNetworkService _networkService = BaseNetworkService();
  static const String _apiBaseUrl = 'https://api.coingecko.com/api/v3';

  // Nama Box Hive untuk cache
  static const String _cacheBoxName =
      'api_gecko_cache_ttl_simple'; // Nama box baru
  // Durasi cache valid (misalnya, 2 menit)
  static const int _cacheDurationMinutesTTL = 1;

  // Fungsi helper untuk membuka Hive box
  Future<Box> _getCacheBox() async {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      return await Hive.openBox(_cacheBoxName);
    }
    return Hive.box(_cacheBoxName);
  }

  // Fungsi helper untuk membuat kunci cache yang dinamis
  String _generateCacheKey(
    String prefix, {
    String vsCurrency = 'idr',
    String? ids,
    int perPage = 100,
    int page = 1,
  }) {
    // Menggunakan semua parameter relevan untuk membuat kunci unik
    return "${prefix}_${vsCurrency}_ids-${ids ?? "all"}_p-${page}_pp-$perPage";
  }

  Future<List<CoinGeckoMarketModel>> fetchCoinMarkets({
    String vsCurrency = 'idr',
    String? ids,
    int perPage = 100,
    int page = 1,
    bool forceRefreshUiTrigger = false, // Untuk memaksa pengambilan dari API
  }) async {
    final cacheBox = await _getCacheBox();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Buat kunci unik untuk data dan timestamp berdasarkan parameter request
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

    // 1. Cek Cache jika tidak ada forceRefreshUiTrigger
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
              // Parse List<Map<String, dynamic>> dari Hive ke List<CoinGeckoMarketModel>
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
              // Jika ada error parsing cache, hapus cache yang korup agar bisa fetch baru
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
        print(
          "CACHE TTL EMPTY: Timestamp (atau data) tidak ditemukan untuk $dataKey.",
        );
      }
    } else {
      print("CACHE TTL: Force Refresh dari UI untuk $dataKey.");
    }

    // 2. Jika cache tidak valid, tidak ada, atau forceRefresh, ambil dari API
    print(
      "CACHE TTL MISS/STALE/FORCED: Mengambil data baru dari CoinGecko API untuk $dataKey.",
    );
    String endpoint =
        '/coins/markets?vs_currency=$vsCurrency&order=market_cap_desc&per_page=$perPage&page=$page&sparkline=false&price_change_percentage=24h';
    if (ids != null && ids.isNotEmpty) {
      // Untuk request by ID, parameter perPage dan page biasanya tidak lagi relevan di CoinGecko
      // atau bisa diabaikan oleh servernya, tapi kita tetap sertakan untuk kunci cache yang berbeda.
      endpoint =
          '/coins/markets?vs_currency=$vsCurrency&ids=$ids&order=market_cap_desc&sparkline=false&price_change_percentage=24h';
    }

    try {
      // _networkService.get() sudah melakukan jsonDecode dan mengembalikan List<dynamic> atau Map<String, dynamic>
      final dynamic responseData = await _networkService.get(
        '$_apiBaseUrl$endpoint',
      );

      if (responseData is List) {
        // responseData adalah List<Map<String, dynamic>>
        // Simpan List<Map<String, dynamic>> ini langsung ke Hive.
        await cacheBox.put(dataKey, responseData);
        await cacheBox.put(timestampKey, now); // Update timestamp

        print("API FETCH TTL SUCCESS: Data disimpan ke Hive untuk $dataKey.");
        // Parse ke List<CoinGeckoMarketModel> sebelum mengembalikan
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
      rethrow; // Lempar ulang error asli dari BaseNetworkService atau dari sini
    } catch (e) {
      print("ApiServiceGecko: Error umum saat fetch API untuk $dataKey: $e");
      throw NetworkException(
        'Gagal memproses data dari CoinGecko: ${e.toString()}',
      );
    }
  }

  // Anda bisa menambahkan metode lain di sini jika perlu, misalnya untuk membersihkan cache tertentu
  // Future<void> clearCacheForCoinMarkets({String vsCurrency = 'idr', String? ids, int perPage = 100, int page = 1}) async {
  //   final cacheBox = await _getCacheBox();
  //   String dataKey = _generateCacheKey("data", vsCurrency: vsCurrency, ids: ids, page: page, perPage: perPage);
  //   String timestampKey = _generateCacheKey("ts", vsCurrency: vsCurrency, ids: ids, page: page, perPage: perPage);
  //   await cacheBox.delete(dataKey);
  //   await cacheBox.delete(timestampKey);
  //   print("CACHE CLEARED for $dataKey");
  // }
}
