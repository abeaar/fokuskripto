import 'package:flutter/material.dart';
import '../../model/news_article.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsListItem extends StatelessWidget {
  final NewsArticle article;
  const NewsListItem({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(article.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          print('[DEBUG] Tidak bisa launch url: $uri');
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        color: const Color.fromARGB(255, 255, 255, 255),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        shadowColor: const Color.fromARGB(255, 216, 216, 216),
        
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: article.urlToImage.isNotEmpty
                    ? Image.network(
                        article.urlToImage,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.image),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${article.source} • ${article.publishedAt.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
