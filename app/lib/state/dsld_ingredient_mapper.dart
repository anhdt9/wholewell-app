/// Chuyển đổi bản ghi [DsldProductDetail] từ NIH DSLD sang danh sách dòng xác nhận và gợi ý sản phẩm.
library;

import 'package:dsld_library/dsld_library.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import '../ui/confirm_ingredients_screen.dart';
import 'label_unit_text.dart';
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
    final parsedUps = m == null ? null : double.tryParse(m.group(1)!.replaceAll(',', '.'));
    final ups = (parsedUps != null && parsedUps.isFinite && parsedUps > 0) ? parsedUps : 1.0;
    return (unit, ups);
  }

  static EditableIngredient? _mapFact(DsldFact f, ReferencePack pack) {
    final ing = f.ingredient.trim();
    if (ing.isEmpty) return null;
    final cat = f.category.trim().toLowerCase();
    // Bỏ qua dòng tiêu đề nhóm / calo / đường tổng nếu không phải vi chất cần theo dõi,
    // nhưng giữ vitamin, mineral, hoặc các chất có số lượng rõ ràng.
    // `%` là phần trăm giá trị hằng ngày, không phải lượng: bỏ cả lượng và đơn vị.
    final isPercent = f.unit.trim() == '%';
    final rawAmount = double.tryParse(f.amount.trim().replaceAll(',', '.'));
    final amount =
        (!isPercent && rawAmount != null && rawAmount.isFinite && rawAmount >= 0) ? rawAmount : null;
    // Đơn vị lạ để trống cho người dùng chọn theo nhãn, không lấy đơn vị chuẩn của chất.
    final unit = isPercent ? null : LabelUnitText.parse(f.unit);

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

    return EditableIngredient(
      nutrientId: nutrientId,
      freeName: nutrientId == null ? ing : null,
      form: p?.form ?? NutrientForm.unknown,
      labelAmount: amount,
      labelUnit: unit,
      isCompound: p != null && p.compoundKind != CompoundKind.elemental,
      origin: IngredientOrigin.barcode,
      confirmed: false,
    );
  }
}
