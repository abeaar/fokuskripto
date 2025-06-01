class walletAsset {
  final String hiveKey; 
  final String name;
  final String shortName;
  final String imageUrl;
  final double amount;
  final double currentPriceInIdr; // Harga live dari API
  final double totalValueInIdr;   // amount * currentPriceInIdr
  final double? acquisitionPriceInIdr; // Harga perolehan dari Hive (jika ada)

  walletAsset({
    required this.hiveKey,
    required this.name,
    required this.shortName,
    required this.imageUrl,
    required this.amount,
    required this.currentPriceInIdr,
    required this.totalValueInIdr,
    this.acquisitionPriceInIdr,
  });
}