/// Đổi đơn vị trên nhãn bổ sung và thực phẩm sang khóa và đơn vị chuẩn của engine.
library;

import 'dart:math' as math;

import 'models.dart';
import 'reference_pack.dart';

enum VitaminEForm { natural, synthetic }

class IntakeLineInput {
  final String? nutrientId;
  final String? freeName;
  final IntakeSource source;
  final String form;
  final double amount;
  final LabelUnit unit;
  final CompoundKind compoundKind;

  /// Lượng axit folic (µg) đi kèm khi nhãn folate ghi `µg DFE (x µg axit folic)`.
  final double? secondaryFolicAcidUg;

  const IntakeLineInput({
    this.nutrientId,
    this.freeName,
    required this.source,
    this.form = NutrientForm.unknown,
    required this.amount,
    required this.unit,
    this.compoundKind = CompoundKind.elemental,
    this.secondaryFolicAcidUg,
  });
}

class ConvertedIntakeLine {
  final Map<String, double> amounts;
  final Map<String, double>? ulAmounts;
  final bool uncertain;
  final NotComputedReason? amountsNotComputed;

  const ConvertedIntakeLine({
    required this.amounts,
    this.ulAmounts,
    this.uncertain = false,
    this.amountsNotComputed,
  });
}

const _metricFactorToUg = <LabelUnit, double>{
  LabelUnit.g: 1000000,
  LabelUnit.mg: 1000,
  LabelUnit.ug: 1,
};

class UnitConverter {
  final ReferencePack _pack;
  final Map<String, double> _c;
  UnitConverter(ReferencePack pack)
      : _pack = pack,
        _c = pack.unitConversions;

  /// Vitamin D: IU → µg.
  double vitDIuToUg(double iu) => iu * _c['vitD_IU_to_ug']!;

  /// Vitamin A dạng retinol (có sẵn): IU → µg RAE.
  double vitARetinolIuToUgRae(double iu) => iu * _c['vitA_retinol_IU_to_ug_RAE']!;

  /// Beta-caroten trong thực phẩm bổ sung: IU → µg RAE.
  double vitABetaCaroteneSupplementIuToUgRae(double iu) =>
      iu * _c['vitA_supplemental_betacarotene_IU_to_ug_RAE']!;

  /// Vitamin E: IU → mg alpha-tocopherol cho RDA, theo dạng tự nhiên (d-) hay tổng hợp (dl-).
  double vitEIuToMg(double iu, VitaminEForm form) => iu *
      (form == VitaminEForm.natural
          ? _c['vitE_natural_IU_to_mg']!
          : _c['vitE_synthetic_IU_to_mg']!);

  /// Vitamin E: IU → mg alpha-tocopherol cho UL.
  double vitEIuToUlMg(double iu, VitaminEForm form) => iu *
      (form == VitaminEForm.natural
          ? _c['vitE_ul_natural_IU_to_mg']!
          : _c['vitE_ul_synthetic_IU_to_mg']!);

  /// Axit folic (µg) → µg DFE.
  double folicAcidToDfe(double ug) => ug * _c['folicAcid_ug_to_ug_DFE']!;

  double _toTargetUnit(double amount, LabelUnit from, String targetUnit) {
    if ((from == LabelUnit.ugDfe && targetUnit == 'ug_DFE') ||
        (from == LabelUnit.ugRae && targetUnit == 'ug_RAE') ||
        (from == LabelUnit.mgNe && targetUnit == 'mg_NE') ||
        (from == LabelUnit.mg && targetUnit == 'mg_NE') ||
        (from == LabelUnit.ug && (targetUnit == 'ug_RAE' || targetUnit == 'ug_DFE'))) {
      return amount;
    }
    final fromFactor = _metricFactorToUg[from];
    final targetFactor = switch (targetUnit) {
      'g' => 1000000.0,
      'mg' => 1000.0,
      'ug' => 1.0,
      _ => null,
    };
    if (fromFactor != null && targetFactor != null) {
      return amount * fromFactor / targetFactor;
    }
    throw ArgumentError('Không đổi được đơn vị ${from.name} sang $targetUnit');
  }

  /// Đổi một dòng nhãn thành `amounts`, `ulAmounts`, `uncertain` theo bảng quy tắc đặc tả CSDL & engine-v2.
  ConvertedIntakeLine convertIntakeLine(IntakeLineInput input) {
    if (input.amount < 0) {
      throw ArgumentError.value(input.amount, 'amount', 'Lượng chất không được âm');
    }
    if (input.secondaryFolicAcidUg != null && input.secondaryFolicAcidUg! < 0) {
      throw ArgumentError.value(
          input.secondaryFolicAcidUg, 'secondaryFolicAcidUg', 'Lượng axit folic phụ không được âm');
    }
    final nid = input.nutrientId;
    final def = nid == null ? null : _pack.nutrients[nid];
    if (nid == null || def == null) {
      return const ConvertedIntakeLine(
        amounts: {},
        amountsNotComputed: NotComputedReason.missingNutrientInPack,
      );
    }

    final form = input.form;
    final unit = input.unit;
    final amt = input.amount;

    // 1–3. Folate / Axit folic
    if (nid == 'folicAcid') {
      final ug = _toTargetUnit(amt, unit, 'ug');
      return ConvertedIntakeLine(amounts: {'folate': folicAcidToDfe(ug), 'folicAcid': ug});
    }
    if (nid == 'folate') {
      if (form == NutrientForm.folicAcid && _metricFactorToUg.containsKey(unit)) {
        final ug = _toTargetUnit(amt, unit, 'ug');
        return ConvertedIntakeLine(amounts: {'folate': folicAcidToDfe(ug), 'folicAcid': ug});
      }
      final dfe = _toTargetUnit(amt, unit, 'ug_DFE');
      if (input.secondaryFolicAcidUg != null) {
        return ConvertedIntakeLine(amounts: {'folate': dfe, 'folicAcid': input.secondaryFolicAcidUg!});
      }
      if (form == NutrientForm.naturalFolate) {
        return ConvertedIntakeLine(amounts: {'folate': dfe});
      }
      final folicEq = dfe / _c['folicAcid_ug_to_ug_DFE']!;
      return ConvertedIntakeLine(
        amounts: {'folate': dfe, 'folicAcid': folicEq},
        uncertain: form != NutrientForm.folicAcid,
      );
    }

    // 4–8. Vitamin A
    if (nid == 'vitA') {
      if (form == NutrientForm.retinol) {
        final rae = unit == LabelUnit.iu
            ? vitARetinolIuToUgRae(amt)
            : _toTargetUnit(amt, unit, 'ug_RAE');
        return ConvertedIntakeLine(amounts: {'vitA': rae, 'retinol': rae});
      }
      if (form == NutrientForm.betaCarotene) {
        if (unit != LabelUnit.iu) {
          return ConvertedIntakeLine(amounts: {'vitA': _toTargetUnit(amt, unit, 'ug_RAE')});
        }
        if (input.source == IntakeSource.supplement) {
          return ConvertedIntakeLine(amounts: {'vitA': vitABetaCaroteneSupplementIuToUgRae(amt)});
        }
        final foodFactor = _pack.foodBetaCaroteneIuToUgRae;
        if (foodFactor == null) {
          return const ConvertedIntakeLine(
            amounts: {},
            amountsNotComputed: NotComputedReason.missingFoodBetaCaroteneFactor,
          );
        }
        return ConvertedIntakeLine(amounts: {'vitA': amt * foodFactor});
      }
      // Dạng unknown
      if (unit != LabelUnit.iu) {
        final rae = _toTargetUnit(amt, unit, 'ug_RAE');
        return ConvertedIntakeLine(amounts: {'vitA': rae, 'retinol': rae}, uncertain: true);
      }
      if (input.source == IntakeSource.supplement) {
        final rae = vitARetinolIuToUgRae(amt);
        return ConvertedIntakeLine(amounts: {'vitA': rae, 'retinol': rae}, uncertain: true);
      }
      final foodFactor = _pack.foodBetaCaroteneIuToUgRae;
      final retinolUg = vitARetinolIuToUgRae(amt);
      if (foodFactor == null) {
        return ConvertedIntakeLine(
          amounts: const {},
          ulAmounts: {'retinol': retinolUg},
          uncertain: true,
          amountsNotComputed: NotComputedReason.missingFoodBetaCaroteneFactor,
        );
      }
      return ConvertedIntakeLine(
        amounts: {'vitA': amt * foodFactor},
        ulAmounts: {'retinol': retinolUg},
        uncertain: true,
      );
    }

    // 9–14. Vitamin E
    if (nid == 'vitE') {
      return _convertVitaminE(amt, unit, form);
    }

    // 17a. Vitamin D IU
    if (nid == 'vitD' && unit == LabelUnit.iu) {
      return ConvertedIntakeLine(amounts: {'vitD': vitDIuToUg(amt)});
    }

    // 15–17. Hợp chất khoáng vs nguyên tố
    final stdVal = _toTargetUnit(amt, unit, def.unit);
    if (input.compoundKind == CompoundKind.compound) {
      final ratio = _pack.compounds[nid]?[form];
      if (ratio == null) {
        return const ConvertedIntakeLine(
          amounts: {},
          amountsNotComputed: NotComputedReason.missingCompoundRatio,
        );
      }
      return ConvertedIntakeLine(amounts: {nid: stdVal * ratio});
    }
    if (input.compoundKind == CompoundKind.unknown) {
      final byNutrient = _pack.compounds[nid];
      if (byNutrient == null || byNutrient.isEmpty) {
        return ConvertedIntakeLine(
          amounts: const {},
          ulAmounts: {nid: stdVal},
          uncertain: true,
          amountsNotComputed: NotComputedReason.missingCompoundRatio,
        );
      }
      final minRatio = byNutrient.values.reduce(math.min);
      return ConvertedIntakeLine(
        amounts: {nid: stdVal * minRatio},
        ulAmounts: {nid: stdVal},
        uncertain: true,
      );
    }
    return ConvertedIntakeLine(amounts: {nid: stdVal});
  }

  ConvertedIntakeLine _convertVitaminE(double amt, LabelUnit unit, String form) {
    final esters = _pack.vitaminEEsters;
    final isEster = NutrientForm.isVitaminEEster(form) || esters.containsKey(form);
    final eRdaSyn = _c['vitE_synthetic_IU_to_mg']!;
    final eUlSyn = _c['vitE_ul_synthetic_IU_to_mg']!;

    if (unit == LabelUnit.iu) {
      bool? isNatural;
      if (form == NutrientForm.natural2r) {
        isNatural = true;
      } else if (form == NutrientForm.synthetic2r || form == NutrientForm.syntheticMass) {
        isNatural = false;
      } else if (isEster) {
        isNatural = esters[form]?.isNatural ?? NutrientForm.vitaminEEsterIsNatural(form);
      }
      if (isNatural == true) {
        final rda = vitEIuToMg(amt, VitaminEForm.natural);
        final ul = vitEIuToUlMg(amt, VitaminEForm.natural);
        return ConvertedIntakeLine(
          amounts: {'vitE': rda},
          ulAmounts: (ul - rda).abs() < 1e-12 ? null : {'vitE': ul},
        );
      }
      if (isNatural == false) {
        return ConvertedIntakeLine(
          amounts: {'vitE': vitEIuToMg(amt, VitaminEForm.synthetic)},
          ulAmounts: {'vitE': vitEIuToUlMg(amt, VitaminEForm.synthetic)},
        );
      }
      return ConvertedIntakeLine(
        amounts: {'vitE': vitEIuToMg(amt, VitaminEForm.synthetic)},
        ulAmounts: {'vitE': vitEIuToUlMg(amt, VitaminEForm.synthetic)},
        uncertain: true,
      );
    }

    final mg = _toTargetUnit(amt, unit, 'mg');
    if (isEster) {
      final esterDef = esters[form];
      if (esterDef == null) {
        return ConvertedIntakeLine(
          amounts: const {},
          ulAmounts: {'vitE': mg},
          amountsNotComputed: NotComputedReason.missingEsterRatio,
        );
      }
      final tocopherolMg = mg * esterDef.tocopherolRatio;
      if (esterDef.isNatural) {
        return ConvertedIntakeLine(amounts: {'vitE': tocopherolMg});
      }
      return ConvertedIntakeLine(
        amounts: {'vitE': tocopherolMg / eUlSyn * eRdaSyn},
        ulAmounts: {'vitE': tocopherolMg},
      );
    }
    if (form == NutrientForm.natural2r) {
      return ConvertedIntakeLine(amounts: {'vitE': mg});
    }
    if (form == NutrientForm.synthetic2r) {
      return ConvertedIntakeLine(
        amounts: {'vitE': mg},
        ulAmounts: {'vitE': mg / eRdaSyn * eUlSyn},
      );
    }
    if (form == NutrientForm.syntheticMass) {
      return ConvertedIntakeLine(
        amounts: {'vitE': mg / eUlSyn * eRdaSyn},
        ulAmounts: {'vitE': mg},
      );
    }
    return ConvertedIntakeLine(
      amounts: {'vitE': mg / eUlSyn * eRdaSyn},
      ulAmounts: {'vitE': mg / eRdaSyn * eUlSyn},
      uncertain: true,
    );
  }
}
