import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

void main() {
  runApp(const InfoSummarizerApp());
}

class InfoSummarizerApp extends StatelessWidget {
  const InfoSummarizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '信息记录助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}