import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT PACKAGE SHARED PREFERENCES
import 'dart:convert'; // Untuk utf8.encode
import 'package:crypto/crypto.dart'; // Untuk sha256
import 'package:hive_flutter/hive_flutter.dart';

import './HomePage.dart';

const String spIsLoginKey = 'isLogin';
const String spUsernameKey = 'username';

Future<String> _hashPassword(String password) async {
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool isObscure = true;
  late bool newUser;

  @override
  void initState() {
    super.initState();
    checkIfAlreadyLogin();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  checkIfAlreadyLogin() async {
    SharedPreferences loginData = await SharedPreferences.getInstance();
    bool isLoggedIn = loginData.getBool(spIsLoginKey) ?? false;

    if (isLoggedIn) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
      );
    }
  }

  Future<void> _login() async {
    if (formKey.currentState!.validate()) {
      SharedPreferences loginData = await SharedPreferences.getInstance();
      String inputUsername = _username.text.trim();
      String inputPassword = _password.text.trim();

      String hashedInputPassword = await _hashPassword(inputPassword);
      String? storedHashedPassword = loginData.getString(
        'password_$inputUsername',
      );

      if (storedHashedPassword != null &&
          storedHashedPassword == hashedInputPassword) {
        await loginData.setBool(spIsLoginKey, true);
        // Simpan username yang sedang aktif untuk digunakan di ProfilePage dll.
        await loginData.setString(spUsernameKey, inputUsername);
        if (!mounted) return;

        var userWallet = await Hive.openBox('wallet_$inputUsername');
        if (userWallet.isEmpty) {
          await userWallet.put('IDR', {
            'name': 'Rupiah',
            'short_name': 'IDR',
            'image_url':
                'https://cdn-icons-png.flaticon.com/512/13893/13893854.png',
            'amount': 0,
            'price_in_idr': 1,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil login'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Login gagal
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login gagal: Username atau password salah'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 600,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: const Color.fromARGB(255, 59, 58, 58),
                    child: Image.asset('assets/logo/kriptoin.png'),
                  ),
                  Text(
                    "Kriptoin;",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courrier',
                    ),
                  ),
                  SizedBox(height: 24),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Silahkan isi";
                      }
                      return null;
                    },
                    controller: _username,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      labelText: "Username",
                      counterText: "",
                    ),
                    maxLength: 64,
                  ),
                  SizedBox(height: 14),
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Silahkan isi";
                      }
                      return null;
                    },
                    controller: _password,
                    obscureText: isObscure,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            isObscure = !isObscure;
                          });
                        },
                        icon: Icon(
                          isObscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    maxLength: 12,
                  ),
                  SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: Text("Login", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.black, fontSize: 16),
                          children: <TextSpan>[
                            TextSpan(
                              text: "Signup",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: 16,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/register_page',
                                    (route) => true,
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
