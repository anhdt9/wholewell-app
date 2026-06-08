import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/enums/amount_accuracy_status.dart';
import '../provider/product_list_provider.dart';
import 'widgets/product_card.dart';
import '../../../app/route_paths.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListWithDetailsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products yet. Tap + to add your first supplement.'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];
              final warning = item.ingredients.any((ingredient) {
                final status = AmountAccuracyStatus.fromString(ingredient.amountAccuracyStatus);
                return status == AmountAccuracyStatus.compoundOnly || status == AmountAccuracyStatus.unknown;
              });
              return ProductCard(
                product: item.product,
                ingredientCount: item.ingredients.length,
                hasWarnings: warning,
                onTap: () => context.go('/products/${item.product.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Unable to load products: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go(RoutePaths.addProduct),
        child: const Icon(Icons.add),
      ),
    );
  }
}
