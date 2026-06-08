import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../provider/product_detail_provider.dart';
import '../repository/product_repository.dart';
import 'widgets/ingredient_tile.dart';
import '../../../app/route_paths.dart';
import '../../../core/enums/amount_accuracy_status.dart';
import '../../../data/local/daos/product_dao.dart';
import '../../../data/local/app_database.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int? productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (productId == null) {
      return const Scaffold(body: Center(child: Text('Product not found.')));
    }
    final productAsync = ref.watch(productDetailProvider(productId!));
    return productAsync.when(
      data: (productWithIngredients) {
        if (productWithIngredients == null) {
          return const Scaffold(body: Center(child: Text('Product not found.')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(productWithIngredients.product.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('${RoutePaths.addProduct}?editId=${productId!}'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref, productId!),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSection('Product Info', [
                _infoItem('Brand', productWithIngredients.product.brand ?? 'Not provided'),
                _infoItem('Price', productWithIngredients.product.price != null ? '${productWithIngredients.product.price} ${productWithIngredients.product.currency}' : 'Not provided'),
                _infoItem('Total quantity', productWithIngredients.product.totalQuantity.toString()),
                _infoItem('Serving', '${productWithIngredients.product.servingSize} ${productWithIngredients.product.servingType ?? ''}'),
                if (productWithIngredients.product.note != null && productWithIngredients.product.note!.isNotEmpty)
                  _infoItem('Note', productWithIngredients.product.note!),
              ]),
              const SizedBox(height: 16),
              _buildSection('Ingredients', [
                const SizedBox.shrink(),
              ]),
              ...productWithIngredients.ingredients.map(
                (ingredient) => IngredientTile(
                  ingredient: ingredient,
                  onEdit: () {},
                  onDelete: () => _deleteIngredient(context, ref, ingredient.id),
                ),
              ),
              const SizedBox(height: 16),
              _buildSection('Data Quality', [
                _qualityWarnings(productWithIngredients),
              ]),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error loading product: $error'))),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _qualityWarnings(ProductWithIngredients productWithIngredients) {
    final warnings = productWithIngredients.ingredients.where((ingredient) {
      final status = AmountAccuracyStatus.fromString(ingredient.amountAccuracyStatus);
      return status == AmountAccuracyStatus.compoundOnly || status == AmountAccuracyStatus.unknown;
    }).toList();

    if (warnings.isEmpty) {
      return const Text('All ingredient accuracy statuses are confirmed or estimated.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: warnings.map((ingredient) {
        final status = AmountAccuracyStatus.fromString(ingredient.amountAccuracyStatus);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            '- ${ingredient.nutrientName} ${ingredient.variantName ?? ''} (${status.label})',
            style: const TextStyle(color: Colors.orange),
          ),
        );
      }).toList(),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int productId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text('Are you sure you want to delete this product and its ingredients?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(productRepositoryProvider).deleteProduct(productId);
              if (context.mounted) {
                Navigator.of(context).pop();
                context.go(RoutePaths.products);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteIngredient(BuildContext context, WidgetRef ref, int ingredientId) async {
    await ref.read(productRepositoryProvider).deleteIngredient(ingredientId);
  }
}
