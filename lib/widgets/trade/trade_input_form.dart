import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../services/providers/trade_provider.dart';
import '../../services/providers/wallet_provider.dart';

class TradeInputForm extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController totalController;
  final NumberFormat cryptoFormatter;

  const TradeInputForm({
    super.key,
    required this.amountController,
    required this.totalController,
    required this.cryptoFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('wallet_${context.read<WalletProvider>().username}').listenable(),
      builder: (context, Box box, _) {
        final tradeProvider = context.read<TradeProvider>();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Jumlah ${tradeProvider.selectedCoinSymbol}',
                suffixText: tradeProvider.selectedCoinSymbol,
              ),
              onChanged: (value) {
                final amount = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                totalController.text = (amount * tradeProvider.currentPrice).round().toString();
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total IDR',
                prefixText: 'Rp ',
              ),
              onChanged: (value) {
                final total = double.tryParse(value) ?? 0;
                if (tradeProvider.currentPrice > 0) {
                  amountController.text = cryptoFormatter.format(total / tradeProvider.currentPrice);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
