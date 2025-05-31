import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pages/LoginPage.dart';
import 'pages/RegisterPage.dart';
import 'pages/HomePage.dart';

// Asumsikan kode CryptoListPage di atas ada di file yang sama atau diimpor
void main() async {
  await Hive.initFlutter();
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

      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
