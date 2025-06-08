import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/providers/market_provider.dart';
import '../model/coinGecko.dart';
import '../widgets/dashboardtab/coin_list_item.dart';
import '../widgets/dashboardtab/top_coin.dart';
import '../services/providers/news_provider.dart';
import '../model/news_article.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/dashboardtab/news_list_item.dart';

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
        SizedBox(
          width: double.infinity,
          child: Row(
            children: topCoins.map((coin) {
              return Expanded(
                child: TopCoin(
                  coin: coin,
                  priceFormatter: priceFormatter,
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: [
              if (marketData.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 10),
              _buildSummarySection(context, marketData.topCoins),
              _buildTrendingSection(context, marketData.trendingCoins),
              const SizedBox(height: 20),
              Text('News',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Consumer<NewsProvider>(
                builder: (context, newsProvider, _) {
                  if (newsProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (newsProvider.error != null) {
                    return Center(child: Text('Error: ${newsProvider.error}'));
                  }
                  if (newsProvider.articles.isEmpty) {
                    return const Center(child: Text('No news found.'));
                  }
                  return Column(
                    children: List.generate(
                      newsProvider.articles.length > 5
                          ? 5
                          : newsProvider.articles.length,
                      (index) =>
                          NewsListItem(article: newsProvider.articles[index]),
                    ),
                  );
                },
              ),
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
