import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT PACKAGE SHARED PREFERENCES

import './HomePage.dart';

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

  checkIfAlreadyLogin() async {
    SharedPreferences loginData = await SharedPreferences.getInstance();
    newUser = (loginData.getBool('isLogin') ?? true);

    if(newUser == false) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
        (route) => false,
        arguments: "Successfully logged in"
      );
    }
  }

  Future<void> _login() async {
    if (formKey.currentState!.validate()) {
      SharedPreferences loginData = await SharedPreferences.getInstance();
      String? registeredUsername = loginData.getString('registered_username');
      String? registeredPassword = loginData.getString('registered_password');

      // Cek apakah user sudah pernah registrasi
      if ((registeredUsername != null && registeredPassword != null) &&
        _username.text.trim() == registeredUsername &&
        _password.text.trim() == registeredPassword) {
        await loginData.setBool('isLogin', true);
        await loginData.setString('username', _username.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil login'), backgroundColor: Colors.green,),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('login gagal'), backgroundColor: Colors.red,),
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
            height: 320,
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  Text("Silahkan Login", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  SizedBox( height: 24 ),

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
                  SizedBox( height: 14 ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login, 
                      child: Text("Login", style: TextStyle(fontSize: 18),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)
                        ),
                      ),
                    ),
                  ),
                  SizedBox( height: 10 ),

                  SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                          children: <TextSpan> [
                            TextSpan(
                              text: "Signup",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontSize: 16
                              ),
                              recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context, 
                                  '/register_page', 
                                  (route) => true
                                );
                              }
                            )
                          ]
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