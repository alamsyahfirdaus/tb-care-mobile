import 'package:apk_tb_care/Main/login.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }

  // For Android 11+ (API 30+)
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
  await initializeDateFormatting('id_ID', '');
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
