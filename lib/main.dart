import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const InnovatorApp());
}

class InnovatorApp extends StatelessWidget {
  const InnovatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innovator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F5F8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B1E28),
          brightness: Brightness.light,
        ),
        splashFactory: NoSplash.splashFactory,
      ),
      home: const LoginPage(),
    );
  }
}
