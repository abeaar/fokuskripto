class CryptoNews {
  final String id;
  final String title;
  final String body;
  final String url;
  final String imageUrl;
  final String source;
  final DateTime publishedAt;
  final List<String> categories;
  final List<String> tags;

  CryptoNews({
    required this.id,
    required this.title,
    required this.body,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
    required this.categories,
    required this.tags,
  });

  factory CryptoNews.fromJson(Map<String, dynamic> json) {
    return CryptoNews(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      url: json['url'] ?? '',
      imageUrl: json['imageurl'] ?? '',
      source: json['source'] ?? '',
      publishedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['published_on'] ?? 0) * 1000,
      ),
      categories: List<String>.from(json['categories'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}
