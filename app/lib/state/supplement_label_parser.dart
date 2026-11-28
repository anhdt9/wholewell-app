/// Bộ phân tích văn bản OCR trên nhãn thực phẩm bổ sung (thuần Dart, hỗ trợ fuzzy matching).
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

import 'label_unit_text.dart';

class ParsedIngredientLine {
  final String rawLine;
  final String? nutrientId;
  final String? freeName;
  final String form;
  final double? amount;

  /// `null` khi nhãn không ghi đơn vị hoặc đơn vị không có trong danh sách: người dùng chọn theo nhãn.
  final LabelUnit? unit;
  final CompoundKind compoundKind;

  /// Dòng AI chưa khớp chữ đọc từ ảnh: người dùng phải kiểm qua bảng sửa dòng.
  final bool needsCheck;

  const ParsedIngredientLine({
    required this.rawLine,
    this.nutrientId,
    this.freeName,
    this.form = NutrientForm.unknown,
    this.amount,
    this.unit,
    this.compoundKind = CompoundKind.elemental,
    this.needsCheck = false,
  });

  ParsedIngredientLine copyWith({String? form, CompoundKind? compoundKind, bool? needsCheck}) => ParsedIngredientLine(
    rawLine: rawLine,
    nutrientId: nutrientId,
    freeName: freeName,
    form: form ?? this.form,
    amount: amount,
    unit: unit,
    compoundKind: compoundKind ?? this.compoundKind,
    needsCheck: needsCheck ?? this.needsCheck,
  );
}

class ParsedLabelPackage {
  final List<ParsedIngredientLine> ingredients;
  final String? suggestedProductName;
  final double? suggestedBoxRemaining;
  final double? suggestedUnitsPerServing;
  final CountUnit? suggestedCountUnit;
  final List<String> rawLines;

  /// Danh sách có gợi ý của AI trên máy (Gemini Nano).
  final bool fromOnDeviceAi;

  const ParsedLabelPackage({
    required this.ingredients,
    this.suggestedProductName,
    this.suggestedBoxRemaining,
    this.suggestedUnitsPerServing,
    this.suggestedCountUnit,
    this.rawLines = const [],
    this.fromOnDeviceAi = false,
  });
}

/// Phân tích các dòng text OCR thành danh sách dòng thành phần và gợi ý thông tin sản phẩm.
class SupplementLabelParser {
  // Bắt số + đơn vị, kể cả một số lỗi nhận nhầm ký tự phổ biến của OCR (mq/m9 -> mg, meg/ucg -> ug, 1u/lu -> iu).
  // `µ` là U+00B5 (ký tự micro), `μ` là U+03BC (chữ mu Hy Lạp); OCR có thể trả một trong hai.
  static final _amountUnitRe = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(mcg\s*dfe|µg\s*dfe|μg\s*dfe|ug\s*dfe|mcg\s*rae|µg\s*rae|μg\s*rae|ug\s*rae|mg\s*ne|micrograms?|milligrams?|grams?|international\s+units?|mcg|µg|μg|ug|meg|ucg|pcg|u9|mg|mq|m9|iu|ui|1u|lu|g)(?![a-zA-ZÀ-ỹ])',
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

  /// Chữ đánh dấu tên nguồn trên bảng Supplement Facts, vd. "Calcium (as calcium carbonate)".
  /// Theo 21 CFR 101.36(d) và (b)(2)(ii), lượng ghi khi đó là lượng nguyên tố.
  /// Phải trùng `supplementFactsElemental.markers` trong gói dữ liệu (có test kiểm).
  static const elementalSourceMarkers = ['as', 'from'];

  static const _nutrientPatterns = <(String, List<String>)>[
    ('vitA', ['vitamin a', 'vit a', 'retinol', 'retinyl', 'beta-carotene', 'beta carotene']),
    ('vitC', ['vitamin c', 'vit c', 'ascorbic', 'ascorbat']),
    ('vitD', ['vitamin d3', 'vitamin d', 'vit d', 'cholecalciferol', 'ergocalciferol']),
    ('vitE', ['vitamin e', 'vit e', 'tocopherol', 'tocopheryl']),
    ('vitK', ['vitamin k2', 'vitamin k1', 'vitamin k', 'vit k', 'phylloquinone', 'menaquinone']),
    ('vitB12', ['vitamin b12', 'vitamin b-12', 'cobalamin', 'cyanocobalamin', 'methylcobalamin']),
    ('thiamin', ['vitamin b1', 'vitamin b-1', 'thiamin', 'thiamine', 'benfotiamine']),
    ('riboflavin', ['vitamin b2', 'vitamin b-2', 'riboflavin']),
    ('niacin', ['vitamin b3', 'vitamin b-3', 'niacin', 'niacinamide', 'nicotinamide']),
    ('vitB6', ['vitamin b6', 'vitamin b-6', 'pyridoxine', 'pyridoxal']),
    ('folicAcid', ['folic acid', 'axit folic', 'acid folic']),
    ('folate', ['folate', 'methylfolate', 'dfe']),
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

  /// Hợp chất khoáng có tỷ lệ nguyên tố trong gói: (form, chữ khớp đúng, chữ khớp gần, khoảng cách).
  static const _mineralCompounds = <String, List<(String, List<String>, String, int)>>{
    'calcium': [
      ('calcium_carbonate', ['carbonate', 'carbonat'], 'carbonate', 2),
      ('calcium_citrate', ['citrate', 'citrat'], 'citrate', 1),
    ],
    'iron': [
      ('ferrous_fumarate', ['fumarate', 'fumarat'], 'fumarate', 2),
      ('ferrous_sulfate', ['sulfate', 'sulfat'], 'sulfate', 1),
      ('ferrous_gluconate', ['gluconate', 'gluconat'], 'gluconate', 2),
    ],
  };

  /// Chữ được phép đứng trước tên hợp chất khi dòng ghi tên hợp chất trần (vd. "Calcium carbonate 1250 mg").
  static const _bareCompoundLeadWords = <String, List<String>>{
    'calcium': ['calcium', 'canxi', 'calci'],
    'iron': ['iron', 'ferrous', 'ferric', 'sắt'],
  };

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

  static final _wordRe = RegExp(r'[a-zA-ZÀ-ỹ0-9]+');

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
        curr[j] = math.min(math.min(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      for (var j = 0; j <= b.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }

  static bool _fuzzyEquals(String token, String keyword, int limit) {
    if ((token.length - keyword.length).abs() > limit) return false;
    return _editDistance(token, keyword) <= limit;
  }

  static bool _fuzzyContains(String text, String keyword, {int? maxDist}) {
    final limit = maxDist ?? (keyword.length >= 7 ? 2 : 1);
    final tokens = _wordRe.allMatches(text.toLowerCase()).map((m) => m.group(0)!);
    for (final t in tokens) {
      if (_fuzzyEquals(t, keyword, limit)) return true;
    }
    return false;
  }

  static double? _parseNumber(String raw) {
    final s = raw.trim();
    final double? v;
    if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(s)) {
      v = double.tryParse(s.replaceAll(',', ''));
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
      v = double.tryParse(s.replaceAll('.', ''));
    } else {
      v = double.tryParse(s.replaceAll(',', '.'));
    }
    return (v != null && v.isFinite) ? v : null;
  }

  /// Đơn vị OCR: bỏ hết khoảng trắng trước khi so, nên `mcgdfe`, `mgne` cũng đọc được.
  static LabelUnit? _ocrUnit(String raw) {
    final u = raw.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return switch (u) {
      'mcgdfe' || 'µgdfe' || 'μgdfe' || 'ugdfe' => LabelUnit.ugDfe,
      'mcgrae' || 'µgrae' || 'μgrae' || 'ugrae' => LabelUnit.ugRae,
      'mgne' => LabelUnit.mgNe,
      'mg' || 'mq' || 'm9' || 'milligram' || 'milligrams' => LabelUnit.mg,
      'mcg' || 'µg' || 'μg' || 'ug' || 'meg' || 'ucg' || 'pcg' || 'u9' || 'microgram' || 'micrograms' => LabelUnit.ug,
      'iu' || 'ui' || '1u' || 'lu' || 'internationalunit' || 'internationalunits' => LabelUnit.iu,
      'g' || 'gram' || 'grams' => LabelUnit.g,
      _ => null,
    };
  }

  static String? _matchNutrientId(String lower) {
    if (lower.contains('dfe') || lower.contains('methylfolate')) return 'folate';
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

  /// Xếp loại dòng canxi / sắt theo cách ghi trên nhãn (đặc tả Bổ sung 1, mục B1.8):
  /// - `Chất (as/from hợp chất) N`: lượng nguyên tố, giữ dạng (quy tắc lịch như
  ///   "uống canxi carbonat cùng bữa ăn" lọc theo dạng);
  /// - bắt đầu bằng tên hợp chất (`Calcium carbonate 1250 mg`): khối lượng hợp chất;
  /// - có tên hợp chất nhưng không rõ cách ghi: chưa rõ dạng (giới hạn tính thận trọng nhất).
  static (String form, CompoundKind kind) classifyMineral(
    String? nutrientId,
    String text, {
    bool explicitElemental = false,
  }) {
    final compounds = _mineralCompounds[nutrientId];
    if (compounds == null) return (NutrientForm.unknown, CompoundKind.elemental);
    final lower = text.toLowerCase();
    if (explicitElemental ||
        lower.contains('elemental') ||
        lower.contains('nguyên tố') ||
        _fuzzyContains(lower, 'elemental', maxDist: 2)) {
      return (NutrientForm.unknown, CompoundKind.elemental);
    }

    String? formId;
    var compoundStart = -1;
    for (final m in _wordRe.allMatches(lower)) {
      final token = m.group(0)!;
      for (final (fid, exact, fuzzy, dist) in compounds) {
        if (exact.any(token.contains) || _fuzzyEquals(token, fuzzy, dist)) {
          formId = fid;
          compoundStart = m.start;
          break;
        }
      }
      if (formId != null) break;
    }
    if (formId == null) return (NutrientForm.unknown, CompoundKind.elemental);

    final prefix = lower.substring(0, compoundStart);
    final prefixWords = [for (final m in _wordRe.allMatches(prefix)) m.group(0)!];
    if (prefixWords.any(elementalSourceMarkers.contains)) {
      return (formId, CompoundKind.elemental);
    }
    final leads = _bareCompoundLeadWords[nutrientId] ?? const <String>[];
    final bare =
        !prefix.contains('(') &&
        prefixWords.every((w) => leads.any((l) => w == l || (l.length >= 5 && _fuzzyEquals(w, l, 2))));
    if (bare) return (formId, CompoundKind.compound);
    return (NutrientForm.unknown, CompoundKind.unknown);
  }

  /// Các đoạn kèm chỉ số dòng OCR gốc chứa đoạn đó.
  static List<(String, int)> _splitSegmentsIndexed(List<String> rawLines) {
    final segments = <(String, int)>[];
    for (var ri = 0; ri < rawLines.length; ri++) {
      final t = rawLines[ri].trim();
      if (t.isEmpty) continue;
      // Tách theo dấu `;` hoặc `, ` (không cắt dấu phẩy hàng nghìn như `1,250`).
      final parts = t.split(RegExp(r'[;,]\s+(?=[a-zA-ZÀ-ỹ(])'));
      for (final part in parts) {
        final p = part.trim();
        if (p.isEmpty) continue;
        final matches = _amountUnitRe.allMatches(p).toList();
        if (matches.length <= 1) {
          segments.add((p, ri));
        } else {
          // Nhiều cặp số + đơn vị nối liền không dấu phẩy: cắt ngay sau mỗi đơn vị.
          var start = 0;
          for (final m in matches) {
            final slice = p.substring(start, m.end).trim();
            if (slice.isNotEmpty) segments.add((slice, ri));
            start = m.end;
          }
          final tail = p.substring(start).trim();
          if (tail.isNotEmpty && RegExp(r'[a-zA-ZÀ-ỹ]{2,}').hasMatch(tail)) {
            segments.add((tail, ri));
          }
        }
      }
    }
    return segments;
  }

  static ParsedLabelPackage parsePackage(List<String> rawLines) {
    final indexed = _splitSegmentsIndexed(rawLines);
    final lines = [for (final (seg, _) in indexed) seg];
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
        final rawCount = double.tryParse(countMatch.group(1)!);
        if (rawCount != null && rawCount.isFinite && rawCount > 0) {
          suggestedBoxCount = rawCount;
        }
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
      final nextIsAmountOnly =
          i + 1 < lines.length &&
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
    // Dòng OCR gốc của thành phần vừa thêm, để nhận đoạn trong ngoặc ghi lại cùng chất.
    var lastAddedRaw = -1;

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

      final unit = _ocrUnit(m.group(2)!);

      // Đoạn trong ngoặc ghi lại cùng chất trên cùng dòng nhãn, vd.
      // "Calcium 500 mg (as calcium carbonate 1250 mg)": số trong ngoặc là khối lượng nguồn,
      // không phải thêm một lượng canxi. Bỏ đoạn này, chỉ lấy dạng nguồn cho dòng trước.
      if (line.startsWith('(') &&
          lineNutrient != null &&
          ingredients.isNotEmpty &&
          ingredients.last.nutrientId == lineNutrient &&
          lastAddedRaw == indexed[i].$2) {
        final prev = ingredients.last;
        if ((lineNutrient == 'calcium' || lineNutrient == 'iron') &&
            prev.compoundKind == CompoundKind.elemental &&
            prev.form == NutrientForm.unknown) {
          final (f, k) = classifyMineral(lineNutrient, line);
          if (k == CompoundKind.elemental && f != NutrientForm.unknown) {
            ingredients[ingredients.length - 1] = prev.copyWith(form: f);
          }
        }
        pendingNutrientId = null;
        contextBuffer.clear();
        continue;
      }

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

      if (matchedNid == 'calcium' || matchedNid == 'iron') {
        (form, compoundKind) = classifyMineral(matchedNid, combinedLine);
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

      ingredients.add(
        ParsedIngredientLine(
          rawLine: combinedLine,
          nutrientId: matchedNid,
          freeName: freeName,
          form: form,
          amount: amount,
          unit: unit,
          compoundKind: compoundKind,
        ),
      );
      lastAddedRaw = indexed[i].$2;
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

  static List<ParsedIngredientLine> parseLines(List<String> rawLines) => parsePackage(rawLines).ingredients;

  /// Chuyển JSON từ Gemini Nano (on-device) thành [ParsedLabelPackage]; trả `null` nếu JSON lỗi hoặc rỗng.
  ///
  /// Đơn vị thiếu hoặc lạ thì để trống (không bao giờ mặc định `mg`). Kết quả cần qua [crossCheckAi]
  /// trước khi hiện cho người dùng.
  static ParsedLabelPackage? parseAiJson(String jsonStr, List<String> rawLines) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return null;
      final rawList = decoded['ingredients'];
      if (rawList is! List || rawList.isEmpty) return null;

      final ingredients = <ParsedIngredientLine>[];
      for (final item in rawList) {
        if (item is! Map<String, dynamic>) continue;
        final name = (item['name'] as String?)?.trim() ?? '';
        final amount = (item['amount'] as num?)?.toDouble();
        if (name.isEmpty || amount == null || !amount.isFinite || amount <= 0) continue;

        final unitStr = (item['unit'] as String?)?.trim();
        final unit = LabelUnitText.parse(unitStr);
        final formText = ((item['form'] as String?) ?? '').toLowerCase();
        final explicitElemental =
            item['elemental'] == true || formText.contains('elemental') || formText.contains('nguyên tố');
        final nid = _matchNutrientId('$name $formText ${unit == LabelUnit.ugDfe ? 'dfe' : ''}'.toLowerCase());
        final combined = '$name $formText'.toLowerCase();

        var form = NutrientForm.unknown;
        var compoundKind = CompoundKind.elemental;
        if (nid == 'calcium' || nid == 'iron') {
          // AI đã chuẩn hóa tên nên không biết nhãn ghi "(as …)" hay tên hợp chất trần.
          // Có hợp chất mà không ghi nguyên tố thì coi là chưa rõ dạng (thận trọng nhất);
          // dòng khớp chữ trên ảnh được xếp lại theo đoạn chữ đó ở [crossCheckAi].
          final (f, k) = classifyMineral(nid, combined, explicitElemental: explicitElemental);
          if (k != CompoundKind.elemental || f != NutrientForm.unknown) {
            compoundKind = CompoundKind.unknown;
          }
        } else if (nid == 'vitE') {
          if (combined.contains('dl-alpha') || combined.contains('synthetic')) {
            form = NutrientForm.synthetic2r;
          } else if (combined.contains('d-alpha') || combined.contains('natural')) {
            form = NutrientForm.natural2r;
          }
        } else if (nid == 'vitA') {
          if (combined.contains('beta')) {
            form = NutrientForm.betaCarotene;
          } else if (combined.contains('retinyl') || combined.contains('retinol')) {
            form = NutrientForm.retinol;
          }
        } else if (nid == 'folicAcid') {
          form = NutrientForm.folicAcid;
        }

        ingredients.add(
          ParsedIngredientLine(
            rawLine: '$name $amount ${unitStr ?? ''}'.trim(),
            nutrientId: nid,
            freeName: nid == null ? name : null,
            form: form,
            amount: amount,
            unit: unit,
            compoundKind: compoundKind,
          ),
        );
      }
      if (ingredients.isEmpty) return null;

      final unitName = (decoded['unit'] as String?)?.toLowerCase().trim();
      final countUnit = CountUnit.values.where((u) => u.name == unitName).firstOrNull;
      return ParsedLabelPackage(
        ingredients: ingredients,
        suggestedProductName: (decoded['productName'] as String?)?.trim(),
        suggestedBoxRemaining: (decoded['boxCount'] as num?)?.toDouble(),
        suggestedUnitsPerServing: (decoded['servings'] as num?)?.toDouble(),
        suggestedCountUnit: countUnit,
        rawLines: rawLines,
        fromOnDeviceAi: true,
      );
    } on Object {
      return null;
    }
  }

  static bool _sameAmount(double a, double b) => (a - b).abs() <= 1e-9 * math.max(1, a.abs());

  /// Đối chiếu từng dòng AI với chữ đọc từ ảnh (đặc tả Bổ sung 1, mục B1.5):
  /// - dòng khớp khi số và đơn vị có trên ảnh, bộ đọc chữ không gán cặp số đó cho dòng khác
  ///   (kể cả dòng tên tự do), và bộ đọc chữ không đọc cùng chất đó với số khác (trừ khi nhãn
  ///   ghi cùng chất bằng đơn vị khác trên cùng dòng, vd. "25 mcg (1,000 IU)");
  /// - dòng không khớp (kể cả đơn vị trống) mang `needsCheck`;
  /// - chất AI bỏ sót mà bộ đọc chữ thấy được thêm vào cuối.
  static ParsedLabelPackage crossCheckAi(ParsedLabelPackage ai, ParsedLabelPackage parsed, List<String> ocrLines) {
    final tokens = <(double, LabelUnit, String, int)>[];
    for (final (seg, raw) in _splitSegmentsIndexed(ocrLines)) {
      for (final m in _amountUnitRe.allMatches(seg)) {
        final amount = _parseNumber(m.group(1)!);
        final unit = _ocrUnit(m.group(2)!);
        if (amount != null && unit != null) tokens.add((amount, unit, seg, raw));
      }
    }
    bool same(ParsedIngredientLine p, double amount, LabelUnit unit) =>
        p.unit == unit && p.amount != null && _sameAmount(p.amount!, amount);

    final merged = <ParsedIngredientLine>[];
    for (final a in ai.ingredients) {
      final amount = a.amount;
      final unit = a.unit;
      if (amount == null || unit == null) {
        merged.add(a.copyWith(needsCheck: true));
        continue;
      }
      final onImage = tokens.where((t) => t.$2 == unit && _sameAmount(t.$1, amount)).toList();
      final sameToken = parsed.ingredients.where((p) => same(p, amount, unit)).toList();
      // Cặp số đó đã thuộc dòng khác của bộ đọc chữ, kể cả dòng tên tự do.
      final assignedElsewhere = sameToken.isNotEmpty && !sameToken.any((p) => p.nutrientId == a.nutrientId);
      // Bộ đọc chữ đọc cùng chất với số khác.
      final sameNutrient = a.nutrientId == null
          ? const <ParsedIngredientLine>[]
          : parsed.ingredients.where((p) => p.nutrientId == a.nutrientId).toList();
      final onImageRaws = {for (final t in onImage) t.$4};
      final dualUnit = sameNutrient.any((p) {
        final pUnit = p.unit;
        final pAmount = p.amount;
        if (pUnit == null || pAmount == null || pUnit == unit) return false;
        return tokens.any((t) => onImageRaws.contains(t.$4) && t.$2 == pUnit && _sameAmount(t.$1, pAmount));
      });
      final conflict = sameNutrient.isNotEmpty && !sameNutrient.any((p) => same(p, amount, unit)) && !dualUnit;
      if (onImage.isEmpty || assignedElsewhere || conflict) {
        merged.add(a.copyWith(needsCheck: true));
        continue;
      }
      if (a.nutrientId == 'calcium' || a.nutrientId == 'iron') {
        final sameParser = sameToken.where((p) => p.nutrientId == a.nutrientId).firstOrNull;
        final (form, kind) = sameParser != null
            ? (sameParser.form, sameParser.compoundKind)
            : classifyMineral(a.nutrientId, onImage.first.$3);
        merged.add(a.copyWith(form: form, compoundKind: kind));
      } else {
        merged.add(a);
      }
    }

    final aiNutrients = {
      for (final a in ai.ingredients)
        if (a.nutrientId != null) a.nutrientId!,
    };
    for (final p in parsed.ingredients) {
      final nid = p.nutrientId;
      if (nid != null) {
        if (!aiNutrients.contains(nid)) merged.add(p);
        continue;
      }
      final amount = p.amount;
      // Dòng tên tự do chỉ coi là đã có khi một dòng AI tên tự do khớp ảnh mang đúng số đó;
      // dòng AI lấy nhầm số của nó (đã gắn cần kiểm) không thay được dòng này.
      final covered =
          amount != null &&
          merged.any(
            (a) =>
                a.nutrientId == null &&
                !a.needsCheck &&
                a.unit == p.unit &&
                a.amount != null &&
                _sameAmount(a.amount!, amount),
          );
      if (!covered) merged.add(p);
    }

    return ParsedLabelPackage(
      ingredients: merged,
      suggestedProductName: ai.suggestedProductName ?? parsed.suggestedProductName,
      suggestedBoxRemaining: ai.suggestedBoxRemaining ?? parsed.suggestedBoxRemaining,
      suggestedUnitsPerServing: ai.suggestedUnitsPerServing ?? parsed.suggestedUnitsPerServing,
      suggestedCountUnit: ai.suggestedCountUnit ?? parsed.suggestedCountUnit,
      rawLines: parsed.rawLines,
      fromOnDeviceAi: true,
    );
  }

  static String? _extractName(String line, int matchStart) {
    final prefix = line.substring(0, matchStart).replaceAll(RegExp(r'[:\-–()]+$'), '').trim();
    return prefix.isEmpty ? null : prefix;
  }
}
