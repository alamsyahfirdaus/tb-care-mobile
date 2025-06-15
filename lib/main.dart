import 'package:apk_tb_care/login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'TB Care',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
