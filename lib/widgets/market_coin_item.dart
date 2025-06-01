// lib/widgets/market_coin_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/coinGecko.dart'; // Model baru kita

class MarketCoinListItem extends StatelessWidget {
  final CoinGeckoMarketModel coin;
  final NumberFormat priceFormatter; // Untuk harga
  final NumberFormat volumeFormatter; // Untuk volume
  // Tambahkan formatter lain jika perlu

  const MarketCoinListItem({
    super.key,
    required this.coin,
    required this.priceFormatter,
    required this.volumeFormatter,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color changeColor =
        (coin.priceChangePercentage24h ?? 0) >= 0 ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            Image.network(
              coin.image,
              width: 36,
              height: 36,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  width: 36,
                  height: 36,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error_outline, size: 36);
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3, // Beri ruang lebih untuk Nama & Simbol
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    coin.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2, // Ruang untuk % perubahan
              child: Text(
                "${(coin.priceChangePercentage24h ?? 0).toStringAsFixed(2)}%",
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4, // Ruang untuk Harga & Volume
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceFormatter.format(coin.currentPrice),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Vol ${volumeFormatter.format(coin.totalVolume ?? 0)}",
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
