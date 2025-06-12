import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/coinGecko.dart';
import '../../pages/CoinDetail.dart';

class TopCoin extends StatelessWidget {
  final CoinGeckoMarketModel coin;
  final NumberFormat priceFormatter;

  const TopCoin({super.key, required this.coin, required this.priceFormatter});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Card(
      color: const Color.fromARGB(255, 255, 255, 255),
      elevation: 4,
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
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CoinDetailPage(
                      coinId: coin.id,
                      coinName: coin.name,
                      coinSymbol: coin.symbol,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol.toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 21,
                    ),
                  ),
                  Text(
                    priceFormatter
                        .format(coin.currentPrice)
                        .replaceAll('Rp ', ''),
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
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
          ],
        ),
      ),
    );
  }
}
