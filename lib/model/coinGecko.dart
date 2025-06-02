import 'package:hive/hive.dart';

part 'coinGecko.g.dart'; 

@HiveType(typeId: 0) // typeId harus unik untuk setiap HiveObject di proyek Anda
class CoinGeckoMarketModel extends HiveObject { // Tambahkan 'extends HiveObject' (opsional tapi berguna)
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String symbol;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String image;

  @HiveField(4)
  final double currentPrice;

  @HiveField(5)
  final double? marketCap;

  @HiveField(6)
  final int? marketCapRank;

  @HiveField(7)
  final double? totalVolume;

  @HiveField(8)
  final double? high24h;

  @HiveField(9)
  final double? low24h;

  @HiveField(10)
  final double? priceChange24h;

  @HiveField(11)
  final double? priceChangePercentage24h;

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

  @override
  String toString() {
    return 'CoinGeckoMarketModel(id: $id, name: $name, currentPrice: $currentPrice)';
  }
}