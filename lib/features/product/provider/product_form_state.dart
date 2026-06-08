import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/enums/amount_accuracy_status.dart';

part 'product_form_state.freezed.dart';

@freezed
abstract class ProductIngredientFormState with _$ProductIngredientFormState {
  const factory ProductIngredientFormState({
    int? id,
    @Default('') String nutrientKey,
    @Default('') String nutrientName,
    @Default('') String variantKey,
    @Default('') String variantName,
    double? compoundAmount,
    @Default('') String compoundUnit,
    double? elementalAmount,
    @Default('') String elementalUnit,
    @Default(AmountAccuracyStatus.unknown) AmountAccuracyStatus amountAccuracyStatus,
    @Default('') String note,
    @Default('') String sourceText,
    @Default(0) int confidence,
  }) = _ProductIngredientFormState;
}

@freezed
abstract class ProductFormState with _$ProductFormState {
  const factory ProductFormState({
    int? productId,
    @Default('') String name,
    @Default('') String brand,
    double? price,
    @Default('VND') String currency,
    @Default('0') String totalQuantity,
    @Default('0') String servingSize,
    @Default('capsule') String servingType,
    @Default('') String note,
    @Default(<ProductIngredientFormState>[]) List<ProductIngredientFormState> ingredients,
    @Default(0) int activeStep,
    @Default(false) bool isEditing,
  }) = _ProductFormState;
}
