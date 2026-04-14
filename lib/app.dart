import 'package:flutter/material.dart';

class MtgScannerApp extends StatelessWidget {
  const MtgScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTG Scanner',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const Scaffold(body: Center(child: Text('MTG Scanner'))),
    );
  }
}
