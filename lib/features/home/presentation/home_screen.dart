import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to WholeWell', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            Text('Manage supplement products, ingredients, and household nutrition in future sprints.'),
          ],
        ),
      ),
    );
  }
}
