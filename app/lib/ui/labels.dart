import 'package:flutter/services.dart';
import 'package:health_engine/health_engine.dart';
import 'package:journal_db/journal_db.dart';

/// Nhãn tiếng Việt. Dùng lời thường, không hiện tên viết tắt của chuẩn.
String levelLabel(ActivityLevel l) => switch (l) {
      ActivityLevel.inactive => 'Ít vận động',
      ActivityLevel.lowActive => 'Vận động nhẹ',
      ActivityLevel.active => 'Vận động vừa',
      ActivityLevel.veryActive => 'Vận động nhiều',
    };

String bmiLabel(BmiClass b) => switch (b) {
      BmiClass.underweight => 'Thiếu cân',
      BmiClass.normal => 'Bình thường',
      BmiClass.overweight => 'Thừa cân',
      BmiClass.obese => 'Béo phì',
    };

String stageLabel(LifeStage s) => switch (s) {
      LifeStage.none => 'Không',
      LifeStage.pregnant => 'Đang mang thai',
      LifeStage.lactating => 'Đang cho con bú',
    };

String mealLabel(MealSlot m) => switch (m) {
      MealSlot.breakfast => 'sáng',
      MealSlot.lunch => 'trưa',
      MealSlot.dinner => 'tối',
      MealSlot.snack => 'phụ',
    };

String macroLabel(String m) => switch (m) {
      'protein' => 'Đạm',
      'fat' => 'Béo',
      'carbohydrate' => 'Bột đường',
      _ => m,
    };

const cautionBannerMessage =
    'Các mức trong app dành cho người khỏe mạnh. Với tình trạng của bạn, mức phù hợp có thể khác; hãy hỏi bác sĩ.';

/// Bộ nhãn đổi đồng bộ giữa chế độ thường và chế độ thận trọng (`docs/design/eligibility-caution-water.md`).
class CautionLabels {
  final bool caution;
  const CautionLabels({required this.caution});

  String get calorieGoalLabel => caution ? 'Mức calo tham chiếu' : 'Mục tiêu calo';

  String get calorieGoalExplainer => caution
      ? 'Mức calo tham chiếu là mức giữ cân, đã tính mức vận động trong hồ sơ.'
      : 'Mục tiêu là mức giữ cân, đã tính mức vận động trong hồ sơ.';

  String get macroShareSubtitle =>
      caution ? 'So với khoảng tham chiếu (% năng lượng)' : 'So với khoảng khuyến nghị (% năng lượng)';

  String get nutrientsSubtitle => caution
      ? '% so với mức tham chiếu hằng ngày. "ước tính" là chất chưa có mức tham chiếu chính thức.'
      : '% so với mức khuyến nghị hằng ngày. "ước tính" là chất chưa có mức khuyến nghị chính thức.';

  String get underTargetFilter => caution ? 'Dưới mức tham chiếu' : 'Dưới mức khuyến nghị';

  String get under19NoCalorieGoal =>
      caution ? 'Chưa có mức calo tham chiếu cho người 18 tuổi.' : 'Chưa có mục tiêu calo cho người 18 tuổi.';

  String recommendedGrams(String grams) =>
      caution ? 'mức tham chiếu $grams' : 'mức khuyến nghị $grams';

  String percentTarget(int pct, [String? amount]) {
    final base = caution ? '$pct% mức tham chiếu' : '$pct% mức khuyến nghị';
    return amount == null ? base : '$base $amount';
  }
}

String reasonLabel(NotComputedReason r, {bool caution = false}) => switch (r) {
      NotComputedReason.eerUnderAge19 => CautionLabels(caution: caution).under19NoCalorieGoal,
      NotComputedReason.missingGestationWeek =>
        caution ? 'Nhập tuần thai để tính mức calo tham chiếu.' : 'Nhập tuần thai để tính mục tiêu calo.',
      NotComputedReason.missingPrePregnancyBmi => caution
          ? 'Chọn cân nặng trước khi mang thai (thiếu cân, bình thường…) để tính mức calo tham chiếu.'
          : 'Chọn cân nặng trước khi mang thai (thiếu cân, bình thường…) để tính mục tiêu calo.',
      NotComputedReason.ageUnsupported => 'App dành cho người từ 18 tuổi.',
      NotComputedReason.unknownActivity => 'Hoạt động không có trong danh sách.',
      NotComputedReason.missingFoodBetaCaroteneFactor => 'Chưa có hệ số beta-caroten trong thức ăn.',
      NotComputedReason.missingEsterRatio => 'Chưa có tỷ lệ tocopherol của este vitamin E.',
      NotComputedReason.missingCompoundRatio => 'Chưa có tỷ lệ nguyên tố của hợp chất.',
      NotComputedReason.missingNutrientInPack => 'Chất này chưa có trong gói dữ liệu tham chiếu.',
    };

String unitLabel(String u) => switch (u) {
      'ug' => 'µg',
      'iu' => 'IU',
      'ug_RAE' || 'ugRae' => 'µg RAE',
      'ug_DFE' || 'ugDfe' => 'µg DFE',
      'mg_NE' || 'mgNe' => 'mg NE',
      _ => u,
    };

String fmt(double v) {
  if (v >= 100) return v.round().toString();
  if (v >= 10) return v.toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',');
  return v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
}

/// Định dạng lượng nước `ml` theo chuẩn số Việt Nam (dấu chấm hàng nghìn, vd. `1.250`).
String fmtWaterMl(double ml) {
  if ((ml - ml.roundToDouble()).abs() < 0.05) {
    final s = ml.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final posFromRight = s.length - i;
      if (i > 0 && posFromRight % 3 == 0 && s[i - 1] != '-') buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
  return ml.toStringAsFixed(1).replaceAll('.', ',');
}

String countUnitLabel(CountUnit u) => switch (u) {
      CountUnit.tablet => 'viên',
      CountUnit.capsule => 'viên nang',
      CountUnit.softgel => 'viên nang mềm',
      CountUnit.sachet => 'gói',
      CountUnit.drop => 'giọt',
      CountUnit.ml => 'ml',
      CountUnit.g => 'g',
    };

String fmtExpiryMonth(String yyyyMm) {
  final parts = yyyyMm.split('-');
  if (parts.length != 2) return yyyyMm;
  return '${parts[1]}/${parts[0]}';
}

/// Kiểm hợp lệ `MM/YYYY` (tháng `01..12`, năm 4 chữ số) và chuyển sang `YYYY-MM`.
/// Ô hạn dùng `MM/YYYY`: chỉ nhận số, gõ đủ 2 số tháng thì tự thêm `/`.
/// Số đầu từ 2 đến 9 chỉ có thể là tháng một chữ số nên thêm `0` phía trước (`8` thành `08/`).
/// Xóa lùi qua dấu `/` thì không thêm lại.
class ExpiryMonthInputFormatter extends TextInputFormatter {
  const ExpiryMonthInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isNotEmpty && digits.codeUnitAt(0) > 0x31) digits = '0$digits';
    if (digits.length > 6) digits = digits.substring(0, 6);
    final deleting = newValue.text.length < oldValue.text.length;
    final String text;
    if (digits.length < 2) {
      text = digits;
    } else if (digits.length == 2) {
      text = deleting && !newValue.text.endsWith('/') ? digits : '$digits/';
    } else {
      text = '${digits.substring(0, 2)}/${digits.substring(2)}';
    }
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

({bool ok, String? yyyyMm}) parseExpiryMmYyyy(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return (ok: true, yyyyMm: null);
  final m = RegExp(r'^(\d{2})/(\d{4})$').firstMatch(t);
  if (m == null) return (ok: false, yyyyMm: null);
  final month = int.parse(m.group(1)!);
  if (month < 1 || month > 12) return (ok: false, yyyyMm: null);
  return (ok: true, yyyyMm: '${m.group(2)}-${m.group(1)}');
}
