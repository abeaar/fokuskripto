import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../model/coinGecko.dart';
import '../services/providers/market_provider.dart';
import '../widgets/market/market_coin_item.dart';

class MarketTab extends StatelessWidget {
  const MarketTab({super.key});

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

    if (marketData.error != null && marketData.allCoins.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                marketData.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => marketData.fetchData(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (marketData.allCoins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tidak ada data pasar koin.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => marketData.fetchData(),
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => marketData.fetchData(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 26.0,
              vertical: 10.0,
            ),
            child: Consumer<MarketProvider>(
              builder: (context, marketProvider, _) => Row(
                children: [
                  _buildSortHeader(context, marketProvider, 'Name', 'name', 3,
                      MainAxisAlignment.start),
                  _buildSortHeader(context, marketProvider, '24H Chg',
                      'price_change_24h', 3, MainAxisAlignment.center),
                  _buildSortHeader(context, marketProvider, 'Price / Vol 24H',
                      'current_price', 4, MainAxisAlignment.end),
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          if (marketData.isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: marketData.allCoins.length,
              itemBuilder: (context, index) {
                return MarketCoinListItem(
                  coin: marketData.allCoins[index],
                  priceFormatter: _priceFormatter,
                  volumeFormatter: _volumeFormatter,
                );
              },
            ),
          ),
        ],
      ),
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
