import 'package:flutter/material.dart';
import '../../../../data/local/app_database.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int ingredientCount;
  final bool hasWarnings;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.ingredientCount, required this.hasWarnings, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        onTap: onTap,
        title: Text(product.name),
        subtitle: Text(product.brand ?? 'No brand provided'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$ingredientCount ingredient${ingredientCount == 1 ? '' : 's'}'),
            if (hasWarnings)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Data quality issue', style: TextStyle(fontSize: 12, color: Colors.orange)),
              ),
          ],
        ),
      ),
    );
  }
}
