import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/providers/market_provider.dart';
import '../widgets/market/market_coin_item.dart';
import '../model/coinGecko.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class MarketTab extends StatefulWidget {
  const MarketTab({super.key});

  @override
  State<MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  StreamSubscription? _accelSub;
  double _shakeThreshold = 15.0;
  DateTime? _lastShakeTime;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _accelSub = accelerometerEvents.listen((event) {
      double acceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (acceleration > _shakeThreshold) {
        if (_lastShakeTime == null ||
            DateTime.now().difference(_lastShakeTime!) > Duration(seconds: 1)) {
          _lastShakeTime = DateTime.now();
          final marketProvider = context.read<MarketProvider>();
          marketProvider.shuffleCoins();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Urutan koin diacak (shake)!')),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  // Formatter untuk harga dan volume
  static final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  static final NumberFormat _volumeFormatter = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  );

  Widget _buildMarketContent(BuildContext context, MarketProvider marketData) {
    if (marketData.isLoading && marketData.allCoins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final filteredCoins = _searchQuery.isEmpty
        ? marketData.allCoins
        : marketData.allCoins.where((coin) {
            final q = _searchQuery.toLowerCase();
            return coin.name.toLowerCase().contains(q) ||
                coin.symbol.toLowerCase().contains(q);
          }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search Coin',
              prefixIcon: Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
        Expanded(child: _buildMarketContentList(context, filteredCoins)),
      ],
    );
  }

  Widget _buildMarketContentList(
      BuildContext context, List<CoinGeckoMarketModel> coins) {
    if (coins.isEmpty) {
      return const Center(child: Text('No coins found.'));
    }
    return ListView.builder(
      itemCount: coins.length,
      itemBuilder: (context, index) {
        return MarketCoinListItem(
          coin: coins[index],
          priceFormatter: _priceFormatter,
          volumeFormatter: _volumeFormatter,
        );
      },
    );
  }

  Widget _buildSortHeader(
    BuildContext context,
    MarketProvider provider,
    String title,
    String field,
    int flex,
    MainAxisAlignment alignment,
  ) {
    final isActive = provider.currentSortField == field;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => provider.sortBy(field),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: alignment,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? Colors.green[700] : Colors.grey[700],
                ),
              ),
              if (isActive)
                Icon(
                  provider.isAscendingSort
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: Colors.green[700],
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketProvider>(
      builder: (context, marketData, _) =>
          _buildMarketContent(context, marketData),
    );
  }
}
