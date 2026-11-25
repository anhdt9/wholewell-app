import 'package:health_engine/health_engine.dart';

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

String reasonLabel(NotComputedReason r) => switch (r) {
      NotComputedReason.eerUnderAge19 =>
        'Chưa có mục tiêu calo cho người dưới 19 tuổi (phương trình chưa kiểm chứng xong).',
      NotComputedReason.missingGestationWeek => 'Nhập tuần thai để tính mục tiêu calo.',
      NotComputedReason.missingPrePregnancyBmi =>
        'Chọn cân nặng trước khi mang thai (thiếu cân, bình thường…) để tính mục tiêu calo.',
      NotComputedReason.ageUnsupported => 'App dành cho người từ 18 tuổi.',
      NotComputedReason.unknownActivity => 'Hoạt động không có trong danh sách.',
      NotComputedReason.missingFoodBetaCaroteneFactor => 'Chưa có hệ số beta-caroten trong thức ăn.',
      NotComputedReason.missingEsterRatio => 'Chưa có tỷ lệ tocopherol của este vitamin E.',
      NotComputedReason.missingCompoundRatio => 'Chưa có tỷ lệ nguyên tố của hợp chất.',
      NotComputedReason.missingNutrientInPack => 'Chất này chưa có trong gói dữ liệu tham chiếu.',
    };

String unitLabel(String u) => switch (u) {
      'ug' => 'µg',
      'ug_RAE' => 'µg RAE',
      'ug_DFE' => 'µg DFE',
      'mg_NE' => 'mg NE',
      _ => u,
    };

String fmt(double v) {
  if (v >= 100) return v.round().toString();
  if (v >= 10) return v.toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',');
  return v.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
}
