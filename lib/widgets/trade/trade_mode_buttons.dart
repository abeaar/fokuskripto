import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/providers/trade_provider.dart';

class TradeModeButtons extends StatelessWidget {
  final TradeProvider tradeProvider;

  const TradeModeButtons({
    super.key,
    required this.tradeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => tradeProvider.setTradeMode(TradeMode.buy),
            style: ElevatedButton.styleFrom(
              backgroundColor: tradeProvider.currentMode == TradeMode.buy
                  ? Colors.green
                  : Colors.grey,
            ),
            child: const Text('Beli'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => tradeProvider.setTradeMode(TradeMode.sell),
            style: ElevatedButton.styleFrom(
              backgroundColor: tradeProvider.currentMode == TradeMode.sell
                  ? Colors.red
                  : Colors.grey,
            ),
            child: const Text('Jual'),
          ),
        ),
      ],
    );
  }
}
