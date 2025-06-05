import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/providers/trade_provider.dart';
import '../../services/providers/wallet_provider.dart';

class TradeBalanceInfo extends StatelessWidget {
  final NumberFormat priceFormatter;
  final NumberFormat cryptoFormatter;

  const TradeBalanceInfo({
    super.key,
    required this.priceFormatter,
    required this.cryptoFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('wallet_${context.read<WalletProvider>().username}').listenable(),
      builder: (context, Box box, _) {
        final tradeProvider = context.read<TradeProvider>();
        final idrBalance = (box.get('IDR', defaultValue: {'amount': 0.0})['amount'] as num).toDouble();
        final cryptoBalance = (box.get(tradeProvider.selectedCoinSymbol, defaultValue: {'amount': 0.0})['amount'] as num).toDouble();

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
                'Saldo Tersedia:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                tradeProvider.currentMode == TradeMode.buy
                    ? priceFormatter.format(idrBalance)
                    : '${cryptoFormatter.format(cryptoBalance)} ${tradeProvider.selectedCoinSymbol}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        );
      },
    );
  }
}
