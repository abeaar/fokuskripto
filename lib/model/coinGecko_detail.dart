// lib/models/coin_gecko_detail_model.dart

class CoinGeckoDetailModel {
  final String id;
  final String symbol;
  final String name;
  final String? imageLarge; // Dari json['image']['large']
  final String? descriptionEn; // Dari json['description']['en']
  final String? homepageUrl; // Dari json['links']['homepage'][0]

  // Data Pasar dari json['market_data']
  final double currentPriceIdr;
  final double? high24hIdr;
  final double? low24hIdr;
  final double? totalVolumeIdr;
  final double? totalVolumeBtc; // Atau dalam koin itu sendiri
  final double? priceChangePercentage24h;

  CoinGeckoDetailModel({
    required this.id,
    required this.symbol,
    required this.name,
    this.imageLarge,
    this.descriptionEn,
    this.homepageUrl,
    required this.currentPriceIdr,
    this.high24hIdr,
    this.low24hIdr,
    this.totalVolumeIdr,
    this.totalVolumeBtc,
    this.priceChangePercentage24h,
  });

  factory CoinGeckoDetailModel.fromJson(Map<String, dynamic> json) {
    // Helper untuk mengambil nilai double dari Map, menangani int atau double
    double? _parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return null;
    }

    // Mengambil data dari sub-map 'market_data'
    final marketData = json['market_data'] as Map<String, dynamic>? ?? {};
    final currentPriceMap = marketData['current_price'] as Map<String, dynamic>? ?? {};
    final high24hMap = marketData['high_24h'] as Map<String, dynamic>? ?? {};
    final low24hMap = marketData['low_24h'] as Map<String, dynamic>? ?? {};
    final totalVolumeMap = marketData['total_volume'] as Map<String, dynamic>? ?? {};

    return CoinGeckoDetailModel(
      id: json['id'] as String? ?? 'N/A',
      symbol: json['symbol'] as String? ?? 'N/A',
      name: json['name'] as String? ?? 'N/A',
      imageLarge: (json['image'] as Map<String, dynamic>?)?['large'] as String?,
      descriptionEn: (json['description'] as Map<String, dynamic>?)?['en'] as String?,
      homepageUrl: (json['links'] as Map<String, dynamic>?)?['homepage'] is List && 
                   (json['links']['homepage'] as List).isNotEmpty 
                   ? (json['links']['homepage'] as List)[0] as String?
                   : null,

      currentPriceIdr: _parseDouble(currentPriceMap['idr']) ?? 0.0,
      high24hIdr: _parseDouble(high24hMap['idr']),
      low24hIdr: _parseDouble(low24hMap['idr']),
      totalVolumeIdr: _parseDouble(totalVolumeMap['idr']),
      totalVolumeBtc: _parseDouble(totalVolumeMap['btc']), // Atau apa pun koinnya
      priceChangePercentage24h: _parseDouble(marketData['price_change_percentage_24h']),
    );
  }

  @override
  String toString() {
    return 'CoinGeckoDetailModel(id: $id, name: $name, currentPriceIdr: $currentPriceIdr)';
  }
}