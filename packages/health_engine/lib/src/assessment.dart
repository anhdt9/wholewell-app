/// Tổng hợp một ngày: vi chất so với RDA/AI, UL, calo, tỷ lệ đạm/béo/bột đường,
/// đường bổ sung.
library;

import 'dri.dart';
import 'energy.dart';
import 'models.dart';
import 'reference_pack.dart';

enum RangeStatus { below, within, above }

class MacroShare {
  final String macro; // protein | fat | carbohydrate
  final double grams;
  final double percentEnergy;
  final Range amdr;
  const MacroShare(this.macro, this.grams, this.percentEnergy, this.amdr);

  RangeStatus get status => percentEnergy < amdr.min
      ? RangeStatus.below
      : (percentEnergy > amdr.max ? RangeStatus.above : RangeStatus.within);
}

class NutrientStatus {
  final String nutrientId;
  final double amount;
  final Target target;
  const NutrientStatus(this.nutrientId, this.amount, this.target);
  double get percentOfTarget => target.value == 0 ? 0 : amount / target.value * 100;
}

class SugarCheck {
  final double addedSugarG;

  /// Chỉ để hiển thị; Dietary Guidelines 2025–2030 không đặt giới hạn theo % năng lượng/ngày.
  final double percentEnergy;

  /// Các bữa có đường bổ sung vượt giới hạn mỗi bữa: mealId → gram.
  final Map<String, double> mealsOverLimit;
  const SugarCheck(this.addedSugarG, this.percentEnergy, this.mealsOverLimit);
}

class DailyReport {
  final double energyInKcal;

  /// null khi EER chưa tính được; xem [eerNotComputed].
  final int? eerKcal;
  final NotComputedReason? eerNotComputed;
  final double energyOutWorkoutKcal;
  final List<MacroShare> macros;
  final SugarCheck sugar;
  final List<NutrientStatus> nutrients;
  final List<UlFlag> ulFlags;

  const DailyReport({
    required this.energyInKcal,
    required this.eerKcal,
    required this.eerNotComputed,
    required this.energyOutWorkoutKcal,
    required this.macros,
    required this.sugar,
    required this.nutrients,
    required this.ulFlags,
  });
}

double _sum(Iterable<IntakeItem> items, String key) =>
    items.fold(0.0, (s, it) => s + it.amount(key));

/// Tỷ lệ năng lượng từ đạm, béo, bột đường (tính trên năng lượng của ba chất này).
List<MacroShare> macroShares(ReferencePack pack, Profile p, List<IntakeItem> day) {
  final amdr = p.ageYears >= 19 ? pack.amdrAdult : pack.amdrTeen;
  final g = {
    'protein': _sum(day, 'protein'),
    'fat': _sum(day, 'fat'),
    'carbohydrate': _sum(day, 'carbohydrate'),
  };
  final kcal = {for (final e in g.entries) e.key: e.value * pack.energyPerGram[e.key]!};
  final total = kcal.values.fold(0.0, (a, b) => a + b);
  return [
    for (final m in ['protein', 'fat', 'carbohydrate'])
      MacroShare(m, g[m]!, total == 0 ? 0 : kcal[m]! / total * 100, amdr[m]!),
  ];
}

SugarCheck sugarCheck(ReferencePack pack, List<IntakeItem> day) {
  final sugar = _sum(day, 'addedSugar');
  var energy = _sum(day, 'energyKcal');
  if (energy <= 0) {
    energy = _sum(day, 'protein') * 4 + _sum(day, 'carbohydrate') * 4 + _sum(day, 'fat') * 9;
  }
  final pct = energy <= 0 ? 0.0 : sugar * 4 / energy * 100;
  final perMeal = <String, double>{};
  for (final it in day) {
    final id = it.mealId;
    if (id == null) continue;
    perMeal[id] = (perMeal[id] ?? 0) + it.amount('addedSugar');
  }
  perMeal.removeWhere((_, g) => g <= pack.addedSugarMaxGramsPerMeal);
  return SugarCheck(sugar, pct, perMeal);
}

/// Báo cáo một ngày. [last7Days] (gồm cả hôm nay) dùng cho cờ UL trung bình.
DailyReport dailyReport(
  ReferencePack pack,
  Profile p,
  List<IntakeItem> today, {
  List<WorkoutEntry> workouts = const [],
  List<List<IntakeItem>> last7Days = const [],
}) {
  int? eer;
  NotComputedReason? why;
  try {
    eer = eerKcal(pack, p);
  } on NotComputed catch (e) {
    why = e.reason;
  }
  final statuses = <NutrientStatus>[];
  for (final def in pack.nutrients.values) {
    final t = targetFor(pack, p, def.id);
    if (t == null) continue;
    statuses.add(NutrientStatus(def.id, _sum(today, def.id), t));
  }
  final flags = <String, UlFlag>{
    for (final f in checkUlDay(pack, p, today)) f.nutrientId: f,
  };
  if (last7Days.isNotEmpty) {
    for (final f in checkUlAverage(pack, p, last7Days)) {
      flags.putIfAbsent(f.nutrientId, () => f);
    }
  }
  return DailyReport(
    energyInKcal: _sum(today, 'energyKcal'),
    eerKcal: eer,
    eerNotComputed: why,
    energyOutWorkoutKcal:
        workouts.fold(0.0, (s, w) => s + workoutKcal(pack, p, w)),
    macros: macroShares(pack, p, today),
    sugar: sugarCheck(pack, today),
    nutrients: statuses,
    ulFlags: flags.values.toList(),
  );
}
