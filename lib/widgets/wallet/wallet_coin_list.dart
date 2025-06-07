import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../model/coinGecko.dart';
import 'wallet_coin_tile.dart';

class WalletCoinList extends StatelessWidget {
  final Box box;
  final List<CoinGeckoMarketModel> marketCoins;
  const WalletCoinList(
      {super.key, required this.box, required this.marketCoins});

  @override
  Widget build(BuildContext context) {
    if (box.isEmpty) {
      return const Expanded(child: Center(child: Text('No assets found.')));
    }
    return Expanded(
      child: ListView.builder(
        itemCount: box.length,
        itemBuilder: (context, index) {
          final asset = box.get(box.keyAt(index));
          if (asset == null) return const SizedBox.shrink();
          return WalletCoinTile(asset: asset, marketCoins: marketCoins);
        },
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
      ),
    );
  }
}
