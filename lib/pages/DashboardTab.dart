import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/coin.dart';
import '../widgets/coin_list_item.dart';
import '../services/api_service.dart';
import '../widgets/top_coin.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _error;
  List<Coin> _coins = [];
  final NumberFormat _priceFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchCoins();
  }

  Future<void> _fetchCoins() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetchedCoins = await _apiService.fetchCoins();
      if (!mounted) return;
      setState(() {
        _coins = fetchedCoins;
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

  // Widget baru untuk membangun bagian ringkasan koin
  Widget _buildSummarySection() {
    if (_coins.isEmpty) {
      return const SizedBox.shrink(); // Tidak tampilkan apa-apa jika koin kosong
    }
    final topCoin = _coins.take(3).toList();
    if (topCoin.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            "Top Coin",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
          ), // Padding untuk Row
          child: Row(
            children: <Widget>[
              // Eksplisit membuat List<Widget>
              ...topCoin.map((coin) {
                // Spread hasil map
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: TopCoin(coin: coin, priceFormatter: _priceFormatter),
                  ),
                );
              }).toList(),
              ...List.generate(
                3 - topCoin.length,
                (index) => Expanded(child: Container()),
                growable: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _fetchCoins,
      child: ListView.builder(
        itemCount: 1 + 1 + _coins.length, // Summary + Judul List + Item List
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummarySection();
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                "Trending",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
          }
          final coinIndex = index - 2;
          return CoinListItem(
            coin: _coins[coinIndex],
            priceFormatter: _priceFormatter,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}
