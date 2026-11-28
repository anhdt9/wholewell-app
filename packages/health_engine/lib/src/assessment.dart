/// Tổng hợp một ngày và trung bình 7 ngày: vi chất (2 tổng), UL, calo, tỷ lệ đạm/béo/bột đường, đường bổ sung.
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
  final double totalAmount;
  final double foodAmount;
  final double fortifiedAmount;
  final double supplementAmount;
  final Target? target;
  final double? ul;
  final double ulAmount;
  final UlScope ulScope;
  final String? ulNutrientId;

  const NutrientStatus({
    required this.nutrientId,
    required this.totalAmount,
    required this.foodAmount,
    required this.fortifiedAmount,
    required this.supplementAmount,
    required this.target,
    required this.ul,
    required this.ulAmount,
    required this.ulScope,
    required this.ulNutrientId,
  });

  double get amount => totalAmount;
  double? get percentOfTarget => target == null || target!.value == 0 ? null : totalAmount / target!.value * 100;
}

class MealSugarAlert {
  final MealSlot meal;
  final double grams;
  final DateTime? startAt;
  final DateTime? endAt;
  final List<String> labels;

  const MealSugarAlert({required this.meal, required this.grams, this.startAt, this.endAt, required this.labels});
}

class SugarCheck {
  final double addedSugarG;

  /// Chỉ để hiển thị; Dietary Guidelines 2025–2030 không đặt giới hạn theo % năng lượng/ngày.
  final double percentEnergy;
  final List<MealSugarAlert> mealsOverLimit;
  final List<String> unknownSugarFoods;

  const SugarCheck(this.addedSugarG, this.percentEnergy, this.mealsOverLimit, [this.unknownSugarFoods = const []]);
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
  final int loggedDaysCount;
  final ActivitySummary activity7Days;

  const DailyReport({
    required this.energyInKcal,
    required this.eerKcal,
    required this.eerNotComputed,
    required this.energyOutWorkoutKcal,
    required this.macros,
    required this.sugar,
    required this.nutrients,
    required this.ulFlags,
    required this.loggedDaysCount,
    required this.activity7Days,
  });
}

class PeriodReport {
  final int loggedDaysCount;
  final double averageEnergyInKcal;
  final int? eerKcal;
  final NotComputedReason? eerNotComputed;
  final List<MacroShare> macros;
  final double averageAddedSugarG;
  final double addedSugarPercentEnergy;
  final List<NutrientStatus> nutrients;
  final List<UlFlag> ulFlags;
  final ActivitySummary activity7Days;

  const PeriodReport({
    required this.loggedDaysCount,
    required this.averageEnergyInKcal,
    required this.eerKcal,
    required this.eerNotComputed,
    required this.macros,
    required this.averageAddedSugarG,
    required this.addedSugarPercentEnergy,
    required this.nutrients,
    required this.ulFlags,
    required this.activity7Days,
  });
}

double _sum(Iterable<IntakeItem> items, String key) => items.fold(0.0, (s, it) => s + it.amount(key));

(int?, NotComputedReason?) _computeEer(ReferencePack pack, Profile p) {
  try {
    return (eerKcal(pack, p), null);
  } on NotComputed catch (e) {
    return (null, e.reason);
  }
}

List<MacroShare> _computeMacros(ReferencePack pack, Profile p, List<List<IntakeItem>> days, {required bool average}) {
  final gDef = driGroupDefFor(pack, p);
  final amdr = pack.amdr[gDef.amdrKey]!;
  final flat = [for (final d in days) ...d];
  final g = {'protein': _sum(flat, 'protein'), 'fat': _sum(flat, 'fat'), 'carbohydrate': _sum(flat, 'carbohydrate')};
  final kcal = {for (final e in g.entries) e.key: e.value * pack.energyPerGram[e.key]!};
  final total = kcal.values.fold(0.0, (a, b) => a + b);
  final divisor = average && days.isNotEmpty ? days.length.toDouble() : 1.0;
  return [
    for (final m in ['protein', 'fat', 'carbohydrate'])
      MacroShare(
        m,
        average && days.isEmpty ? 0.0 : g[m]! / divisor,
        total == 0 ? 0.0 : kcal[m]! / total * 100,
        amdr[m]!,
      ),
  ];
}

/// Tỷ lệ năng lượng từ đạm, béo, bột đường (tính trên năng lượng của ba chất này).
List<MacroShare> macroShares(ReferencePack pack, Profile p, List<IntakeItem> day) =>
    _computeMacros(pack, p, [day], average: false);

List<NutrientStatus> _computeNutrientStatuses(
  ReferencePack pack,
  Profile p,
  List<List<IntakeItem>> days, {
  required bool average,
}) {
  final ulTargetKeys = {
    for (final n in pack.nutrients.values)
      if (n.ulKey != null) n.ulKey!,
  };
  final nDays = days.length;
  final out = <NutrientStatus>[];
  for (final def in pack.nutrients.values) {
    if (ulTargetKeys.contains(def.id)) continue;
    final t = targetFor(pack, p, def.id);
    final ulDef = def.ulKey != null ? pack.nutrients[def.ulKey!]! : def;
    final ul = ulFor(pack, p, ulDef.id);
    if (t == null && ul == null) continue;

    var food = 0.0, fort = 0.0, supp = 0.0, ulAmt = 0.0;
    for (final day in days) {
      for (final it in day) {
        final v = it.amount(def.id);
        switch (it.source) {
          case IntakeSource.food:
            food += v;
          case IntakeSource.fortified:
            fort += v;
          case IntakeSource.supplement:
            supp += v;
        }
      }
      ulAmt += amountForUl(ulDef, day);
    }
    if (average && nDays > 0) {
      food /= nDays;
      fort /= nDays;
      supp /= nDays;
      ulAmt /= nDays;
    } else if (average && nDays == 0) {
      food = fort = supp = ulAmt = 0.0;
    }
    out.add(
      NutrientStatus(
        nutrientId: def.id,
        totalAmount: food + fort + supp,
        foodAmount: food,
        fortifiedAmount: fort,
        supplementAmount: supp,
        target: t,
        ul: ul,
        ulAmount: ulAmt,
        ulScope: ulDef.ulScope,
        ulNutrientId: ul == null ? null : ulDef.id,
      ),
    );
  }
  return out;
}

class _SugarEntry {
  final String label;
  final MealSlot? meal;
  final DateTime? at;
  double sugar;
  bool known;
  _SugarEntry(this.label, this.meal, this.at, this.sugar, this.known);
}

List<_SugarEntry> _groupSugarEntries(List<IntakeItem> day) {
  final out = <_SugarEntry>[];
  final byEid = <String, _SugarEntry>{};
  for (final it in day) {
    final eid = it.entryId;
    if (eid != null && byEid.containsKey(eid)) {
      final g = byEid[eid]!;
      g.sugar += it.amount('addedSugar');
      if (!it.addedSugarKnown) g.known = false;
    } else {
      final g = _SugarEntry(it.label, it.meal, it.at, it.amount('addedSugar'), it.addedSugarKnown);
      out.add(g);
      if (eid != null) byEid[eid] = g;
    }
  }
  return out;
}

class _SnackCluster {
  final DateTime? startAt;
  DateTime? endAt;
  double grams;
  final List<String> labels;
  _SnackCluster(this.startAt, this.endAt, this.grams, this.labels);
}

SugarCheck sugarCheck(ReferencePack pack, List<IntakeItem> day) {
  final totalSugar = _sum(day, 'addedSugar');
  var energy = _sum(day, 'energyKcal');
  if (energy <= 0) {
    energy = _sum(day, 'protein') * 4 + _sum(day, 'carbohydrate') * 4 + _sum(day, 'fat') * 9;
  }
  final pct = energy <= 0 ? 0.0 : totalSugar * 4 / energy * 100;
  final limit = pack.addedSugarMaxGramsPerMeal;
  final entries = _groupSugarEntries(day);
  final alerts = <MealSugarAlert>[];

  for (final m in const [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]) {
    final ms = [
      for (final g in entries)
        if (g.meal == m) g,
    ];
    final sum = ms.fold(0.0, (s, g) => s + g.sugar);
    if (sum > limit) {
      alerts.add(MealSugarAlert(meal: m, grams: sum, labels: [for (final g in ms) g.label]));
    }
  }

  final snacks = [
    for (final g in entries)
      if (g.meal == MealSlot.snack) g,
  ];
  final timed = [
    for (final g in snacks)
      if (g.at != null) g,
  ]..sort((a, b) => a.at!.compareTo(b.at!));
  final untimed = [
    for (final g in snacks)
      if (g.at == null) g,
  ];

  final clusters = <_SnackCluster>[];
  for (final g in timed) {
    final t = g.at!;
    if (clusters.isEmpty || t.difference(clusters.last.endAt!).inSeconds >= 30 * 60) {
      clusters.add(_SnackCluster(t, t, g.sugar, [g.label]));
    } else {
      final c = clusters.last;
      c.endAt = t;
      c.grams += g.sugar;
      c.labels.add(g.label);
    }
  }
  for (final g in untimed) {
    clusters.add(_SnackCluster(null, null, g.sugar, [g.label]));
  }
  for (final c in clusters) {
    if (c.grams > limit) {
      alerts.add(
        MealSugarAlert(meal: MealSlot.snack, grams: c.grams, startAt: c.startAt, endAt: c.endAt, labels: c.labels),
      );
    }
  }

  final unknown = [
    for (final g in entries)
      if (!g.known) g.label,
  ];
  return SugarCheck(totalSugar, pct, alerts, unknown);
}

/// Báo cáo một ngày. [last7Days] (tự lọc bỏ ngày rỗng) dùng cho cờ UL trung bình.
DailyReport dailyReport(
  ReferencePack pack,
  Profile p,
  List<IntakeItem> today, {
  List<WorkoutEntry> workouts = const [],
  List<List<IntakeItem>> last7Days = const [],
  List<WorkoutEntry> workouts7 = const [],
}) {
  final (eer, why) = _computeEer(pack, p);
  final nonEmpty = [
    for (final d in last7Days)
      if (d.isNotEmpty) d,
  ];
  final flags = <UlFlag>[...checkUlDay(pack, p, today), ...checkUlAverage(pack, p, nonEmpty)];
  sortUlFlags(flags);

  return DailyReport(
    energyInKcal: _sum(today, 'energyKcal'),
    eerKcal: eer,
    eerNotComputed: why,
    energyOutWorkoutKcal: workouts.fold(0.0, (s, w) => s + workoutKcal(pack, p, w)),
    macros: _computeMacros(pack, p, [today], average: false),
    sugar: sugarCheck(pack, today),
    nutrients: _computeNutrientStatuses(pack, p, [today], average: false),
    ulFlags: flags,
    loggedDaysCount: nonEmpty.length,
    activity7Days: activitySummary(pack, workouts7),
  );
}

/// Báo cáo trung bình các ngày có ghi (dùng cho chế độ "7 ngày").
PeriodReport averageReport(
  ReferencePack pack,
  Profile p,
  List<List<IntakeItem>> loggedDays, {
  List<WorkoutEntry> workouts7 = const [],
}) {
  final nonEmpty = [
    for (final d in loggedDays)
      if (d.isNotEmpty) d,
  ];
  final n = nonEmpty.length;
  final (eer, why) = _computeEer(pack, p);
  final flat = [for (final d in nonEmpty) ...d];
  final totEnergy = _sum(flat, 'energyKcal');
  final totSugar = _sum(flat, 'addedSugar');
  final denomEnergy = totEnergy > 0
      ? totEnergy
      : _sum(flat, 'protein') * 4 + _sum(flat, 'carbohydrate') * 4 + _sum(flat, 'fat') * 9;

  return PeriodReport(
    loggedDaysCount: n,
    averageEnergyInKcal: n == 0 ? 0.0 : totEnergy / n,
    eerKcal: eer,
    eerNotComputed: why,
    macros: _computeMacros(pack, p, nonEmpty, average: true),
    averageAddedSugarG: n == 0 ? 0.0 : totSugar / n,
    addedSugarPercentEnergy: denomEnergy <= 0 ? 0.0 : totSugar * 4 / denomEnergy * 100,
    nutrients: _computeNutrientStatuses(pack, p, nonEmpty, average: true),
    ulFlags: checkUlAverage(pack, p, nonEmpty),
    activity7Days: activitySummary(pack, workouts7),
  );
}
