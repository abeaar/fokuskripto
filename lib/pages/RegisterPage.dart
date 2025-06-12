import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT PACKAGE SHARED PREFERENCES
import 'dart:convert'; 
import 'package:crypto/crypto.dart';

Future<String> _hashPassword(String password) async {
  var bytes = utf8.encode(password);
  var digest = sha256.convert(bytes);
  return digest.toString();
}

const String spFullNameKeySuffix = 'full_name';
const String spEmailKeySuffix = 'email';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool isObscure = true;
  bool isObscureConfirmPassword = true;
  late SharedPreferences loginData;
  late bool newUser;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String newUsername = _username.text.trim();
      String newPassword = _password.text.trim();

      if (prefs.containsKey('password_$newUsername')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Username sudah terdaftar! Silakan gunakan username lain.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      String hashedPassword = await _hashPassword(newPassword);

      await prefs.setString('password_$newUsername', hashedPassword);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi berhasil! Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(
        context,
      ); // Kembali ke halaman login setelah registrasi berhasil
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 410,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Text(
                    "Registrasi",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 22),

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
                  SizedBox(height: 18),
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
                  SizedBox(height: 18),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: isObscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Konfirmasi password tidak boleh kosong";
                      }
                      if (value != _password.text) {
                        return "Password tidak cocok";
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "Konfirmasi Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            isObscureConfirmPassword =
                                !isObscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    maxLength: 12,
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      child: Text("Register", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
