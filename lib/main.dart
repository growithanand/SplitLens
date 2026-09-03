import 'package:flutter/material.dart';

void main() {
  runApp(const SplitLensApp());
}

class SplitLensApp extends StatelessWidget {
  const SplitLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('SplitLens'))),
    );
  }
}
