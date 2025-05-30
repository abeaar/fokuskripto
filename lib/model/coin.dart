import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import paket intl untuk format angka

// 1. Model untuk data koin (Best Practice)
// Ini membantu kita menghindari kesalahan pengetikan dan membuat kode lebih aman.
class Coin {
  final int id;
  final String name;
  final String shortName;
  final String imageUrl;
  final num
  currentPrice; // Menggunakan 'num' agar fleksibel (bisa int atau double)

  Coin({
    required this.id,
    required this.name,
    required this.shortName,
    required this.imageUrl,
    required this.currentPrice,
  });

  // Factory constructor untuk membuat objek Coin dari JSON
  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      id: json['id'],
      name: json['name'],
      shortName: json['short_name'],
      imageUrl: json['image_url'],
      currentPrice: json['current_price'],
    );
  }
}

// Halaman utama yang akan menampilkan daftar koin
class CryptoListPage extends StatefulWidget {
  const CryptoListPage({super.key});

  @override
  State<CryptoListPage> createState() => _CryptoListPageState();
}

class _CryptoListPageState extends State<CryptoListPage> {
  // Variabel untuk menyimpan state
  bool _isLoading = true;
  String? _error;
  List<Coin> _coins = [];

  @override
  void initState() {
    super.initState();
    // Panggil API saat halaman pertama kali dibuka
    _fetchCoins();
  }

  // 2. Fungsi untuk mengambil data dari API
  Future<void> _fetchCoins() async {
    const String apiUrl =
        'https://be-projek-mobile-713031961242.us-central1.run.app/coins';
    final uri = Uri.parse(apiUrl);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        // Ubah setiap item JSON menjadi objek Coin dan simpan ke state
        setState(() {
          _coins = jsonData.map((json) => Coin.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat data. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Terjadi error: $e';
        _isLoading = false;
      });
    }
  }

  // 3. Widget untuk membangun setiap baris data koin
  Widget _buildCoinRow(Coin coin) {
    // Formatter untuk mengubah angka menjadi format mata uang Rupiah
    final priceFormatter = NumberFormat.currency(
      locale: 'id_ID', // Locale Indonesia
      symbol: 'Rp ', // Simbol Rupiah
      decimalDigits: 0, // Tidak ada angka di belakang koma
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Gambar Koin
            Image.network(
              coin.imageUrl,
              width: 50,
              height: 50,
              // Tampilkan loading indicator saat gambar dimuat
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator();
              },
              // Tampilkan ikon error jika gambar gagal dimuat
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 50);
              },
            ),
            const SizedBox(width: 16),
            // Nama dan Short Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    coin.shortName.toUpperCase(),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Harga
            Text(
              priceFormatter.format(coin.currentPrice),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Tampilan utama halaman
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monitoring Harga Kripto')),
      body: _buildBody(),
    );
  }

  // Fungsi untuk menentukan body apa yang akan ditampilkan (loading, error, atau data)
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return ListView.builder(
      itemCount: _coins.length,
      itemBuilder: (context, index) {
        return _buildCoinRow(_coins[index]);
      },
    );
  }
}
