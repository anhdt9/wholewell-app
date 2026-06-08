import 'package:flutter_riverpod/legacy.dart';
import 'package:drift/drift.dart';
import '../../../core/enums/amount_accuracy_status.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/product_dao.dart';
import '../repository/product_repository.dart';
import 'product_form_state.dart';

final productFormProvider = StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductFormNotifier(repository);
});

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final ProductRepository repository;

  ProductFormNotifier(this.repository) : super(const ProductFormState());

  void updateProductInfo({
    String? name,
    String? brand,
    double? price,
    String? currency,
    String? totalQuantity,
    String? servingSize,
    String? servingType,
    String? note,
  }) {
    state = state.copyWith(
      name: name ?? state.name,
      brand: brand ?? state.brand,
      price: price ?? state.price,
      currency: currency ?? state.currency,
      totalQuantity: totalQuantity ?? state.totalQuantity,
      servingSize: servingSize ?? state.servingSize,
      servingType: servingType ?? state.servingType,
      note: note ?? state.note,
    );
  }

  void changeStep(int step) {
    state = state.copyWith(activeStep: step);
  }

  void addIngredient(ProductIngredientFormState ingredient) {
    final ingredients = [...state.ingredients, ingredient];
    state = state.copyWith(ingredients: ingredients);
  }

  void updateIngredient(int index, ProductIngredientFormState ingredient) {
    final ingredients = [...state.ingredients];
    if (index >= 0 && index < ingredients.length) {
      ingredients[index] = ingredient;
      state = state.copyWith(ingredients: ingredients);
    }
  }

  void removeIngredient(int index) {
    final ingredients = [...state.ingredients];
    if (index >= 0 && index < ingredients.length) {
      ingredients.removeAt(index);
      state = state.copyWith(ingredients: ingredients);
    }
  }

  void reset() {
    state = const ProductFormState();
  }

  void loadProductWithIngredients(ProductWithIngredients productWithIngredients) {
    final formIngredients = productWithIngredients.ingredients.map((ingredient) {
      return ProductIngredientFormState(
        id: ingredient.id,
        nutrientKey: ingredient.nutrientKey,
        nutrientName: ingredient.nutrientName,
        variantKey: ingredient.variantKey ?? '',
        variantName: ingredient.variantName ?? '',
        compoundAmount: ingredient.compoundAmount,
        compoundUnit: ingredient.compoundUnit ?? '',
        elementalAmount: ingredient.elementalAmount,
        elementalUnit: ingredient.elementalUnit ?? '',
        amountAccuracyStatus: AmountAccuracyStatus.fromString(ingredient.amountAccuracyStatus),
        note: ingredient.note ?? '',
        sourceText: ingredient.sourceText ?? '',
        confidence: ingredient.confidence,
      );
    }).toList();

    state = state.copyWith(
      productId: productWithIngredients.product.id,
      name: productWithIngredients.product.name,
      brand: productWithIngredients.product.brand ?? '',
      price: productWithIngredients.product.price,
      currency: productWithIngredients.product.currency,
      totalQuantity: productWithIngredients.product.totalQuantity.toString(),
      servingSize: productWithIngredients.product.servingSize.toString(),
      servingType: productWithIngredients.product.servingType ?? 'capsule',
      note: productWithIngredients.product.note ?? '',
      ingredients: formIngredients,
      isEditing: true,
    );
  }

  Future<void> saveCurrentProduct() async {
    final product = ProductsCompanion(
      name: Value(state.name.trim()),
      brand: Value(state.brand.trim()),
      price: Value(state.price),
      currency: Value(state.currency.trim()),
      totalQuantity: Value(int.tryParse(state.totalQuantity) ?? 0),
      servingSize: Value(double.tryParse(state.servingSize) ?? 0),
      servingType: Value(state.servingType.trim()),
      note: Value(state.note.trim()),
      updatedAt: Value(DateTime.now()),
    );
    final ingredientCompanions = state.ingredients.map((ingredient) {
      return ProductIngredientsCompanion(
        productId: state.productId == null ? const Value.absent() : Value(state.productId!),
        nutrientKey: Value(ingredient.nutrientKey.trim()),
        nutrientName: Value(ingredient.nutrientName.trim()),
        variantKey: Value(ingredient.variantKey.trim()),
        variantName: Value(ingredient.variantName.trim()),
        compoundAmount: Value(ingredient.compoundAmount),
        compoundUnit: Value(ingredient.compoundUnit.trim()),
        elementalAmount: Value(ingredient.elementalAmount),
        elementalUnit: Value(ingredient.elementalUnit.trim()),
        amountAccuracyStatus: Value(ingredient.amountAccuracyStatus.name),
        sourceText: Value(ingredient.sourceText.trim()),
        confidence: Value(ingredient.confidence),
        note: Value(ingredient.note.trim()),
        updatedAt: Value(DateTime.now()),
      );
    }).toList();

    if (state.isEditing && state.productId != null) {
      final currentProduct = await repository.fetchProduct(state.productId!);
      if (currentProduct == null) return;
      final updatedProduct = currentProduct.product.copyWith(
        name: state.name.trim(),
        brand: state.brand.trim().isEmpty ? const Value(null) : Value(state.brand.trim()),
        price: Value(state.price),
        currency: state.currency.trim(),
        totalQuantity: int.tryParse(state.totalQuantity) ?? 0,
        servingSize: double.tryParse(state.servingSize) ?? 0,
        servingType: state.servingType.trim().isEmpty ? const Value(null) : Value(state.servingType.trim()),
        note: state.note.trim().isEmpty ? const Value(null) : Value(state.note.trim()),
        updatedAt: DateTime.now(),
      );
      final ingredients = state.ingredients.map((ingredient) {
        return ProductIngredient(
          id: ingredient.id ?? 0,
          productId: updatedProduct.id,
          nutrientKey: ingredient.nutrientKey.trim(),
          nutrientName: ingredient.nutrientName.trim(),
          variantKey: ingredient.variantKey.trim().isEmpty ? null : ingredient.variantKey.trim(),
          variantName: ingredient.variantName.trim().isEmpty ? null : ingredient.variantName.trim(),
          compoundAmount: ingredient.compoundAmount,
          compoundUnit: ingredient.compoundUnit.trim().isEmpty ? null : ingredient.compoundUnit.trim(),
          elementalAmount: ingredient.elementalAmount,
          elementalUnit: ingredient.elementalUnit.trim().isEmpty ? null : ingredient.elementalUnit.trim(),
          amountAccuracyStatus: ingredient.amountAccuracyStatus.name,
          sourceText: ingredient.sourceText.trim().isEmpty ? null : ingredient.sourceText.trim(),
          confidence: ingredient.confidence,
          note: ingredient.note.trim().isEmpty ? null : ingredient.note.trim(),
          createdAt: currentProduct.ingredients.any((element) => element.id == ingredient.id) ? currentProduct.ingredients.firstWhere((element) => element.id == ingredient.id).createdAt : DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();

      await repository.updateProductWithIngredients(updatedProduct, ingredients);
      return;
    }

    await repository.saveProductWithIngredients(product, ingredientCompanions);
  }
}
