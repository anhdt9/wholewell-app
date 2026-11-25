/// Bộ phân tích văn bản OCR trên nhãn thực phẩm bổ sung (thuần Dart, không AI tạo sinh).
library;

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

class ParsedIngredientLine {
  final String rawLine;
  final String? nutrientId;
  final String? freeName;
  final String form;
  final double? amount;
  final LabelUnit? unit;
  final CompoundKind compoundKind;

  const ParsedIngredientLine({
    required this.rawLine,
    this.nutrientId,
    this.freeName,
    this.form = NutrientForm.unknown,
    this.amount,
    this.unit,
    this.compoundKind = CompoundKind.elemental,
  });
}

class ParsedLabelPackage {
  final List<ParsedIngredientLine> ingredients;
  final String? suggestedProductName;
  final double? suggestedBoxRemaining;
  final CountUnit? suggestedCountUnit;
  final List<String> rawLines;

  const ParsedLabelPackage({
    required this.ingredients,
    this.suggestedProductName,
    this.suggestedBoxRemaining,
    this.suggestedCountUnit,
    this.rawLines = const [],
  });
}

/// Phân tích các dòng text OCR thành danh sách dòng thành phần và gợi ý thông tin sản phẩm.
class SupplementLabelParser {
  static final _amountUnitRe = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(mcg|µg|ug|mg|iu|ui|g)\b',
    caseSensitive: false,
  );

  static final _packCountRe = RegExp(
    r'(\d+)\s*(tablets?|capsules?|softgels?|sachets?|gummies|viên\s*nang\s*mềm|viên\s*nang|viên|gói)\b',
    caseSensitive: false,
  );

  static const _nutrientPatterns = <(String, List<String>)>[
    ('vitA', ['vitamin a', 'vit a', 'retinol', 'retinyl', 'beta-carotene', 'beta carotene']),
    ('vitC', ['vitamin c', 'vit c', 'ascorbic acid', 'ascorbat']),
    ('vitD', ['vitamin d3', 'vitamin d', 'vit d', 'cholecalciferol', 'ergocalciferol']),
    ('vitE', ['vitamin e', 'vit e', 'tocopherol', 'tocopheryl']),
    ('vitK', ['vitamin k2', 'vitamin k1', 'vitamin k', 'vit k', 'phylloquinone', 'menaquinone']),
    ('thiamin', ['vitamin b1', 'thiamin', 'thiamine']),
    ('riboflavin', ['vitamin b2', 'riboflavin']),
    ('niacin', ['vitamin b3', 'niacin', 'niacinamide', 'nicotinamide']),
    ('vitB6', ['vitamin b6', 'pyridoxine']),
    ('folicAcid', ['folic acid', 'axit folic', 'acid folic']),
    ('folate', ['folate', 'dfe']),
    ('vitB12', ['vitamin b12', 'cobalamin', 'cyanocobalamin', 'methylcobalamin']),
    ('biotin', ['biotin', 'vitamin b7']),
    ('pantothenic', ['pantothenic', 'vitamin b5']),
    ('calcium', ['calcium', 'canxi', 'calci']),
    ('iron', ['iron', 'ferrous', 'ferric', 'sắt', 'sat']),
    ('magnesium', ['magnesium', 'magie', 'magnesi']),
    ('zinc', ['zinc', 'kẽm', 'kem']),
    ('selenium', ['selenium', 'selen']),
    ('copper', ['copper', 'đồng']),
    ('iodine', ['iodine', 'iốt', 'iod']),
    ('phosphorus', ['phosphorus', 'phốt pho', 'phot pho']),
    ('potassium', ['potassium', 'kali']),
  ];

  static const _ignoredHeaderWords = [
    'supplement facts',
    'nutrition facts',
    'thành phần',
    'serving size',
    'servings per',
    'amount per serving',
    'daily value',
    '% dv',
    'directions',
    'cách dùng',
    'hướng dẫn',
    'thực phẩm bảo vệ sức khỏe',
  ];

  static double? _parseNumber(String raw) {
    final s = raw.trim();
    // Hỗ trợ dấu phân cách nghìn kiểu Mỹ (1,250) hoặc VN (1.250).
    if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(s)) {
      return double.tryParse(s.replaceAll(',', ''));
    }
    if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
      return double.tryParse(s.replaceAll('.', ''));
    }
    return double.tryParse(s.replaceAll(',', '.'));
  }

  static String? _matchNutrientId(String lower) {
    for (final (nid, keys) in _nutrientPatterns) {
      if (keys.any(lower.contains)) return nid;
    }
    return null;
  }

  static ParsedLabelPackage parsePackage(List<String> rawLines) {
    final lines = [for (final r in rawLines) if (r.trim().isNotEmpty) r.trim()];
    final ingredients = <ParsedIngredientLine>[];
    String? suggestedName;
    double? suggestedBoxCount;
    CountUnit? suggestedUnit;

    // 1. Gợi ý tên sản phẩm & quy cách đóng gói từ các dòng đầu/không phải dòng thành phần.
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      final countMatch = _packCountRe.firstMatch(lower);
      if (suggestedBoxCount == null && countMatch != null) {
        suggestedBoxCount = double.tryParse(countMatch.group(1)!);
        final u = countMatch.group(2)!;
        if (u.contains('softgel') || u.contains('mềm')) {
          suggestedUnit = CountUnit.softgel;
        } else if (u.contains('capsule') || u.contains('nang')) {
          suggestedUnit = CountUnit.capsule;
        } else if (u.contains('sachet') || u.contains('gói')) {
          suggestedUnit = CountUnit.sachet;
        } else {
          suggestedUnit = CountUnit.tablet;
        }
      }
      final nextIsAmountOnly = i + 1 < lines.length &&
          _amountUnitRe.hasMatch(lines[i + 1]) &&
          _matchNutrientId(lines[i + 1].toLowerCase()) == null;
      if (suggestedName == null &&
          countMatch == null &&
          !nextIsAmountOnly &&
          line.length >= 3 &&
          line.length <= 60 &&
          !_amountUnitRe.hasMatch(line) &&
          !_ignoredHeaderWords.any(lower.contains) &&
          RegExp(r'[a-zA-ZÀ-ỹ]').hasMatch(line)) {
        suggestedName = line;
      }
    }

    // 2. Phân tích từng dòng thành phần (có ghép cặp khi tên chất và số lượng tách 2 dòng kề nhau).
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      var m = _amountUnitRe.firstMatch(line);
      var combinedLine = line;

      if (m == null) {
        // Thử ghép nếu dòng hiện tại có tên chất nhưng số lượng nằm ngay ở dòng kế tiếp.
        final hasNutrient = _matchNutrientId(line.toLowerCase()) != null;
        if (hasNutrient && i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          final nextMatch = _amountUnitRe.firstMatch(nextLine);
          if (nextMatch != null && _matchNutrientId(nextLine.toLowerCase()) == null) {
            combinedLine = '$line $nextLine';
            m = _amountUnitRe.firstMatch(combinedLine);
            i++;
          }
        }
      }

      if (m == null) continue;

      final amount = _parseNumber(m.group(1)!);
      if (amount == null || amount <= 0) continue;

      final unitRaw = m.group(2)!.toLowerCase();
      final unit = switch (unitRaw) {
        'mg' => LabelUnit.mg,
        'mcg' || 'µg' || 'ug' => LabelUnit.ug,
        'iu' || 'ui' => LabelUnit.iu,
        'g' => LabelUnit.g,
        _ => null,
      };

      final lower = combinedLine.toLowerCase();
      final matchedNid = _matchNutrientId(lower);
      final freeName = matchedNid == null ? _extractName(combinedLine, m.start) : null;
      if (matchedNid == null && (freeName == null || freeName.length < 2)) continue;

      var form = NutrientForm.unknown;
      var compoundKind = CompoundKind.elemental;
      if (matchedNid == 'calcium') {
        if (lower.contains('carbonate') || lower.contains('carbonat')) {
          form = 'calcium_carbonate';
          compoundKind = CompoundKind.compound;
        } else if (lower.contains('citrate') || lower.contains('citrat')) {
          form = 'calcium_citrate';
          compoundKind = CompoundKind.compound;
        }
      } else if (matchedNid == 'iron') {
        if (lower.contains('fumarate') || lower.contains('fumarat')) {
          form = 'ferrous_fumarate';
          compoundKind = CompoundKind.compound;
        } else if (lower.contains('sulfate') || lower.contains('sulfat')) {
          form = 'ferrous_sulfate';
          compoundKind = CompoundKind.compound;
        } else if (lower.contains('gluconate') || lower.contains('gluconat')) {
          form = 'ferrous_gluconate';
          compoundKind = CompoundKind.compound;
        }
      } else if (matchedNid == 'vitE') {
        if (lower.contains('dl-alpha') || lower.contains('dl alpha')) {
          form = NutrientForm.synthetic2r;
        } else if (lower.contains('d-alpha') || lower.contains('d alpha')) {
          form = NutrientForm.natural2r;
        }
      } else if (matchedNid == 'vitA') {
        if (lower.contains('beta')) {
          form = NutrientForm.betaCarotene;
        } else if (lower.contains('retinyl') || lower.contains('retinol')) {
          form = NutrientForm.retinol;
        }
      } else if (matchedNid == 'folicAcid') {
        form = NutrientForm.folicAcid;
      }

      ingredients.add(ParsedIngredientLine(
        rawLine: combinedLine,
        nutrientId: matchedNid,
        freeName: freeName,
        form: form,
        amount: amount,
        unit: unit,
        compoundKind: compoundKind,
      ));
    }

    return ParsedLabelPackage(
      ingredients: ingredients,
      suggestedProductName: suggestedName,
      suggestedBoxRemaining: suggestedBoxCount,
      suggestedCountUnit: suggestedUnit,
      rawLines: lines,
    );
  }

  static List<ParsedIngredientLine> parseLines(List<String> rawLines) =>
      parsePackage(rawLines).ingredients;

  static String? _extractName(String line, int matchStart) {
    final prefix = line.substring(0, matchStart).replaceAll(RegExp(r'[:\-–()]+$'), '').trim();
    return prefix.isEmpty ? null : prefix;
  }
}
