/// Kiểu dữ liệu đầu vào và kết quả của engine.
library;

enum Sex { male, female }

enum LifeStage { none, pregnant, lactating }

enum ActivityLevel { inactive, lowActive, active, veryActive }

enum BmiClass { underweight, normal, overweight, obese }

/// Nguồn của một lượng chất, dùng để xác định phạm vi UL.
enum IntakeSource { food, fortified, supplement }

class Profile {
  final int ageYears;
  final Sex sex;
  final double heightCm;
  final double weightKg;
  final LifeStage stage;

  /// Tuần thai (chỉ khi [stage] == pregnant).
  final int? gestationWeek;

  /// Phân loại BMI trước khi mang thai (chỉ khi mang thai, quý 2–3).
  final BmiClass? prePregnancyBmi;

  /// Số tháng sau sinh (chỉ khi [stage] == lactating).
  final int? monthsPostpartum;

  /// Mức vận động người dùng xác nhận (app có thể gợi ý từ nhật ký).
  final ActivityLevel activityLevel;

  const Profile({
    required this.ageYears,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    this.stage = LifeStage.none,
    this.gestationWeek,
    this.prePregnancyBmi,
    this.monthsPostpartum,
    this.activityLevel = ActivityLevel.inactive,
  });

  Profile copyWith({
    int? ageYears,
    Sex? sex,
    double? heightCm,
    double? weightKg,
    LifeStage? stage,
    int? gestationWeek,
    BmiClass? prePregnancyBmi,
    int? monthsPostpartum,
    ActivityLevel? activityLevel,
  }) =>
      Profile(
        ageYears: ageYears ?? this.ageYears,
        sex: sex ?? this.sex,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        stage: stage ?? this.stage,
        gestationWeek: gestationWeek ?? this.gestationWeek,
        prePregnancyBmi: prePregnancyBmi ?? this.prePregnancyBmi,
        monthsPostpartum: monthsPostpartum ?? this.monthsPostpartum,
        activityLevel: activityLevel ?? this.activityLevel,
      );
}

/// Một món ăn, đồ uống hoặc liều bổ sung đã ghi.
///
/// [nutrients] dùng id chất trong gói dữ liệu (vd. `vitC`, `iron`), cùng đơn vị
/// chuẩn của gói. Các khóa năng lượng: `energyKcal`, `protein`, `fat`,
/// `carbohydrate`, `addedSugar` (g).
class IntakeItem {
  final String label;
  final IntakeSource source;
  final String? mealId;
  final Map<String, double> nutrients;

  const IntakeItem({
    required this.label,
    required this.source,
    required this.nutrients,
    this.mealId,
  });

  double amount(String key) => nutrients[key] ?? 0;
}

/// Một buổi tập người dùng tự nhập.
class WorkoutEntry {
  final String activityCode;
  final double minutes;

  const WorkoutEntry({required this.activityCode, required this.minutes});
}

/// Lý do engine không tính được một giá trị (để UI giải thích, không đoán).
enum NotComputedReason {
  ageUnsupported,
  eerUnderAge19,
  missingGestationWeek,
  missingPrePregnancyBmi,
  unknownActivity,
}

class NotComputed implements Exception {
  final NotComputedReason reason;
  const NotComputed(this.reason);
  @override
  String toString() => 'NotComputed($reason)';
}
