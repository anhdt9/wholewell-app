/// Năng lượng: EER (NASEM 2023), calo vận động theo MET, phút vận động.
library;

import 'models.dart';
import 'reference_pack.dart';

String _levelKey(ActivityLevel l) => switch (l) {
      ActivityLevel.inactive => 'inactive',
      ActivityLevel.lowActive => 'lowActive',
      ActivityLevel.active => 'active',
      ActivityLevel.veryActive => 'veryActive',
    };

String _bmiKey(BmiClass b) => switch (b) {
      BmiClass.underweight => 'underweight',
      BmiClass.normal => 'normal',
      BmiClass.overweight => 'overweight',
      BmiClass.obese => 'obese',
    };

double _tee(EerCoef c, Profile p, {int gestWeek = 0}) =>
    c.a + c.age * p.ageYears + c.height * p.heightCm + c.weight * p.weightKg + c.gestWeek * gestWeek;

/// Mục tiêu calo mỗi ngày (kcal, làm tròn số nguyên). Mức giữ cân.
///
/// Ném [NotComputed] khi chưa đủ dữ liệu hoặc ngoài phạm vi đã kiểm chứng
/// (dưới 19 tuổi; mang thai quý 2–3 thiếu tuần thai hoặc BMI trước mang thai).
int eerKcal(ReferencePack pack, Profile p) {
  if (p.ageYears < pack.eerMinAge) {
    throw const NotComputed(NotComputedReason.eerUnderAge19);
  }
  final level = _levelKey(p.activityLevel);
  final sexKey = p.sex == Sex.male ? 'male' : 'female';
  final double kcal;
  if (p.stage == LifeStage.pregnant) {
    final week = p.gestationWeek;
    if (week == null) throw const NotComputed(NotComputedReason.missingGestationWeek);
    if (week <= pack.firstTrimesterMaxWeek) {
      // Quý 1: dùng phương trình nữ không mang thai, bỏ qua năng lượng tích lũy.
      kcal = _tee(pack.eerAdult['female']![level]!, p);
    } else {
      final bmi = p.prePregnancyBmi;
      if (bmi == null) throw const NotComputed(NotComputedReason.missingPrePregnancyBmi);
      kcal = _tee(pack.eerPregnancy[level]!, p, gestWeek: week) +
          pack.pregnancyDeposition[_bmiKey(bmi)]!;
    }
  } else if (p.stage == LifeStage.lactating) {
    final base = _tee(pack.eerAdult['female']![level]!, p);
    final m = p.monthsPostpartum ?? 0;
    if (m <= 6) {
      kcal = base + pack.lactation0to6.milk - pack.lactation0to6.mobilization;
    } else if (m <= 12) {
      kcal = base + pack.lactation7to12.milk - pack.lactation7to12.mobilization;
    } else {
      kcal = base;
    }
  } else {
    kcal = _tee(pack.eerAdult[sexKey]![level]!, p);
  }
  return kcal.round();
}

/// kcal ≈ MET × cân nặng (kg) × số giờ.
double workoutKcal(ReferencePack pack, Profile p, WorkoutEntry w) {
  final a = pack.activities[w.activityCode];
  if (a == null) throw const NotComputed(NotComputedReason.unknownActivity);
  return a.met * p.weightKg * (w.minutes / 60);
}

class ActivityMinutes {
  final double moderate;
  final double vigorous;
  const ActivityMinutes(this.moderate, this.vigorous);

  /// Phút tương đương vừa: phút mạnh tính gấp đôi (như Physical Activity Guidelines).
  double get moderateEquivalent => moderate + 2 * vigorous;
}

/// Phút vận động vừa (3–5,9 MET) và mạnh (từ 6 MET).
ActivityMinutes activityMinutes(ReferencePack pack, Iterable<WorkoutEntry> ws) {
  var mod = 0.0, vig = 0.0;
  for (final w in ws) {
    final a = pack.activities[w.activityCode];
    if (a == null) continue;
    if (a.met >= pack.vigorousMinMet) {
      vig += w.minutes;
    } else if (a.met >= pack.moderateMinMet) {
      mod += w.minutes;
    }
  }
  return ActivityMinutes(mod, vig);
}

/// Gợi ý mức vận động cho EER từ buổi tập trong [days] ngày gần nhất.
///
/// Đây là quy tắc của app (không phải chuẩn NASEM); người dùng tự xác nhận.
ActivityLevel suggestActivityLevel(ReferencePack pack, Iterable<WorkoutEntry> lastDays,
    {int days = 7}) {
  final perDay = activityMinutes(pack, lastDays).moderateEquivalent / days;
  final t = pack.palSuggestionThresholds;
  if (perDay >= t['veryActive']!) return ActivityLevel.veryActive;
  if (perDay >= t['active']!) return ActivityLevel.active;
  if (perDay >= t['lowActive']!) return ActivityLevel.lowActive;
  return ActivityLevel.inactive;
}
