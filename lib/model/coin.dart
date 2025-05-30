class Coin {
  final int id;
  final String name;
  final String shortName;
  final String imageUrl;
  final num currentPrice;

  Coin({
    required this.id,
    required this.name,
    required this.shortName,
    required this.imageUrl,
    required this.currentPrice,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'],
      name: json['name'],
      shortName: json['short_name'],
      imageUrl: json['image_url'],
      currentPrice: json['current_price'],
    );
  }
}
