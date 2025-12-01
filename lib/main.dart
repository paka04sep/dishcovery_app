import 'package:flutter/material.dart';
import 'starting_screen/loading_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dishcovery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF539DF3)),
        useMaterial3: true,
      ),
      home: const LoadingScreen(),
    );
  }
}
