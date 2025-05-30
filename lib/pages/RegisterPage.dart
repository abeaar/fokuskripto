import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT PACKAGE SHARED PREFERENCES

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool isObscure = true;
  late SharedPreferences loginData;
  late bool newUser;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _register() async {
    if (formKey.currentState!.validate()) {
      SharedPreferences loginData = await SharedPreferences.getInstance();
      String? registeredUsername = loginData.getString('registered_username');

      // Cek apakah username sudah terdaftar
      if (registeredUsername != null && registeredUsername == _username.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username sudah terdaftar!')),
        );
        return;
      }

      // Jika belum terdaftar, simpan data
      await loginData.setString('registered_username', _username.text.trim());
      await loginData.setString('registered_password', _password.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Kembali ke halaman login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 300,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Text("Registrasi", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  SizedBox( height: 22 ),

                  TextFormField(
                    validator: (value) {
                      if(value==null || value.isEmpty) {
                        return "Silahkan isi";
                      }
                      return null;
                    },
                    controller: _username,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      labelText: "Username",
                      counterText: ""
                    ),
                    maxLength: 64,
                  ),
                  SizedBox( height: 14 ),

                  TextFormField(
                    validator: (value) {
                      if(value==null || value.isEmpty) {
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
                        icon: Icon(isObscure ? Icons.visibility : Icons.visibility_off)) 
                    ),
                    maxLength: 12,
                  ),
                  SizedBox( height: 18 ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register, 
                      child: Text("Register", style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)
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