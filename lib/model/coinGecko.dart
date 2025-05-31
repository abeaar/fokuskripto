// lib/models/coin_gecko_market_model.dart

class CoinGeckoMarketModel {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double currentPrice;
  final double? marketCap;
  final int? marketCapRank;
  final double? totalVolume;
  final double? high24h;
  final double? low24h;
  final double? priceChange24h;
  final double? priceChangePercentage24h;
  // Tambahkan field lain jika perlu dari respons CoinGecko

  CoinGeckoMarketModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.currentPrice,
    this.marketCap,
    this.marketCapRank,
    this.totalVolume,
    this.high24h,
    this.low24h,
    this.priceChange24h,
    this.priceChangePercentage24h,
  });

  factory CoinGeckoMarketModel.fromJson(Map<String, dynamic> json) {
    return CoinGeckoMarketModel(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      marketCapRank: json['market_cap_rank'] as int?,
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      high24h: (json['high_24h'] as num?)?.toDouble(),
      low24h: (json['low_24h'] as num?)?.toDouble(),
      priceChange24h: (json['price_change_24h'] as num?)?.toDouble(),
      priceChangePercentage24h: (json['price_change_percentage_24h'] as num?)?.toDouble(),
    );
  }

  // Mungkin berguna untuk debugging
  @override
  String toString() {
    return 'CoinGeckoMarketModel(id: $id, name: $name, currentPrice: $currentPrice)';
  }
}