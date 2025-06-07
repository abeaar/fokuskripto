import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../model/coinGecko.dart';

class WalletCoinTile extends StatelessWidget {
  final dynamic asset;
  final List<CoinGeckoMarketModel> marketCoins;
  const WalletCoinTile(
      {super.key, required this.asset, required this.marketCoins});

  @override
  Widget build(BuildContext context) {
    final amountFormatter = NumberFormat('#,##0.########', 'en_US');
    final valueFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );
    final String? assetId = asset['id'];
    final isRupiah = (asset['short_name'] ?? '').toUpperCase() == 'IDR';
    Widget leadingIcon;
    if (isRupiah) {
      leadingIcon = Image.asset(
        'assets/logo/rupiah.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    } else {
      leadingIcon = Image.network(
        asset['image_url'] ?? '',
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, color: Colors.red);
        },
      );
    }
    final CoinGeckoMarketModel? marketCoin = marketCoins
        .where((coin) => coin.id == assetId)
        .cast<CoinGeckoMarketModel?>()
        .firstOrNull;
    final double? marketPrice = marketCoin?.currentPrice;
    final double amount = (asset['amount'] as num?)?.toDouble() ?? 0.0;
    final double price = (asset['price_in_idr'] as num?)?.toDouble() ?? 0.0;
    final double totalValuePerCoin = amount * price;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 20,
            child: leadingIcon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amountFormatter.format(amount)} ${asset['short_name'] ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                valueFormatter.format(totalValuePerCoin),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              if (marketPrice != null && marketPrice > 0)
                Text(
                  'Est. : ${valueFormatter.format(marketPrice * amount).replaceAll('IDR ', '')}',
                  style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
