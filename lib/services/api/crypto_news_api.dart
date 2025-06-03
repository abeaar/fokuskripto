import 'package:fokuskripto/model/crypto_news.dart';
import 'package:fokuskripto/services/base_network.dart';
import 'package:fokuskripto/services/api/api_exception.dart';
import 'package:fokuskripto/services/cache/cache_manager.dart';

class CryptoNewsApi {
  static const String _baseUrl = 'https://min-api.cryptocompare.com/data/v2';
  final BaseNetworkService _network;
  final CacheManager _cache;

  CryptoNewsApi({
    BaseNetworkService? network,
    CacheManager? cache,
  })  : _network = network ?? BaseNetworkService(),
        _cache = cache ?? CacheManager(boxName: 'crypto_news_cache');

  Future<List<CryptoNews>> getLatestNews({
    String lang = 'EN',
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cache.generateKey(
      prefix: 'news',
      perPage: limit,
    );

    if (!forceRefresh) {
      try {
        final cached = await _cache.get<List<dynamic>>(cacheKey);
        if (cached != null) {
          return _parseNewsData(cached);
        }
      } on CacheException catch (e) {
        print('Cache error: ${e.message}');
      }
    }

    try {
      final response = await _network.get(
        '$_baseUrl/news/',
        queryParameters: {
          'lang': lang,
          'sortOrder': 'popular',
          'feeds': 'cryptocompare,cointelegraph,coindesk',
        },
      );

      if (response is Map<String, dynamic> &&
          response['Data'] != null &&
          response['Data'] is List) {
        final List<dynamic> newsData = response['Data'];
        await _cache.set(cacheKey, newsData);
        return _parseNewsData(newsData);
      }

      throw ApiException('Invalid response format for news');
    } catch (e) {
      throw ApiException(
        'Failed to fetch news: ${e.toString()}',
        data: {'lang': lang, 'limit': limit},
      );
    }
  }

  List<CryptoNews> _parseNewsData(List<dynamic> data) {
    try {
      return data
          .map((json) => CryptoNews.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Failed to parse news data: ${e.toString()}');
    }
  }
}
