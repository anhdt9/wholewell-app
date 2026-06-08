import 'package:flutter/material.dart';
import '../../../../data/local/app_database.dart';
import '../../../../core/enums/amount_accuracy_status.dart';

class IngredientTile extends StatelessWidget {
  final ProductIngredient ingredient;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const IngredientTile({super.key, required this.ingredient, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final accuracy = AmountAccuracyStatus.fromString(ingredient.amountAccuracyStatus);
    final warning = accuracy == AmountAccuracyStatus.compoundOnly || accuracy == AmountAccuracyStatus.unknown;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${ingredient.nutrientName}${ingredient.variantName?.isNotEmpty == true ? ' • ${ingredient.variantName}' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Row(
                  children: [
                    if (onEdit != null)
                      IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                    if (onDelete != null)
                      IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (ingredient.elementalAmount != null)
              Text('Elemental: ${ingredient.elementalAmount} ${ingredient.elementalUnit ?? ''}'),
            if (ingredient.compoundAmount != null)
              Text('Compound: ${ingredient.compoundAmount} ${ingredient.compoundUnit ?? ''}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(accuracy.shortLabel)),
                if (warning)
                  const Chip(
                    label: Text('Needs verification'),
                    backgroundColor: Colors.orangeAccent,
                  ),
              ],
            ),
            if (warning)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Compound amount only. Elemental/active amount is missing and will not be used for daily nutrient calculations.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
