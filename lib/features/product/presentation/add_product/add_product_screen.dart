import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../repository/product_repository.dart';
import '../../provider/product_form_provider.dart';
import 'product_info_step.dart';
import 'ingredient_step.dart';
import 'product_review_step.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final int? editProductId;
  const AddProductScreen({super.key, this.editProductId});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.editProductId != null) {
      _loadProduct(widget.editProductId!);
    }
  }

  Future<void> _loadProduct(int id) async {
    final repository = ref.read(productRepositoryProvider);
    final product = await repository.fetchProduct(id);
    if (product != null) {
      ref.read(productFormProvider.notifier).loadProductWithIngredients(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);

    final steps = <Widget>[
      const ProductInfoStep(),
      const IngredientStep(),
      const ProductReviewStep(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(formState.isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          if (!formState.isEditing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => notifier.reset(),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: List.generate(3, (index) {
                final active = index <= formState.activeStep;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    decoration: BoxDecoration(
                      color: active ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        ['Product', 'Ingredients', 'Review'][index],
                        style: TextStyle(
                          color: active ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(child: steps[formState.activeStep]),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (formState.activeStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => notifier.changeStep(formState.activeStep - 1),
                      child: const Text('Back'),
                    ),
                  ),
                if (formState.activeStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formState.activeStep < steps.length - 1) {
                        notifier.changeStep(formState.activeStep + 1);
                        return;
                      }

                      await notifier.saveCurrentProduct();
                      if (mounted) {
                        notifier.reset();
                        context.pop();
                      }
                    },
                    child: Text(formState.activeStep < steps.length - 1 ? 'Next' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
