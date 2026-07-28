import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'splash_page.dart';
import 'services/auth_session.dart';
import 'theme/brand_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.instance.load();
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
        scaffoldBackgroundColor: BrandColors.canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: BrandColors.accent,
          primary: BrandColors.secondarySurface,
          secondary: BrandColors.accent,
          surface: BrandColors.canvas,
          onPrimary: BrandColors.text,
          onSecondary: BrandColors.secondarySurface,
          brightness: Brightness.light,
        ),
        splashFactory: NoSplash.splashFactory,
      ),
      home: const SplashPage(),
    );
  }
}
