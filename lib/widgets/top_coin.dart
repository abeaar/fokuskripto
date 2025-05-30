import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/coin.dart'; // Pastikan path ini benar

class TopCoin extends StatelessWidget {
  final Coin coin;
  final NumberFormat priceFormatter;

  const TopCoin({super.key, required this.coin, required this.priceFormatter});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    // Menghilangkan SizedBox dengan lebar tetap di sini
    // Lebar akan diatur oleh parent (misalnya Expanded di dalam Row)
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Padding bisa disesuaikan
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.network(
              coin.imageUrl,
              width: 32, // Ukuran gambar bisa disesuaikan
              height: 32,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 32);
              },
            ),
            const SizedBox(height: 8),
            Text(
              coin.shortName.toUpperCase(),
              style: theme.textTheme.titleSmall?.copyWith(
                // Mungkin titleSmall atau bodyLarge
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              priceFormatter.format(coin.currentPrice),
              style: theme.textTheme.bodySmall, // Mungkin bodySmall agar muat
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
