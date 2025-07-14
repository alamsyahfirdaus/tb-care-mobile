import 'dart:convert';
import 'dart:developer';
import 'package:apk_tb_care/Main/Pasien/home.dart';
import 'package:apk_tb_care/Main/Petugas/home.dart';
import 'package:apk_tb_care/connection.dart';
import 'package:apk_tb_care/register.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  // Memuat kredensial yang tersimpan
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe && savedUsername != null && savedPassword != null) {
      setState(() {
        usernameController.text = savedUsername;
        passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Connection.BASE_URL}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_name', user['name']);
        await prefs.setString('user_id', user['id'].toString());

        // Simpan kredensial jika remember me dicentang
        if (_rememberMe) {
          await prefs.setString('saved_username', username);
          await prefs.setString('saved_password', password);

          await prefs.setBool('remember_me', true);
        } else {
          // Hapus kredensial yang tersimpan jika remember me tidak dicentang
          await prefs.remove('saved_username');
          await prefs.remove('saved_password');
          await prefs.setBool('remember_me', false);
        }

        if (mounted) {
          if (user['user_type_id'] == 2) {
            final patient = user['patient'];
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => HomePage(
                      name: user['name'],
                      userId: user['id'],
                      patientId: patient['id'],
                    ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => StaffHomePage(name: user['name']),
              ),
            );
          }
        }
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error['message'] ?? 'Login Gagal!')),
        );
        log('Login failed: ${error['message']}', name: 'LoginError');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi Kesalahan: $e')));
      log('Login failed: ${e.toString()}', name: 'LoginErrorCatch');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Column(
                children: [
                  Image.asset('assets/images/tbcare2.png', height: 160),
                ],
              ),
              // Card Form Login
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Selamat Datang di TB Care',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Username wajib diisi'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscureText,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _obscureText = !_obscureText,
                                  ),
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Password wajib diisi'
                                      : null,
                        ),
                        const SizedBox(height: 8),
                        // Remember Me Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Text('Ingat Saya'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _login();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Belum punya akun? '),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Daftar di sini',
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
                              const TextSpan(text: 'Lupa akun? '),
                              TextSpan(
                                text: 'Hubungi Admin',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () async {
                                        final Uri waUri = Uri.parse(
                                          'https://wa.me/62893829624',
                                        );
                                        if (await canLaunchUrl(waUri)) {
                                          await launchUrl(waUri);
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Tidak dapat membuka WhatsApp',
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                              ),
                            ],
                          ),
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
    );
  }
}
