import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api/coin_gecko_api.dart';
import '../services/api/crypto_news_api.dart';
import '../services/api/api_exception.dart';
import '../model/coinGecko.dart';
import '../model/crypto_news.dart';
import '../widgets/dashboardtab/coin_list_item.dart';
import '../widgets/dashboardtab/top_coin.dart';
import '../widgets/dashboardtab/news_card.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final CoinGeckoApi _api = CoinGeckoApi();
  final CryptoNewsApi _newsApi = CryptoNewsApi();

  bool _isLoading = true;
  String? _error;
  List<CoinGeckoMarketModel> _topCoins = [];
  List<CoinGeckoMarketModel> _trendingCoins = [];
  List<CryptoNews> _news = [];

  final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getMarkets(
          vsCurrency: 'idr',
          perPage: 8,
          page: 1,
        ),
        // _newsApi.getLatestNews(limit: 5), // Temporarily disabled
      ]);

      if (!mounted) return;
      setState(() {
        // Handle coins data
        final List<CoinGeckoMarketModel> fetchedCoins =
            results[0] as List<CoinGeckoMarketModel>;
        _topCoins = fetchedCoins.take(3).toList();
        _trendingCoins = fetchedCoins.skip(3).take(5).toList();

        // Handle news data
        // _news = results[1] as List<CryptoNews>; // Temporarily disabled

        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat data: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan tidak terduga: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildSummarySection() {
    if (_topCoins.isEmpty) {
      return const SizedBox.shrink();
    }

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
            children: _topCoins.map((coin) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: TopCoin(
                    coin: coin,
                    priceFormatter: _priceFormatter,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingSection() {
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
        ..._trendingCoins.map((coin) => CoinListItem(
              coin: coin,
              priceFormatter: _priceFormatter,
            )),
      ],
    );
  }

  Widget _buildNewsSection() {
    if (_news.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            "Latest News",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ..._news.map((news) => NewsCard(news: news)),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        children: [
          _buildSummarySection(),
          _buildTrendingSection(),
          // _buildNewsSection(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}
