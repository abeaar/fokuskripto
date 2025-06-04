import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Color bgColor;

  @override
  void initState() {
    super.initState();
    // Generate random background color
    final random = Random();
    bgColor = Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate loading
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (!mounted) return;
    if (username != null) {
      Navigator.pushReplacementNamed(context, '/home_page');
    } else {
      Navigator.pushReplacementNamed(context, '/login_page');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'FokusKripto',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Loading... Please wait',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
