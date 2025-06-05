import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/providers/trade_provider.dart';

class TradeExecuteButton extends StatelessWidget {
  final TextEditingController amountController;

  const TradeExecuteButton({
    super.key,
    required this.amountController,
  });

  @override
  Widget build(BuildContext context) {
    final tradeProvider = context.read<TradeProvider>();
    
    return ElevatedButton(
      onPressed: () async {
        try {
          final amount = double.tryParse(
                amountController.text.replaceAll(',', '.'),
              ) ?? 0;
          await tradeProvider.executeTrade(amount);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaksi berhasil!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: tradeProvider.currentMode == TradeMode.buy
            ? Colors.green
            : Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        tradeProvider.currentMode == TradeMode.buy ? 'BELI' : 'JUAL',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}
