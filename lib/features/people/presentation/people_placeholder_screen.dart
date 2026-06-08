import 'package:flutter/material.dart';

class PeoplePlaceholderScreen extends StatelessWidget {
  const PeoplePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('People')),
      body: const Center(child: Text('People management is coming soon.')),
    );
  }
}
