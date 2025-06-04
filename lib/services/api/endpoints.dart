class CoinGeckoEndpoints {
  static const String baseUrl = 'https://api.coingecko.com/api/v3';

  static String markets({
    required String vsCurrency,
    String? ids,
    int perPage = 50,
    int page = 1,
  }) {
    if (ids?.isNotEmpty ?? false) {
      return '/coins/markets?vs_currency=$vsCurrency&ids=$ids'
          '&order=market_cap_desc&sparkline=false&price_change_percentage=24h';
    }
    return '/coins/markets?vs_currency=$vsCurrency'
        '&order=market_cap_desc&per_page=$perPage&page=$page'
        '&sparkline=false&price_change_percentage=24h';
  }

  static String coinDetail(String coinId) {
    return '/coins/$coinId?localization=false&tickers=false'
        '&community_data=false&developer_data=false&sparkline=false';
  }

  static String marketChart({
    required String coinId,
    required String vsCurrency,
    required int days,
  }) {
    return '/coins/$coinId/market_chart?vs_currency=$vsCurrency&days=$days';
  }
}
