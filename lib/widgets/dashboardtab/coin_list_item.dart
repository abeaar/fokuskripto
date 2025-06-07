import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/coinGecko.dart';

class CoinListItem extends StatelessWidget {
  final CoinGeckoMarketModel coin;
  final NumberFormat priceFormatter;

  const CoinListItem({
    super.key,
    required this.coin,
    required this.priceFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            print('Tapped on ${coin.name}');
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
            child: Row(
              children: [
                // --- IKON KOIN ---
                Image.network(
                  coin.image,
                  width: 36,
                  height: 36,
                  errorBuilder: (context, error, stackTrace) {
                    return const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.error, color: Colors.white, size: 18),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coin.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.w600, // Sedikit tebal untuk nama
                            ),
                      ),
                      Text(
                        coin.symbol.toUpperCase(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors
                                  .grey[600], // Warna lebih redup untuk simbol
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // --- HARGA KOIN ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceFormatter.format(coin.currentPrice),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500, // Berat font medium
                          ),
                    ),
                    if (coin.priceChangePercentage24h != null)
                      Text(
                        '${coin.priceChangePercentage24h!.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: coin.priceChangePercentage24h! >= 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(height: 1, thickness: 0.5),
        ),
      ],
    );
  }
}
