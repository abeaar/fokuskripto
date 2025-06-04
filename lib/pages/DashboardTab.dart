import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/providers/market_provider.dart';
import '../model/coinGecko.dart';
import '../widgets/dashboardtab/coin_list_item.dart';
import '../widgets/dashboardtab/top_coin.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  NumberFormat _getPriceFormatter() {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
  }

  Widget _buildSummarySection(
      BuildContext context, List<CoinGeckoMarketModel> topCoins) {
    if (topCoins.isEmpty) {
      return const SizedBox.shrink();
    }

    final priceFormatter = _getPriceFormatter();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            "Top Coin",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: topCoins.map((coin) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: TopCoin(
                    coin: coin,
                    priceFormatter: priceFormatter,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection(
      BuildContext context, List<CoinGeckoMarketModel> trendingCoins) {
    final priceFormatter = _getPriceFormatter();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            "Trending",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...trendingCoins.map((coin) => CoinListItem(
              coin: coin,
              priceFormatter: priceFormatter,
            )),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<MarketProvider>(
      builder: (context, marketData, _) {
        if (marketData.isLoading && marketData.allCoins.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (marketData.error != null && marketData.allCoins.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(marketData.error!,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => marketData.fetchData(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => marketData.fetchData(),
          child: ListView(
            children: [
              if (marketData.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              _buildSummarySection(context, marketData.topCoins),
              _buildTrendingSection(context, marketData.trendingCoins),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }
}
