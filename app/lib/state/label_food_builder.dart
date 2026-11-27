/// Dựng dữ liệu món "Nhập theo nhãn", kiểm hợp lý đơn vị và lưu `custom_foods`.
library;

import 'dart:math' as math;

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

/// Cách người dùng chọn nhập Folate / Axit folic trên nhãn bao bì.
enum LabelFolateMode {
  /// Nhãn ghi riêng `Axit folic` (µg).
  folicAcidOnly,

  /// Nhãn ghi `Folate tổng (µg đã quy đổi)` kèm `(x µg axit folic)`.
  folateWithFolicAcid,

  /// Nhãn ghi `Folate` không tách riêng, dùng đơn vị + nguồn người dùng chọn.
  folateGeneral,
}

/// Một dòng vi chất người dùng thêm trên màn Nhập theo nhãn.
class LabelMicroEntry {
  final String nutrientId;
  final double labelAmount;
  final LabelUnit unit;
  final String form;
  final LabelFolateMode? folateMode;

  /// Dùng khi [folateMode] == [LabelFolateMode.folateWithFolicAcid].
  final double? secondaryFolicAcidUg;

  const LabelMicroEntry({
    required this.nutrientId,
    required this.labelAmount,
    required this.unit,
    this.form = NutrientForm.unknown,
    this.folateMode,
    this.secondaryFolicAcidUg,
  });
}

/// Cảnh báo nghi sai đơn vị (> 100% giới hạn an toàn hoặc > 10x mức khuyến nghị/ước tính).
class UnitPlausibilityWarning {
  final String nutrientId;
  final String nutrientNameVi;
  final double displayAmount;
  final String displayUnit;

  const UnitPlausibilityWarning({
    required this.nutrientId,
    required this.nutrientNameVi,
    required this.displayAmount,
    required this.displayUnit,
  });
}

/// Dữ liệu thô trên màn Nhập theo nhãn cho một khẩu phần đã dùng.
class LabelFoodDraft {
  final String name;
  final Meal meal;
  final DateTime at;
  final double labelBasisQty;
  final String labelBasisUnit;
  final double usedQty;

  final double? energyKcal;
  final double? proteinG;
  final double? fatG;
  final double? carbG;
  final double? totalSugarG;

  /// `null` nghĩa là bỏ trống ("chưa rõ đường bổ sung"); `0.0` nghĩa là nhãn ghi 0 g.
  final double? addedSugarG;
  final double? sodiumMg;
  final List<LabelMicroEntry> micros;

  const LabelFoodDraft({
    required this.name,
    required this.meal,
    required this.at,
    required this.labelBasisQty,
    required this.labelBasisUnit,
    required this.usedQty,
    this.energyKcal,
    this.proteinG,
    this.fatG,
    this.carbG,
    this.totalSugarG,
    this.addedSugarG,
    this.sodiumMg,
    this.micros = const [],
  });

  double get scale => usedQty / labelBasisQty;
}

class BuiltLabelFood {
  final FoodEntryInput entryInput;
  final CustomFoodInput customFoodInput;
  final List<UnitPlausibilityWarning> warnings;

  const BuiltLabelFood({
    required this.entryInput,
    required this.customFoodInput,
    required this.warnings,
  });
}

class LabelFoodBuilder {
  LabelFoodBuilder._();

  static const _macroLabels = <(String id, double? Function(LabelFoodDraft d) get, String unit)>[
    ('energyKcal', _getEnergy, 'kcal'),
    ('protein', _getProtein, 'g'),
    ('fat', _getFat, 'g'),
    ('carbohydrate', _getCarb, 'g'),
    ('sodium', _getSodium, 'mg'),
  ];

  static double? _getEnergy(LabelFoodDraft d) => d.energyKcal;
  static double? _getProtein(LabelFoodDraft d) => d.proteinG;
  static double? _getFat(LabelFoodDraft d) => d.fatG;
  static double? _getCarb(LabelFoodDraft d) => d.carbG;
  static double? _getSodium(LabelFoodDraft d) => d.sodiumMg;

  static IntakeSource sourceForLabelMicro(LabelMicroEntry m) {
    if (m.nutrientId == 'niacin' || m.nutrientId == 'vitE' || m.nutrientId == 'folicAcid') {
      return IntakeSource.fortified;
    }
    if (m.nutrientId == 'folate') {
      if (m.folateMode == LabelFolateMode.folicAcidOnly || m.form == NutrientForm.folicAcid) {
        return IntakeSource.fortified;
      }
      if (m.folateMode == LabelFolateMode.folateWithFolicAcid) {
        return IntakeSource.food;
      }
    }
    return IntakeSource.food;
  }

  static String unitWireName(LabelUnit u) => switch (u) {
        LabelUnit.g => 'g',
        LabelUnit.mg => 'mg',
        LabelUnit.ug => 'ug',
        LabelUnit.iu => 'iu',
        LabelUnit.ugRae => 'ug_RAE',
        LabelUnit.ugDfe => 'ug_DFE',
        LabelUnit.mgNe => 'mg_NE',
      };

  static LabelUnit unitFromWire(String s) => switch (s) {
        'g' => LabelUnit.g,
        'mg' => LabelUnit.mg,
        'ug' => LabelUnit.ug,
        'iu' => LabelUnit.iu,
        'ug_RAE' || 'ugRae' => LabelUnit.ugRae,
        'ug_DFE' || 'ugDfe' => LabelUnit.ugDfe,
        'mg_NE' || 'mgNe' => LabelUnit.mgNe,
        _ => LabelUnit.mg,
      };

  static BuiltLabelFood build(
    LabelFoodDraft draft, {
    required ReferencePack pack,
    Profile? profile,
    String? customFoodRef,
  }) {
    if (draft.labelBasisQty <= 0) {
      throw ArgumentError.value(draft.labelBasisQty, 'labelBasisQty', 'Phải > 0');
    }
    if (draft.usedQty <= 0) {
      throw ArgumentError.value(draft.usedQty, 'usedQty', 'Phải > 0');
    }
    final scale = draft.scale;
    final intakeLines = <IntakeLine>[];
    final customLines = <CustomFoodLine>[];
    final converter = UnitConverter(pack);

    for (final (id, getter, unit) in _macroLabels) {
      final raw = getter(draft);
      if (raw == null || raw <= 0) continue;
      intakeLines.add(IntakeLine(
        nutrientId: id,
        source: IntakeSource.food,
        labelAmount: raw,
        labelUnit: unit,
        amounts: {id: raw * scale},
      ));
      customLines.add(CustomFoodLine(
        nutrientId: id,
        labelAmount: raw,
        labelUnit: unit,
        source: IntakeSource.food,
      ));
    }

    // Đường tổng chỉ lưu vào custom_food_lines nếu cần, hoặc không đưa vào engine;
    // để khớp quy ước custom_food_lines cũng giữ lại tổng đường trên nhãn nếu > 0.
    if (draft.totalSugarG != null && draft.totalSugarG! > 0) {
      customLines.add(CustomFoodLine(
        nutrientId: 'totalSugar',
        labelAmount: draft.totalSugarG!,
        labelUnit: 'g',
        source: IntakeSource.food,
      ));
    }

    // Quy tắc Đường bổ sung: nhập 0 => ghi 0 (addedSugarKnown = true); bỏ trống => không ghi (false).
    final addedSugar = draft.addedSugarG;
    final addedSugarKnown = addedSugar != null;
    if (addedSugar != null) {
      intakeLines.add(IntakeLine(
        nutrientId: 'addedSugar',
        source: IntakeSource.food,
        labelAmount: addedSugar,
        labelUnit: 'g',
        amounts: {'addedSugar': addedSugar * scale},
      ));
      customLines.add(CustomFoodLine(
        nutrientId: 'addedSugar',
        labelAmount: addedSugar,
        labelUnit: 'g',
        source: IntakeSource.food,
      ));
    }

    final dfeFactor = pack.unitConversions['folicAcid_ug_to_ug_DFE'] ?? 1.7;

    for (final m in draft.micros) {
      if (m.labelAmount <= 0) continue;

      if (m.nutrientId == 'folate' &&
          m.folateMode == LabelFolateMode.folateWithFolicAcid &&
          m.secondaryFolicAcidUg != null) {
        final totalDfe = m.labelAmount;
        final folicUg = m.secondaryFolicAcidUg!;
        final naturalDfe = math.max(0.0, totalDfe - folicUg * dfeFactor);

        if (folicUg > 0) {
          intakeLines.add(IntakeLine(
            nutrientId: 'folicAcid',
            source: IntakeSource.fortified,
            form: NutrientForm.folicAcid,
            labelAmount: folicUg,
            labelUnit: 'ug',
            amounts: {
              'folicAcid': folicUg * scale,
              'folate': folicUg * dfeFactor * scale,
            },
          ));
          customLines.add(CustomFoodLine(
            nutrientId: 'folicAcid',
            form: NutrientForm.folicAcid,
            labelAmount: folicUg,
            labelUnit: 'ug',
            source: IntakeSource.fortified,
          ));
        }
        if (naturalDfe > 0 || folicUg <= 0) {
          intakeLines.add(IntakeLine(
            nutrientId: 'folate',
            source: IntakeSource.food,
            form: NutrientForm.naturalFolate,
            labelAmount: naturalDfe,
            labelUnit: 'ug_DFE',
            amounts: {'folate': naturalDfe * scale},
          ));
          customLines.add(CustomFoodLine(
            nutrientId: 'folate',
            form: NutrientForm.naturalFolate,
            labelAmount: naturalDfe,
            labelUnit: 'ug_DFE',
            source: IntakeSource.food,
          ));
        }
        continue;
      }

      final src = sourceForLabelMicro(m);
      final conv = converter.convertIntakeLine(IntakeLineInput(
        nutrientId: m.nutrientId,
        source: src,
        form: m.form,
        amount: m.labelAmount,
        unit: m.unit,
        compoundKind: CompoundKind.elemental,
        secondaryFolicAcidUg: m.secondaryFolicAcidUg,
      ));
      if (conv.amounts.isNotEmpty || (conv.ulAmounts != null && conv.ulAmounts!.isNotEmpty)) {
        intakeLines.add(IntakeLine(
          nutrientId: m.nutrientId,
          source: src,
          form: m.form,
          uncertain: conv.uncertain,
          labelAmount: m.labelAmount,
          labelUnit: unitWireName(m.unit),
          amounts: {for (final e in conv.amounts.entries) e.key: e.value * scale},
          ulAmounts: conv.ulAmounts == null
              ? null
              : {for (final e in conv.ulAmounts!.entries) e.key: e.value * scale},
        ));
      }
      customLines.add(CustomFoodLine(
        nutrientId: m.nutrientId,
        form: m.form,
        labelAmount: m.labelAmount,
        labelUnit: unitWireName(m.unit),
        source: src,
      ));
    }

    final warnings = checkPlausibility(intakeLines, pack: pack, profile: profile);

    return BuiltLabelFood(
      entryInput: FoodEntryInput(
        at: draft.at,
        meal: draft.meal,
        name: draft.name.trim(),
        foodRef: customFoodRef,
        portionUnit: draft.labelBasisUnit,
        portionQty: draft.usedQty,
        labelBasisQty: draft.labelBasisQty,
        labelBasisUnit: draft.labelBasisUnit,
        addedSugarKnown: addedSugarKnown,
        packVersion: pack.version,
        lines: List.unmodifiable(intakeLines),
      ),
      customFoodInput: CustomFoodInput(
        name: draft.name.trim(),
        portionUnit: draft.labelBasisUnit,
        labelBasisQty: draft.labelBasisQty,
        labelBasisUnit: draft.labelBasisUnit,
        lines: List.unmodifiable(customLines),
      ),
      warnings: warnings,
    );
  }

  /// Dựng [FoodEntryInput] từ [CustomFood] đã lưu khi người dùng chọn ăn với [usedQty].
  static FoodEntryInput entryFromCustomFood(
    CustomFood custom, {
    required double usedQty,
    required Meal meal,
    required DateTime at,
    required ReferencePack pack,
  }) {
    final converter = UnitConverter(pack);
    final scale = usedQty / custom.labelBasisQty;
    final intakeLines = <IntakeLine>[];

    for (final cl in custom.lines) {
      if (cl.nutrientId == 'totalSugar') continue;
      if (const {'energyKcal', 'protein', 'fat', 'carbohydrate', 'addedSugar', 'sodium'}
          .contains(cl.nutrientId)) {
        intakeLines.add(IntakeLine(
          nutrientId: cl.nutrientId,
          source: cl.source,
          labelAmount: cl.labelAmount,
          labelUnit: cl.labelUnit,
          amounts: {cl.nutrientId: cl.labelAmount * scale},
        ));
        continue;
      }
      final unit = unitFromWire(cl.labelUnit);
      final conv = converter.convertIntakeLine(IntakeLineInput(
        nutrientId: cl.nutrientId,
        source: cl.source,
        form: cl.form ?? NutrientForm.unknown,
        amount: cl.labelAmount,
        unit: unit,
        compoundKind: CompoundKind.elemental,
      ));
      if (conv.amounts.isNotEmpty || (conv.ulAmounts != null && conv.ulAmounts!.isNotEmpty)) {
        intakeLines.add(IntakeLine(
          nutrientId: cl.nutrientId,
          source: cl.source,
          form: cl.form,
          uncertain: conv.uncertain,
          labelAmount: cl.labelAmount,
          labelUnit: cl.labelUnit,
          amounts: {for (final e in conv.amounts.entries) e.key: e.value * scale},
          ulAmounts: conv.ulAmounts == null
              ? null
              : {for (final e in conv.ulAmounts!.entries) e.key: e.value * scale},
        ));
      }
    }

    return FoodEntryInput(
      at: at,
      meal: meal,
      name: custom.name,
      foodRef: 'custom:${custom.id}',
      portionUnit: custom.labelBasisUnit,
      portionQty: usedQty,
      labelBasisQty: custom.labelBasisQty,
      labelBasisUnit: custom.labelBasisUnit,
      addedSugarKnown: custom.addedSugarKnown,
      packVersion: pack.version,
      lines: List.unmodifiable(intakeLines),
    );
  }

  /// Ngưỡng nhắc nhầm đơn vị (specs/food-library.md, Câu hỏi 4):
  /// > 100% UL (chất có UL) hoặc > 10x RDA/AI (chất không UL).
  static List<UnitPlausibilityWarning> checkPlausibility(
    List<IntakeLine> lines, {
    required ReferencePack pack,
    Profile? profile,
  }) {
    final g = profile == null ? pack.groups.first.id : driGroupFor(pack, profile);
    final out = <UnitPlausibilityWarning>[];
    final totals = <String, double>{};
    for (final l in lines) {
      for (final e in l.amounts.entries) {
        totals[e.key] = (totals[e.key] ?? 0) + e.value;
      }
      if (l.ulAmounts != null) {
        for (final e in l.ulAmounts!.entries) {
          totals[e.key] = math.max(totals[e.key] ?? 0, e.value);
        }
      }
    }

    for (final e in totals.entries) {
      final def = pack.nutrients[e.key];
      if (def == null || def.group == 'macro') continue;
      final val = e.value;
      if (val <= 0) continue;

      final ulDef = def.ulKey != null ? pack.nutrients[def.ulKey!] : def;
      final ulVal = profile != null && ulDef != null
          ? ulFor(pack, profile, ulDef.id)
          : ulDef?.ul[g];
      final targetVal = def.target[g];

      var flagged = false;
      if (def.ulKey == null) {
        if (ulVal != null) {
          if (val > ulVal) flagged = true;
        } else if (targetVal != null && val > 10 * targetVal) {
          flagged = true;
        }
      } else {
        // vitA -> retinol, folate -> folicAcid: nếu có phần UL sẽ do key UL kiểm;
        // nếu chỉ là dạng thực vật/tự nhiên không có key UL thì kiểm 10x RDA/AI.
        if (!totals.containsKey(def.ulKey) && targetVal != null && val > 10 * targetVal) {
          flagged = true;
        }
      }

      if (flagged) {
        out.add(UnitPlausibilityWarning(
          nutrientId: def.id,
          nutrientNameVi: def.nameVi,
          displayAmount: val,
          displayUnit: def.unit,
        ));
      }
    }
    return out;
  }
}
