/// Bộ phân tích văn bản OCR trên nhãn thực phẩm bổ sung (thuần Dart, không AI tạo sinh).
library;

import 'package:health_engine/health_engine.dart';

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

/// Phân tích các dòng text OCR thành danh sách dòng thành phần tiềm năng để người dùng xác nhận.
class SupplementLabelParser {
  static final _amountUnitRe = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(mcg|µg|ug|mg|iu|g)\b',
    caseSensitive: false,
  );

  static const _nutrientPatterns = <(String, List<String>)>[
    ('vitA', ['vitamin a', 'vit a', 'retinol', 'retinyl', 'beta-carotene', 'beta carotene']),
    ('vitC', ['vitamin c', 'vit c', 'ascorbic acid', 'ascorbat']),
    ('vitD', ['vitamin d3', 'vitamin d', 'vit d', 'cholecalciferol', 'ergocalciferol']),
    ('vitE', ['vitamin e', 'vit e', 'tocopherol', 'tocopheryl']),
    ('vitK', ['vitamin k', 'vit k', 'phylloquinone', 'menaquinone']),
    ('thiamin', ['vitamin b1', 'thiamin', 'thiamine']),
    ('riboflavin', ['vitamin b2', 'riboflavin']),
    ('niacin', ['vitamin b3', 'niacin', 'niacinamide', 'nicotinamide']),
    ('vitB6', ['vitamin b6', 'pyridoxine']),
    ('folicAcid', ['folic acid', 'axit folic']),
    ('folate', ['folate', 'dfe']),
    ('vitB12', ['vitamin b12', 'cobalamin', 'cyanocobalamin', 'methylcobalamin']),
    ('biotin', ['biotin', 'vitamin b7']),
    ('pantothenic', ['pantothenic', 'vitamin b5']),
    ('calcium', ['calcium', 'canxi']),
    ('iron', ['iron', 'ferrous', 'ferric', 'sắt']),
    ('magnesium', ['magnesium', 'magie', 'magnesi']),
    ('zinc', ['zinc', 'kẽm']),
    ('selenium', ['selenium', 'selen']),
    ('copper', ['copper', 'đồng']),
    ('iodine', ['iodine', 'iốt', 'iod']),
    ('phosphorus', ['phosphorus', 'phốt pho']),
    ('potassium', ['potassium', 'kali']),
  ];

  static List<ParsedIngredientLine> parseLines(List<String> rawLines) {
    final out = <ParsedIngredientLine>[];
    for (final raw in rawLines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = _amountUnitRe.firstMatch(line);
      if (m == null) continue;

      final amtStr = m.group(1)!.replaceAll(',', '.');
      final amount = double.tryParse(amtStr);
      if (amount == null || amount <= 0) continue;

      final unitRaw = m.group(2)!.toLowerCase();
      final unit = switch (unitRaw) {
        'mg' => LabelUnit.mg,
        'mcg' || 'µg' || 'ug' => LabelUnit.ug,
        'iu' => LabelUnit.iu,
        'g' => LabelUnit.g,
        _ => null,
      };

      final lower = line.toLowerCase();
      String? matchedNid;
      for (final (nid, keys) in _nutrientPatterns) {
        if (keys.any(lower.contains)) {
          matchedNid = nid;
          break;
        }
      }

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

      out.add(ParsedIngredientLine(
        rawLine: line,
        nutrientId: matchedNid,
        freeName: matchedNid == null ? _extractName(line, m.start) : null,
        form: form,
        amount: amount,
        unit: unit,
        compoundKind: compoundKind,
      ));
    }
    return out;
  }

  static String? _extractName(String line, int matchStart) {
    final prefix = line.substring(0, matchStart).replaceAll(RegExp(r'[:\-–]+$'), '').trim();
    return prefix.isEmpty ? null : prefix;
  }
}
