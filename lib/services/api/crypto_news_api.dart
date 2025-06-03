import 'package:fokuskripto/model/crypto_news.dart';
import 'package:fokuskripto/services/base_network.dart';
import 'package:fokuskripto/services/cache/cache_manager.dart' as cache;
import 'package:fokuskripto/services/api/api_exception.dart';
import 'dart:convert';

class CryptoNewsApi {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  final BaseNetworkService _network;
  final cache.CacheManager _cache;

  CryptoNewsApi({
    BaseNetworkService? network,
  })  : _network = network ?? BaseNetworkService(),
        _cache = cache.CacheManager(boxName: 'crypto_news_cache');

  Future<List<CryptoNews>> getLatestNews({
    String lang = 'en',
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cache.generateKey(
      prefix: 'news',
      perPage: limit,
    );

    if (!forceRefresh) {
      try {
        final cached = await _cache.get<String>(cacheKey);
        if (cached != null) {
          final List<dynamic> cachedData = json.decode(cached);
          return _parseNewsData(cachedData);
        }
      } on cache.CacheException catch (e) {
        print('Cache error: ${e.message}');
      }
    }

    try {
      // Menggunakan endpoint status updates dari CoinGecko
      final response = await _network.get(
        '$_baseUrl/status_updates',
        queryParameters: {
          'per_page': limit.toString(),
          'category': 'general',
        },
      );

      print('Raw API Response: $response'); // Debug log

      if (response is Map<String, dynamic>) {
        if (!response.containsKey('status_updates')) {
          throw NetworkException(
            'Response tidak memiliki field "status_updates"',
            responseBody: response.toString(),
          );
        }

        final data = response['status_updates'];
        if (data is! List) {
          throw NetworkException(
            'Field "status_updates" bukan List',
            responseBody: 'Data type: ${data.runtimeType}, Value: $data',
          );
        }

        // Simpan data sebagai JSON string
        await _cache.set(cacheKey, json.encode(data));
        return _parseNewsData(data);
      }

      throw NetworkException(
        'Format response tidak valid',
        responseBody:
            'Response type: ${response.runtimeType}, Value: $response',
      );
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        'Gagal mengambil berita: ${e.toString()}',
        responseBody: e.toString(),
      );
    }
  }

  List<CryptoNews> _parseNewsData(List<dynamic> data) {
    try {
      print('Parsing news data: ${data.length} items'); // Debug log
      return data.map((item) {
        print('Processing item: $item'); // Debug log
        if (item is! Map<String, dynamic>) {
          throw NetworkException(
            'Item berita tidak valid',
            responseBody: 'Item type: ${item.runtimeType}, Value: $item',
          );
        }

        // Convert CoinGecko status update format to our news format
        final Map<String, dynamic> newsJson = {
          'id': item['id']?.toString() ?? '',
          'title': item['project']?['name']?.toString() ?? 'Crypto Update',
          'body': item['description'] ?? '',
          'url': item['project']?['link'] ?? '',
          'imageurl': item['project']?['image']?['large'] ?? '',
          'source': item['user'] ?? 'CoinGecko',
          'published_on': (DateTime.parse(item['created_at'] ??
                          DateTime.now().toIso8601String())
                      .millisecondsSinceEpoch /
                  1000)
              .round(),
          'categories': [item['category']?.toString() ?? 'general'],
          'tags': item['tags']?.cast<String>() ?? [],
        };

        return CryptoNews.fromJson(newsJson);
      }).toList();
    } catch (e) {
      print('Error parsing news data: $e'); // Debug log
      throw NetworkException(
        'Gagal parsing data berita: ${e.toString()}',
        responseBody: data.toString(),
      );
    }
  }
}
