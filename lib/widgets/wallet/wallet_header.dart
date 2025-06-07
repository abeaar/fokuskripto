import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../pages/WalletTab.dart';

class WalletHeader extends StatelessWidget {
  final double totalAssetValue;
  final WalletSummary summary;
  final double staticValue;
  final bool isBalanceVisible;
  final VoidCallback onToggleBalance;

  const WalletHeader({
    super.key,
    required this.totalAssetValue,
    required this.summary,
    required this.staticValue,
    required this.isBalanceVisible,
    required this.onToggleBalance,
  });

  String _formatCurrency(double value) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'IDR ',
      decimalDigits: 0,
    );
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Est. Asset ',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isBalanceVisible ? _formatCurrency(totalAssetValue) : '********',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            IconButton(
              icon: Icon(
                isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: onToggleBalance,
            ),
          ],
        ),
        Row(),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Return Value : ',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              isBalanceVisible
                  ? _formatCurrency(summary.returnValue).replaceAll('IDR ', '')
                  : '****',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: summary.returnValue >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: summary.returnPercentage >= 0
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isBalanceVisible
                    ? '${summary.returnPercentage >= 0 ? '+' : ''}${summary.returnPercentage.toStringAsFixed(2)}%'
                    : '****',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color:
                      summary.returnPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
