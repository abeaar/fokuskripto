import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import '../model/coin.dart'; // Path ke model Coin
import '../widgets/coin_list_item.dart'; // Path ke widget CoinListItem

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
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
    // Beritahu Flutter untuk rebuild jika widget masih ada di tree
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null; // Reset error setiap kali fetch
    });

    const String apiUrl =
        'https://be-projek-mobile-713031961242.us-central1.run.app/coins';
    final uri = Uri.parse(apiUrl);

    try {
      final response = await http.get(uri);
      if (!mounted) return; // Cek lagi setelah await

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _coins = jsonData.map((json) => Coin.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat data. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      // Tambahkan tombol coba lagi
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchCoins, // Panggil fetchCoins lagi
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_coins.isEmpty) {
      return const Center(child: Text('Tidak ada data koin.'));
    }

    // Nanti kita bisa tambahkan elemen dashboard lain di sini, di atas ListView
    return RefreshIndicator(
      onRefresh: _fetchCoins, // Fungsi refresh
      child: ListView.builder(
        itemCount: _coins.length,
        itemBuilder: (context, index) {
          return CoinListItem(
            coin: _coins[index],
            priceFormatter: _priceFormatter,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tidak perlu Scaffold di sini karena DashboardTab adalah bagian dari HomePage
    // yang sudah memiliki Scaffold.
    // Kita tambahkan AppBar di HomePage jika ingin judul spesifik per tab.
    return _buildContent();
  }
}
