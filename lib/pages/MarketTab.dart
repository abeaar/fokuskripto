import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/coinGecko.dart';
import '../services/api_gecko.dart';
import '../services/base_network.dart'; // Untuk NetworkException
import '../widgets/market_coin_item.dart';


class MarketTab extends StatefulWidget {
  const MarketTab({super.key});

  @override
  State<MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  final ApiServiceGecko _apiServiceGecko = ApiServiceGecko();
  bool _isLoading = true;
  String? _error;
  List<CoinGeckoMarketModel> _marketCoins = [];

  // Formatter untuk harga dan volume
  final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final NumberFormat _volumeFormatter = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
  }

  Future<void> _fetchMarketData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Ambil data dari CoinGecko, default vs_currency='idr', per_page=100
      final fetchedCoins = await _apiServiceGecko.fetchCoinMarkets(
        vsCurrency: 'idr',
        perPage: 100,
      );
      if (!mounted) return;
      setState(() {
        _marketCoins = fetchedCoins;
        _isLoading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
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

  Widget _buildMarketContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchMarketData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_marketCoins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tidak ada data pasar koin.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchMarketData,
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      );
    }

    // Nanti di sini akan ada TabBar untuk "All Coin" dan "Favorite"
    // Untuk sekarang, tampilkan semua koin dulu
    return RefreshIndicator(
      onRefresh: _fetchMarketData,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 33.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    '24H Chg',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Price / Vol 24H',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _marketCoins.length,
              itemBuilder: (context, index) {
                return MarketCoinListItem(
                  coin: _marketCoins[index],
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

  @override
  Widget build(BuildContext context) {
    // Tidak perlu Scaffold karena ini akan jadi body dari salah satu tab di HomePage
    return _buildMarketContent();
  }
}
