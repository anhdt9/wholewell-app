/// Helper chuyển đổi và kiểm tra hợp lý thành phần bổ sung (tách logic `UnitConverter` khỏi UI).
library;

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

class SupplementIngredientHelper {
  SupplementIngredientHelper._();

  static const _fallbackProfile = Profile(
    ageYears: 30,
    sex: Sex.male,
    heightCm: 170,
    weightKg: 65,
    activityLevel: ActivityLevel.inactive,
  );

  static CompoundKind _compoundKind(bool isCompound, String form) => isCompound
      ? (form == NutrientForm.unknown ? CompoundKind.unknown : CompoundKind.compound)
      : CompoundKind.elemental;

  static IntakeLineInput _buildInput({
    required String? nutrientId,
    required String form,
    required double amount,
    required LabelUnit unit,
    required bool isCompound,
  }) => IntakeLineInput(
    nutrientId: nutrientId,
    source: IntakeSource.supplement,
    form: form,
    amount: amount,
    unit: unit,
    compoundKind: _compoundKind(isCompound, form),
  );

  static bool isUnitCompatible(
    ReferencePack pack, {
    required String? nutrientId,
    required String form,
    required double? amount,
    required LabelUnit unit,
    required bool isCompound,
  }) {
    if (nutrientId == null || amount == null || amount <= 0) return true;
    try {
      UnitConverter(pack).convertIntakeLine(
        _buildInput(nutrientId: nutrientId, form: form, amount: amount, unit: unit, isCompound: isCompound),
      );
      return true;
    } on ArgumentError {
      return false;
    }
  }

  static ConvertedIntakeLine convertLine(
    ReferencePack pack, {
    required String? nutrientId,
    required String form,
    required double amount,
    required LabelUnit unit,
    required bool isCompound,
  }) => UnitConverter(pack).convertIntakeLine(
    _buildInput(nutrientId: nutrientId, form: form, amount: amount, unit: unit, isCompound: isCompound),
  );

  static ({IngredientSanityResult sanity, bool unitIncompatible}) checkSanity(
    ReferencePack pack, {
    required Profile? profile,
    required String? nutrientId,
    required String form,
    required double? amount,
    required LabelUnit? unit,
    required bool isCompound,
  }) {
    // Đơn vị trống: màn xác nhận đã hiện lời nhắc "Chưa rõ đơn vị", không kiểm thêm.
    if (nutrientId == null || amount == null || amount <= 0 || unit == null) {
      return (
        sanity: const IngredientSanityResult(suspectedUnitMistake: false, exceedsSingleServingUl: false),
        unitIncompatible: false,
      );
    }
    try {
      final res = UnitConverter(pack).checkIngredientSanity(
        profile ?? _fallbackProfile,
        _buildInput(nutrientId: nutrientId, form: form, amount: amount, unit: unit, isCompound: isCompound),
      );
      return (sanity: res, unitIncompatible: false);
    } on ArgumentError {
      return (
        sanity: const IngredientSanityResult(suspectedUnitMistake: false, exceedsSingleServingUl: false),
        unitIncompatible: true,
      );
    }
  }

  static IngredientDraft toDraft(
    ReferencePack pack, {
    required String? nutrientId,
    required String? freeName,
    required String form,
    required double? labelAmount,
    required LabelUnit labelUnit,
    required bool isCompound,
    required IngredientOrigin origin,
    required bool confirmed,
  }) {
    if (nutrientId == null || labelAmount == null) {
      return IngredientDraft(
        freeName: freeName,
        form: form,
        labelAmount: labelAmount,
        labelUnit: labelUnit.name,
        isCompound: false,
        origin: origin,
        confirmed: confirmed,
      );
    }
    try {
      final converted = convertLine(
        pack,
        nutrientId: nutrientId,
        form: form,
        amount: labelAmount,
        unit: labelUnit,
        isCompound: isCompound,
      );
      final def = pack.nutrients[nutrientId];
      final stdAmount = converted.amounts[nutrientId] ?? converted.amounts.values.firstOrNull;
      return IngredientDraft(
        nutrientId: nutrientId,
        form: form,
        amountPerServing: stdAmount,
        unit: def?.unit,
        labelAmount: labelAmount,
        labelUnit: labelUnit.name,
        isCompound: isCompound,
        origin: origin,
        confirmed: confirmed,
      );
    } on ArgumentError {
      return IngredientDraft(
        nutrientId: nutrientId,
        form: form,
        labelAmount: labelAmount,
        labelUnit: labelUnit.name,
        isCompound: isCompound,
        origin: origin,
        confirmed: false,
      );
    }
  }

  /// Đơn vị nhãn tương ứng đơn vị chuẩn của chất trong gói; `null` khi không có (vd. `L`).
  /// Không có giá trị mặc định: chất trả `null` không được nhập theo đơn vị chuẩn.
  static LabelUnit? labelUnitForPackUnit(String packUnit) => switch (packUnit) {
    'g' => LabelUnit.g,
    'mg' => LabelUnit.mg,
    'ug' => LabelUnit.ug,
    'ug_RAE' => LabelUnit.ugRae,
    'ug_DFE' => LabelUnit.ugDfe,
    'mg_NE' => LabelUnit.mgNe,
    _ => null,
  };

  static IntakeLine? toOneOffIntakeLine(
    ReferencePack pack, {
    required String nutrientId,
    required String form,
    required double amount,
    required LabelUnit unit,
  }) {
    final converted = convertLine(
      pack,
      nutrientId: nutrientId,
      form: form,
      amount: amount,
      unit: unit,
      isCompound: false,
    );
    if (converted.amounts.isEmpty) return null;
    return IntakeLine(
      nutrientId: nutrientId,
      source: IntakeSource.supplement,
      form: form,
      uncertain: converted.uncertain,
      labelAmount: amount,
      labelUnit: unit.name,
      amounts: converted.amounts,
      ulAmounts: converted.ulAmounts,
    );
  }
}
