/// Kiểu dữ liệu đầu vào và kết quả của engine.
library;

enum Sex { male, female }

enum LifeStage { none, pregnant, lactating }

enum ActivityLevel { inactive, lowActive, active, veryActive }

enum BmiClass { underweight, normal, overweight, obese }

/// Nguồn của một lượng chất, dùng để xác định phạm vi UL.
enum IntakeSource { food, fortified, supplement }

/// Bữa ăn trong ngày.
enum MealSlot { breakfast, lunch, dinner, snack }

/// Phân biệt số trên nhãn là nguyên tố hay khối lượng hợp chất.
enum CompoundKind { elemental, compound, unknown }

/// Đơn vị đọc từ nhãn thực phẩm hoặc thực phẩm bổ sung.
enum LabelUnit { g, mg, ug, iu, ugRae, ugDfe, mgNe }

/// Mã dạng (`form`) dùng chung giữa gói dữ liệu, engine và CSDL.
abstract final class NutrientForm {
  static const unknown = 'unknown';

  // Vitamin A
  static const retinol = 'retinol';
  static const betaCarotene = 'beta_carotene';

  // Folate
  static const folicAcid = 'folic_acid';
  static const naturalFolate = 'natural_folate';

  // Vitamin E
  static const natural2r = 'natural_2r';
  static const synthetic2r = 'synthetic_2r';
  static const syntheticMass = 'synthetic_mass';
  static const dAlphaTocopherylAcetate = 'd_alpha_tocopheryl_acetate';
  static const dlAlphaTocopherylAcetate = 'dl_alpha_tocopheryl_acetate';
  static const dAlphaTocopherylSuccinate = 'd_alpha_tocopheryl_succinate';
  static const dlAlphaTocopherylSuccinate = 'dl_alpha_tocopheryl_succinate';

  // Khoáng chất
  static const elemental = 'elemental';

  static const vitaminEEsters = {
    dAlphaTocopherylAcetate,
    dlAlphaTocopherylAcetate,
    dAlphaTocopherylSuccinate,
    dlAlphaTocopherylSuccinate,
  };

  static bool isVitaminEEster(String form) => vitaminEEsters.contains(form);

  /// `true` cho este nguồn tự nhiên (`d-`), `false` cho tổng hợp (`dl-`), `null` nếu không thuộc tập cố định.
  static bool? vitaminEEsterIsNatural(String form) => switch (form) {
    dAlphaTocopherylAcetate || dAlphaTocopherylSuccinate => true,
    dlAlphaTocopherylAcetate || dlAlphaTocopherylSuccinate => false,
    _ => null,
  };
}

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
  }) => Profile(
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
  final MealSlot? meal;
  final DateTime? at;
  final bool addedSugarKnown;
  final String? entryId;
  final Map<String, double> nutrients;

  /// Lượng tính vào giới hạn an toàn cho các khóa khác [nutrients].
  final Map<String, double>? ulNutrients;

  const IntakeItem({
    required this.label,
    required this.source,
    required this.nutrients,
    this.ulNutrients,
    this.meal,
    this.at,
    this.addedSugarKnown = true,
    this.entryId,
  });

  double amount(String key) => nutrients[key] ?? 0;

  double amountForUlKey(String key) => ulNutrients?[key] ?? nutrients[key] ?? 0;
}

/// Một buổi tập người dùng tự nhập.
class WorkoutEntry {
  final String activityCode;
  final double minutes;

  /// Ngày YYYY-MM-DD (dùng để đếm số ngày phân biệt tập tăng cơ).
  final String? day;

  const WorkoutEntry({required this.activityCode, required this.minutes, this.day});
}

/// Lý do engine không tính được một giá trị (để UI giải thích, không đoán).
enum NotComputedReason {
  ageUnsupported,
  eerUnderAge19,
  missingGestationWeek,
  missingPrePregnancyBmi,
  unknownActivity,
  missingFoodBetaCaroteneFactor,
  missingEsterRatio,
  missingCompoundRatio,
  missingNutrientInPack,
}

class NotComputed implements Exception {
  final NotComputedReason reason;
  const NotComputed(this.reason);
  @override
  String toString() => 'NotComputed($reason)';
}
