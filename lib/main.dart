// Contoh penggunaan di main.dart
import 'package:flutter/material.dart';
import 'model/coin.dart';
import 'pages/HomePage.dart';

// Asumsikan kode CryptoListPage di atas ada di file yang sama atau diimpor
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // 1. Ganti halaman utama ke HomePage
      home: const HomePage(), // Panggil HomePage di sini
      theme: ThemeData(
        primarySwatch: Colors.blue, // Anda bisa tetap menggunakan ini
      ),
      // 2. Routes Anda tetap dipertahankan
      routes: {
        // '/login': (context) => const LoginPage(),
        // '/crypto_list': (context) => const CryptoListPage(), // Jika ingin akses CryptoListPage via route
      },
    );
  }
}
