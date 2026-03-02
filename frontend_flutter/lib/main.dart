import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const KritikApp());
}

class KritikApp extends StatelessWidget {
  const KritikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kritik App',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
