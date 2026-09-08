import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inner_flare/features/loading/screens/loading_screen.dart';

void main() {
  runApp(const ProviderScope(child: InnerFlareApp()));
}

class InnerFlareApp extends StatelessWidget {
  const InnerFlareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InnerFlare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoadingScreen(),
    );
  }
}
