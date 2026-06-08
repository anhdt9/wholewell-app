import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/product_form_provider.dart';
import '../../provider/product_form_state.dart';
import '../../../../core/enums/amount_accuracy_status.dart';

class IngredientStep extends ConsumerWidget {
  const IngredientStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              FilledButton.icon(
                onPressed: () => _showIngredientDialog(context, notifier),
                icon: const Icon(Icons.add),
                label: const Text('Add ingredient'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.ingredients.isEmpty)
            const Expanded(child: Center(child: Text('No ingredients added yet.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: state.ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = state.ingredients[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text('${ingredient.nutrientName} ${ingredient.variantName.isNotEmpty ? '• ${ingredient.variantName}' : ''}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ingredient.elementalAmount != null) Text('Elemental: ${ingredient.elementalAmount} ${ingredient.elementalUnit}'),
                          if (ingredient.compoundAmount != null) Text('Compound: ${ingredient.compoundAmount} ${ingredient.compoundUnit}'),
                          Text('Accuracy: ${ingredient.amountAccuracyStatus.shortLabel}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showIngredientDialog(context, notifier, ingredient: ingredient, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => notifier.removeIngredient(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showIngredientDialog(BuildContext context, ProductFormNotifier notifier,
      {ProductIngredientFormState? ingredient, int? index}) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return _IngredientFormDialog(
          initialIngredient: ingredient,
          onSave: (value) {
            if (index == null) {
              notifier.addIngredient(value);
            } else {
              notifier.updateIngredient(index, value);
            }
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _IngredientFormDialog extends StatefulWidget {
  final ProductIngredientFormState? initialIngredient;
  final ValueChanged<ProductIngredientFormState> onSave;

  const _IngredientFormDialog({this.initialIngredient, required this.onSave});

  @override
  State<_IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<_IngredientFormDialog> {
  late final TextEditingController _nutrientNameController = TextEditingController(text: widget.initialIngredient?.nutrientName ?? '');
  late final TextEditingController _nutrientKeyController = TextEditingController(text: widget.initialIngredient?.nutrientKey ?? '');
  late final TextEditingController _variantNameController = TextEditingController(text: widget.initialIngredient?.variantName ?? '');
  late final TextEditingController _variantKeyController = TextEditingController(text: widget.initialIngredient?.variantKey ?? '');
  late final TextEditingController _compoundAmountController = TextEditingController(text: widget.initialIngredient?.compoundAmount?.toString() ?? '');
  late final TextEditingController _compoundUnitController = TextEditingController(text: widget.initialIngredient?.compoundUnit ?? '');
  late final TextEditingController _elementalAmountController = TextEditingController(text: widget.initialIngredient?.elementalAmount?.toString() ?? '');
  late final TextEditingController _elementalUnitController = TextEditingController(text: widget.initialIngredient?.elementalUnit ?? '');
  late AmountAccuracyStatus _selectedAccuracy = widget.initialIngredient?.amountAccuracyStatus ?? AmountAccuracyStatus.unknown;
  late final TextEditingController _noteController = TextEditingController(text: widget.initialIngredient?.note ?? '');

  @override
  void dispose() {
    _nutrientNameController.dispose();
    _nutrientKeyController.dispose();
    _variantNameController.dispose();
    _variantKeyController.dispose();
    _compoundAmountController.dispose();
    _compoundUnitController.dispose();
    _elementalAmountController.dispose();
    _elementalUnitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialIngredient == null ? 'Add Ingredient' : 'Edit Ingredient'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _nutrientNameController,
              decoration: const InputDecoration(labelText: 'Nutrient name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nutrientKeyController,
              decoration: const InputDecoration(labelText: 'Nutrient key'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _variantNameController,
              decoration: const InputDecoration(labelText: 'Variant name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _variantKeyController,
              decoration: const InputDecoration(labelText: 'Variant key'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _compoundAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Compound amount'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _compoundUnitController,
              decoration: const InputDecoration(labelText: 'Compound unit'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _elementalAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Elemental amount'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _elementalUnitController,
              decoration: const InputDecoration(labelText: 'Elemental unit'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AmountAccuracyStatus>(
              value: _selectedAccuracy,
              items: AmountAccuracyStatus.values
                  .map((status) => DropdownMenuItem(value: status, child: Text(status.label)))
                  .toList(),
              decoration: const InputDecoration(labelText: 'Accuracy status'),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedAccuracy = value;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note'),
              minLines: 2,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final newIngredient = ProductIngredientFormState(
              id: widget.initialIngredient?.id,
              nutrientKey: _nutrientKeyController.text.trim(),
              nutrientName: _nutrientNameController.text.trim(),
              variantKey: _variantKeyController.text.trim(),
              variantName: _variantNameController.text.trim(),
              compoundAmount: double.tryParse(_compoundAmountController.text),
              compoundUnit: _compoundUnitController.text.trim(),
              elementalAmount: double.tryParse(_elementalAmountController.text),
              elementalUnit: _elementalUnitController.text.trim(),
              amountAccuracyStatus: _selectedAccuracy,
              note: _noteController.text.trim(),
            );
            widget.onSave(newIngredient);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
