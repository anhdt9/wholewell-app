/// Bộ phân tích văn bản OCR trên nhãn thực phẩm bổ sung (thuần Dart, hỗ trợ fuzzy matching).
library;

import 'dart:math' as math;

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
  final double? suggestedUnitsPerServing;
  final CountUnit? suggestedCountUnit;
  final List<String> rawLines;

  const ParsedLabelPackage({
    required this.ingredients,
    this.suggestedProductName,
    this.suggestedBoxRemaining,
    this.suggestedUnitsPerServing,
    this.suggestedCountUnit,
    this.rawLines = const [],
  });
}

/// Phân tích các dòng text OCR thành danh sách dòng thành phần và gợi ý thông tin sản phẩm.
class SupplementLabelParser {
  // Bắt số + đơn vị, kể cả một số lỗi nhận nhầm ký tự phổ biến của OCR (mq/m9 -> mg, meg/ucg -> ug, 1u/lu -> iu).
  static final _amountUnitRe = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(mcg\s*dfe|µg\s*dfe|ug\s*dfe|mcg\s*rae|µg\s*rae|ug\s*rae|mg\s*ne|mcg|µg|ug|meg|ucg|pcg|u9|mg|mq|m9|iu|ui|1u|lu|g)\b',
    caseSensitive: false,
  );

  static final _packCountRe = RegExp(
    r'\b(\d{1,4})\s*(tablets?|capsules?|capsues|softgels?|sachets?|gummies|viên\s*nang\s*mềm|viên\s*nang|viên|gói)\b',
    caseSensitive: false,
  );

  static final _servingSizeRe = RegExp(
    r'(?:serving\s*size|khẩu\s*phần|mỗi\s*lần\s*uống)[^0-9]{0,12}(\d+(?:[.,]\d+)?)',
    caseSensitive: false,
  );

  static const _nutrientPatterns = <(String, List<String>)>[
    ('vitA', ['vitamin a', 'vit a', 'retinol', 'retinyl', 'beta-carotene', 'beta carotene']),
    ('vitC', ['vitamin c', 'vit c', 'ascorbic', 'ascorbat']),
    ('vitD', ['vitamin d3', 'vitamin d', 'vit d', 'cholecalciferol', 'ergocalciferol']),
    ('vitE', ['vitamin e', 'vit e', 'tocopherol', 'tocopheryl']),
    ('vitK', ['vitamin k2', 'vitamin k1', 'vitamin k', 'vit k', 'phylloquinone', 'menaquinone']),
    ('thiamin', ['vitamin b1', 'vitamin b-1', 'thiamin', 'thiamine', 'benfotiamine']),
    ('riboflavin', ['vitamin b2', 'vitamin b-2', 'riboflavin']),
    ('niacin', ['vitamin b3', 'vitamin b-3', 'niacin', 'niacinamide', 'nicotinamide']),
    ('vitB6', ['vitamin b6', 'vitamin b-6', 'pyridoxine', 'pyridoxal']),
    ('folicAcid', ['folic acid', 'axit folic', 'acid folic']),
    ('folate', ['folate', 'methylfolate', 'dfe']),
    ('vitB12', ['vitamin b12', 'vitamin b-12', 'cobalamin', 'cyanocobalamin', 'methylcobalamin']),
    ('biotin', ['biotin', 'vitamin b7', 'vitamin b-7']),
    ('pantothenic', ['pantothenic', 'pantothenate', 'vitamin b5', 'vitamin b-5']),
    ('choline', ['choline', 'bitartrate']),
    ('calcium', ['calcium', 'canxi', 'calci']),
    ('iron', ['iron', 'ferrous', 'ferric', 'sắt']),
    ('magnesium', ['magnesium', 'magie', 'magnesi']),
    ('zinc', ['zinc', 'kẽm']),
    ('selenium', ['selenium', 'selen']),
    ('copper', ['copper', 'đồng']),
    ('iodine', ['iodine', 'iốt', 'iod']),
    ('phosphorus', ['phosphorus', 'phốt pho']),
    ('potassium', ['potassium', 'kali']),
  ];

  // Từ đơn dài >= 5 ký tự cho phép fuzzy matching (Levenshtein <= 2 cho >= 7 ký tự, <= 1 cho 5..6 ký tự).
  static const _fuzzyKeywords = <(String, String)>[
    ('calcium', 'calcium'),
    ('magnesium', 'magnesium'),
    ('selenium', 'selenium'),
    ('riboflavin', 'riboflavin'),
    ('thiamine', 'thiamin'),
    ('pyridoxine', 'vitB6'),
    ('cobalamin', 'vitB12'),
    ('cholecalciferol', 'vitD'),
    ('ergocalciferol', 'vitD'),
    ('ascorbic', 'vitC'),
    ('tocopherol', 'vitE'),
    ('tocopheryl', 'vitE'),
    ('niacinamide', 'niacin'),
    ('nicotinamide', 'niacin'),
    ('pantothenic', 'pantothenic'),
    ('biotin', 'biotin'),
    ('phosphorus', 'phosphorus'),
    ('potassium', 'potassium'),
    ('ferrous', 'iron'),
    ('copper', 'copper'),
    ('iodine', 'iodine'),
    ('folate', 'folate'),
    ('retinol', 'vitA'),
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
    'natural health products',
    'natural healih products',
  ];

  static int _editDistance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (j) => j);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        curr[j] = math.min(
          math.min(curr[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + cost,
        );
      }
      for (var j = 0; j <= b.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }

  static bool _fuzzyContains(String text, String keyword, {int? maxDist}) {
    final limit = maxDist ?? (keyword.length >= 7 ? 2 : 1);
    final tokens = RegExp(r'[a-zA-ZÀ-ỹ0-9]+').allMatches(text.toLowerCase()).map((m) => m.group(0)!);
    for (final t in tokens) {
      if ((t.length - keyword.length).abs() > limit) continue;
      if (_editDistance(t, keyword) <= limit) return true;
    }
    return false;
  }

  static double? _parseNumber(String raw) {
    final s = raw.trim();
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
    // Fuzzy matching cho các lỗi OCR mất/sai 1–2 ký tự.
    for (final (kw, nid) in _fuzzyKeywords) {
      if (_fuzzyContains(lower, kw)) return nid;
    }
    // Tên ngắn 4 ký tự: zinc / iron (chỉ khớp fuzzy khoảng cách 1).
    if (_fuzzyContains(lower, 'zinc', maxDist: 1)) return 'zinc';
    return null;
  }

  static ParsedLabelPackage parsePackage(List<String> rawLines) {
    final lines = [for (final r in rawLines) if (r.trim().isNotEmpty) r.trim()];
    final ingredients = <ParsedIngredientLine>[];
    String? suggestedName;
    double? suggestedBoxCount;
    double? suggestedUnitsPerServing;
    CountUnit? suggestedUnit;

    // 1. Gợi ý tên sản phẩm, khẩu phần & quy cách đóng gói.
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (suggestedUnitsPerServing == null) {
        final sm = _servingSizeRe.firstMatch(lower);
        if (sm != null) {
          suggestedUnitsPerServing = _parseNumber(sm.group(1)!);
        }
      }
      final countMatch = _packCountRe.firstMatch(lower);
      if (suggestedBoxCount == null &&
          countMatch != null &&
          !lower.contains('serving') &&
          !lower.contains('khẩu phần') &&
          !lower.contains('mỗi lần')) {
        suggestedBoxCount = double.tryParse(countMatch.group(1)!);
        final u = countMatch.group(2)!;
        if (u.contains('softgel') || u.contains('mềm')) {
          suggestedUnit = CountUnit.softgel;
        } else if (u.contains('capsule') || u.contains('capsue') || u.contains('nang')) {
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

    // 2. Phân tích từng dòng thành phần (giữ ngữ cảnh tên chất qua cửa sổ 3 dòng).
    String? pendingNutrientId;
    int pendingIndex = -99;
    final contextBuffer = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();
      if (_ignoredHeaderWords.any(lowerLine.contains)) continue;

      final m = _amountUnitRe.firstMatch(line);
      final lineNutrient = _matchNutrientId(lowerLine);

      if (m == null) {
        if (lineNutrient != null) {
          pendingNutrientId = lineNutrient;
          pendingIndex = i;
          contextBuffer
            ..clear()
            ..add(line);
        } else if (pendingNutrientId != null && i - pendingIndex <= 2) {
          contextBuffer.add(line);
        }
        continue;
      }

      final amount = _parseNumber(m.group(1)!);
      if (amount == null || amount <= 0) continue;

      final unitRaw = m.group(2)!.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final unit = switch (unitRaw) {
        'mcg dfe' || 'µg dfe' || 'ug dfe' => LabelUnit.ugDfe,
        'mcg rae' || 'µg rae' || 'ug rae' => LabelUnit.ugRae,
        'mg ne' => LabelUnit.mgNe,
        'mg' || 'mq' || 'm9' => LabelUnit.mg,
        'mcg' || 'µg' || 'ug' || 'meg' || 'ucg' || 'pcg' || 'u9' => LabelUnit.ug,
        'iu' || 'ui' || '1u' || 'lu' => LabelUnit.iu,
        'g' => LabelUnit.g,
        _ => null,
      };

      String? matchedNid = lineNutrient;
      String combinedLine = line;
      if (matchedNid == null && pendingNutrientId != null && i - pendingIndex <= 3) {
        matchedNid = pendingNutrientId;
        combinedLine = '${contextBuffer.join(' ')} $line';
      }
      pendingNutrientId = null;
      contextBuffer.clear();

      final lower = combinedLine.toLowerCase();
      final freeName = matchedNid == null ? _extractName(line, m.start) : null;
      if (matchedNid == null && (freeName == null || freeName.length < 2)) continue;

      var form = NutrientForm.unknown;
      var compoundKind = CompoundKind.elemental;
      final explicitElemental = lower.contains('elemental') ||
          lower.contains('nguyên tố') ||
          _fuzzyContains(lower, 'elemental', maxDist: 2);

      if (matchedNid == 'calcium' && !explicitElemental) {
        if (lower.contains('carbonate') ||
            lower.contains('carbonat') ||
            _fuzzyContains(lower, 'carbonate', maxDist: 2)) {
          form = 'calcium_carbonate';
          compoundKind = CompoundKind.compound;
        } else if (lower.contains('citrate') ||
            lower.contains('citrat') ||
            _fuzzyContains(lower, 'citrate', maxDist: 1)) {
          form = 'calcium_citrate';
          compoundKind = CompoundKind.compound;
        }
      } else if (matchedNid == 'iron' && !explicitElemental) {
        if (lower.contains('fumarate') ||
            lower.contains('fumarat') ||
            _fuzzyContains(lower, 'fumarate', maxDist: 2)) {
          form = 'ferrous_fumarate';
          compoundKind = CompoundKind.compound;
        } else if (lower.contains('sulfate') ||
            lower.contains('sulfat') ||
            _fuzzyContains(lower, 'sulfate', maxDist: 1)) {
          form = 'ferrous_sulfate';
          compoundKind = CompoundKind.compound;
        } else if (lower.contains('gluconate') ||
            lower.contains('gluconat') ||
            _fuzzyContains(lower, 'gluconate', maxDist: 2)) {
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
      suggestedUnitsPerServing: suggestedUnitsPerServing,
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
