import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/coin.dart'; // Pastikan path ini benar

class CoinListItem extends StatelessWidget {
  final Coin coin;
  final NumberFormat priceFormatter;

  const CoinListItem({
    super.key,
    required this.coin,
    required this.priceFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Image.network(
              coin.imageUrl,
              width: 40, // Sedikit lebih kecil untuk list di dashboard
              height: 40,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                // Menampilkan ukuran progress indicator yang lebih kecil
                return SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0, // Garis lebih tipis
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 40);
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: const TextStyle(
                      fontSize: 17, // Sedikit disesuaikan
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    coin.shortName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13, // Sedikit disesuaikan
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              priceFormatter.format(coin.currentPrice),
              style: const TextStyle(
                fontSize: 15, // Sedikit disesuaikan
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
