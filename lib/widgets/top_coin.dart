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

    return Container(
      // Dekorasi untuk menggantikan Card, memberikan border tipis
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grup Ikon dan Simbol Koin
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Agar Row tidak mengambil semua lebar
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Harga Koin
          Text(
            priceFormatter.format(coin.currentPrice),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}