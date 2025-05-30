// Contoh penggunaan di main.dart
import 'package:flutter/material.dart';
import 'model/coin.dart';

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
      home: const CryptoListPage(), // Panggil halaman yang baru kita buat
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        // '/login': (context) => const LoginPage(),
      },

    );
  }
}
