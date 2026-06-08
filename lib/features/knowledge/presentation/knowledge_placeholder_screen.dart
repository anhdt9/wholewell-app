import 'package:flutter/material.dart';

class KnowledgePlaceholderScreen extends StatelessWidget {
  const KnowledgePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Knowledge')),
      body: const Center(child: Text('Knowledge resources will be added in a later sprint.')),
    );
  }
}
