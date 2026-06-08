import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/product_form_provider.dart';

class ProductInfoStep extends ConsumerWidget {
  const ProductInfoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productFormProvider);
    final notifier = ref.read(productFormProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            initialValue: state.name,
            decoration: const InputDecoration(labelText: 'Product name'),
            onChanged: (value) => notifier.updateProductInfo(name: value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: state.brand,
            decoration: const InputDecoration(labelText: 'Brand'),
            onChanged: (value) => notifier.updateProductInfo(brand: value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: state.price?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price'),
                  onChanged: (value) => notifier.updateProductInfo(price: double.tryParse(value)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: state.currency,
                  items: const [
                    DropdownMenuItem(value: 'VND', child: Text('VND')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  decoration: const InputDecoration(labelText: 'Currency'),
                  onChanged: (value) {
                    if (value != null) {
                      notifier.updateProductInfo(currency: value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: state.totalQuantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total quantity'),
                  onChanged: (value) => notifier.updateProductInfo(totalQuantity: value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: state.servingSize,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Serving size'),
                  onChanged: (value) => notifier.updateProductInfo(servingSize: value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: state.servingType,
            decoration: const InputDecoration(labelText: 'Serving type'),
            onChanged: (value) => notifier.updateProductInfo(servingType: value),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: state.note,
            decoration: const InputDecoration(labelText: 'Note'),
            minLines: 2,
            maxLines: 4,
            onChanged: (value) => notifier.updateProductInfo(note: value),
          ),
        ],
      ),
    );
  }
}
