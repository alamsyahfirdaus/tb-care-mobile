import 'package:apk_tb_care/Main/login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.blue[100],
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue[100]!,
          primary: Colors.blue,
          secondary: Colors.amber, // kalau butuh accent
        ),
      ),
      title: 'TB Care',
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
