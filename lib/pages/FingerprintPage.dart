import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FingerprintPage extends StatefulWidget {
  const FingerprintPage({Key? key}) : super(key: key);

  @override
  State<FingerprintPage> createState() => _FingerprintPageState();
}

class _FingerprintPageState extends State<FingerprintPage> {
  String _status = 'Perlu autentikasi sidik jari';
  bool _isAuthenticating = false;
  int _failCount = 0;
  final int _maxFail = 5;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLogin', false);
    await prefs.remove('username');
    await prefs.remove('lastActiveTime');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login_page', (route) => false);
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _status = 'Menunggu autentikasi...';
    });
    final LocalAuthentication auth = LocalAuthentication();
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk melanjutkan',
        options:
            const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
            'lastActiveTime', DateTime.now().millisecondsSinceEpoch);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home_page');
      } else {
        setState(() {
          _failCount++;
          if (_failCount >= _maxFail) {
            _status = 'Terlalu banyak percobaan gagal. Silakan login manual.';
            _isAuthenticating = false;
          } else {
            _status = 'Autentikasi gagal ($_failCount/$_maxFail). Coba lagi.';
            _isAuthenticating = false;
          }
        });
        if (_failCount >= _maxFail) {
          await Future.delayed(const Duration(seconds: 1));
          await _forceLogout();
        }
      }
    } catch (e) {
      setState(() {
        _status = 'Error: silahkan tunggu 30 detik';
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fingerprint Required',
          style: TextStyle(
            color: Color.fromARGB(255, 59, 160, 63),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 10,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isAuthenticating ? null : _authenticate,
              child: const Text('Coba Lagi'),
            ),
            const SizedBox(height: 16),
            Text('Atau'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await _forceLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Login Manual'),
            ),
          ],
        ),
      ),
    );
  }
}
