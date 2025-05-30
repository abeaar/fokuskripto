// Contoh penggunaan di main.dart
import 'package:flutter/material.dart';
import 'model/coin.dart';

import 'pages/LoginPage.dart';
import 'pages/RegisterPage.dart';
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

      initialRoute: '/login_page',
      routes: {
        '/login_page': (context) => LoginPage(),
        '/register_page': (context) => RegisterPage(),
        '/home_page': (context) => HomePage(),
      },

      theme: ThemeData(
        primarySwatch: Colors.blue, // Anda bisa tetap menggunakan ini
      ),

    );
  }
}
