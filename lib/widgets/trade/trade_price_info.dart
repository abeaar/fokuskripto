import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TradePriceInfo extends StatelessWidget {
  final NumberFormat priceFormatter;
  final double currentPrice;

  const TradePriceInfo({
    super.key,
    required this.priceFormatter,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Harga Saat Ini:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            priceFormatter.format(currentPrice),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
