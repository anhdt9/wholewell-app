import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/product_form_provider.dart';
import '../../provider/product_form_state.dart';
import '../../../../core/enums/amount_accuracy_status.dart';

class ProductReviewStep extends ConsumerWidget {
  const ProductReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productFormProvider);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Review product details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _buildSection('Name', state.name),
          _buildSection('Brand', state.brand),
          _buildSection('Price', state.price?.toString() ?? 'Not provided'),
          _buildSection('Currency', state.currency),
          _buildSection('Total quantity', state.totalQuantity),
          _buildSection('Serving size', state.servingSize),
          _buildSection('Serving type', state.servingType),
          _buildSection('Note', state.note.isEmpty ? 'No note' : state.note),
          const SizedBox(height: 16),
          const Text('Ingredients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (state.ingredients.isEmpty)
            const Text('No ingredients added yet.')
          else
            ...state.ingredients.map((ingredient) => _buildIngredientReview(ingredient)).toList(),
          const SizedBox(height: 16),
          const Text('Confirm before saving. You can go back to edit details or ingredients.', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildIngredientReview(ProductIngredientFormState ingredient) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${ingredient.nutrientName}${ingredient.variantName.isNotEmpty ? ' • ${ingredient.variantName}' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            if (ingredient.elementalAmount != null) Text('Elemental: ${ingredient.elementalAmount} ${ingredient.elementalUnit}'),
            if (ingredient.compoundAmount != null) Text('Compound: ${ingredient.compoundAmount} ${ingredient.compoundUnit}'),
            Text('Accuracy: ${ingredient.amountAccuracyStatus.label}'),
            if (ingredient.note.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('Note: ${ingredient.note}', style: const TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }
}
