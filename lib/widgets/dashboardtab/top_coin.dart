import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/coinGecko.dart';

class TopCoin extends StatelessWidget {
  final CoinGeckoMarketModel coin;
  final NumberFormat priceFormatter;

  const TopCoin({super.key, required this.coin, required this.priceFormatter});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Card(
      color: const Color.fromARGB(255, 255, 255, 255),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      shadowColor: const Color.fromARGB(255, 216, 216, 216),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  coin.symbol.toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 21,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              priceFormatter.format(coin.currentPrice).replaceAll('Rp ', ''),
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (coin.priceChangePercentage24h != null)
              Text(
                '${coin.priceChangePercentage24h! >= 0 ? '+' : ''}${coin.priceChangePercentage24h!.toStringAsFixed(2)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: coin.priceChangePercentage24h! >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
