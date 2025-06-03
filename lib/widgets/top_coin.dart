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

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  coin.imageUrl,
                  width: 28,
                  height: 28,
                  errorBuilder: (context, error, stackTrace) {
                    return const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.error, color: Colors.white, size: 14),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  coin.shortName.toUpperCase(),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              priceFormatter.format(coin.currentPrice),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
