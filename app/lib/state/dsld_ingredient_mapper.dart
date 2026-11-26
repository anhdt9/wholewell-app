/// Chuyển đổi bản ghi [DsldProductDetail] từ NIH DSLD sang danh sách dòng xác nhận và gợi ý sản phẩm.
library;

import 'package:dsld_library/dsld_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import '../ui/confirm_ingredients_screen.dart';
import 'supplement_label_parser.dart';

class DsldMappedProduct {
  final String displayName;
  final String barcode;
  final CountUnit suggestedCountUnit;
  final double suggestedUnitsPerServing;
  final List<EditableIngredient> ingredients;
  final bool hasUnknownForm;

  const DsldMappedProduct({
    required this.displayName,
    required this.barcode,
    required this.suggestedCountUnit,
    required this.suggestedUnitsPerServing,
    required this.ingredients,
    required this.hasUnknownForm,
  });
}

class DsldIngredientMapper {
  DsldIngredientMapper._();

  static final _servingNumRe = RegExp(r'^(\d+(?:[.,]\d+)?)');

  static DsldMappedProduct mapProduct(DsldProductDetail detail, ReferencePack pack) {
    final brand = detail.brandName.trim();
    final name = detail.productName.trim();
    final displayName = brand.isNotEmpty && !name.toLowerCase().contains(brand.toLowerCase())
        ? '$brand $name'
        : name;

    final servingInfo = _parseServing(detail.servingSize, detail.supplementForm);
    final lines = <EditableIngredient>[];
    var hasUnknownForm = false;

    for (final f in detail.facts) {
      final mapped = _mapFact(f, pack);
      if (mapped == null) continue;
      if (mapped.nutrientId != null && mapped.form == NutrientForm.unknown) {
        hasUnknownForm = true;
      }
      lines.add(mapped);
    }

    return DsldMappedProduct(
      displayName: displayName,
      barcode: detail.barcode,
      suggestedCountUnit: servingInfo.$1,
      suggestedUnitsPerServing: servingInfo.$2,
      ingredients: lines,
      hasUnknownForm: hasUnknownForm,
    );
  }

  static (CountUnit, double) _parseServing(String servingSize, String supplementForm) {
    final lower = '$servingSize $supplementForm'.toLowerCase();
    final CountUnit unit;
    if (lower.contains('softgel')) {
      unit = CountUnit.softgel;
    } else if (lower.contains('capsule') || lower.contains('veggie cap')) {
      unit = CountUnit.capsule;
    } else if (lower.contains('packet') || lower.contains('sachet')) {
      unit = CountUnit.sachet;
    } else if (lower.contains('gram') || lower.contains('powder') || lower.contains('scoop')) {
      unit = CountUnit.g;
    } else if (lower.contains('ml') || lower.contains('liquid')) {
      unit = CountUnit.ml;
    } else if (lower.contains('drop')) {
      unit = CountUnit.drop;
    } else {
      unit = CountUnit.tablet;
    }

    final m = _servingNumRe.firstMatch(servingSize.trim());
    final ups = m == null ? 1.0 : (double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 1.0);
    return (unit, ups > 0 ? ups : 1.0);
  }

  static EditableIngredient? _mapFact(DsldFact f, ReferencePack pack) {
    final ing = f.ingredient.trim();
    if (ing.isEmpty) return null;
    final cat = f.category.trim().toLowerCase();
    // Bỏ qua dòng tiêu đề nhóm / calo / đường tổng nếu không phải vi chất cần theo dõi,
    // nhưng giữ vitamin, mineral, hoặc các chất có số lượng rõ ràng.
    final amount = double.tryParse(f.amount.trim().replaceAll(',', '.'));
    final unit = _parseUnit(f.unit);

    // Tận dụng SupplementLabelParser để ánh xạ tên chất + dạng.
    final fakeLine = '$ing ${f.amount} ${f.unit}'.trim();
    final parsed = SupplementLabelParser.parseLines([fakeLine]);
    final p = parsed.isNotEmpty ? parsed.first : null;
    final nutrientId = (p != null && p.nutrientId != null && pack.nutrients.containsKey(p.nutrientId))
        ? p.nutrientId
        : null;

    if (nutrientId == null && (cat == 'blend' || amount == null || unit == null)) {
      return null;
    }

    final def = nutrientId == null ? null : pack.nutrients[nutrientId];
    return EditableIngredient(
      nutrientId: nutrientId,
      freeName: nutrientId == null ? ing : null,
      form: p?.form ?? NutrientForm.unknown,
      labelAmount: amount,
      labelUnit: unit ?? _defaultUnitFor(def?.unit),
      isCompound: p != null && p.compoundKind != CompoundKind.elemental,
      origin: IngredientOrigin.barcode,
      confirmed: false,
    );
  }

  static LabelUnit? _parseUnit(String raw) {
    final u = raw.trim().toLowerCase();
    if (u.isEmpty) return null;
    if (u == 'g' || u == 'gram' || u == 'grams' || u == 'gram(s)') return LabelUnit.g;
    if (u == 'mg') return LabelUnit.mg;
    if (u == 'mcg' || u == 'ug' || u == 'µg') return LabelUnit.ug;
    if (u == 'iu') return LabelUnit.iu;
    if (u == 'mcg rae' || u == 'ug rae' || u == 'µg rae') return LabelUnit.ugRae;
    if (u == 'mcg dfe' || u == 'ug dfe' || u == 'µg dfe') return LabelUnit.ugDfe;
    if (u == 'mg ne') return LabelUnit.mgNe;
    return null;
  }

  static LabelUnit _defaultUnitFor(String? packUnit) => switch (packUnit) {
        'g' => LabelUnit.g,
        'mg' => LabelUnit.mg,
        'ug' => LabelUnit.ug,
        'ug_RAE' => LabelUnit.ugRae,
        'ug_DFE' => LabelUnit.ugDfe,
        'mg_NE' => LabelUnit.mgNe,
        _ => LabelUnit.mg,
      };
}
